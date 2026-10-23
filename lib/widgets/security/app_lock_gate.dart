import 'dart:async';

import 'package:aves/widgets/security/failsafe_lockdown.dart';

import 'package:aves/model/security/app_lock.dart';
import 'package:aves/widgets/common/action_mixins/secret_lock.dart';
import 'package:aves_model/aves_model.dart';
import 'package:aves_utils/aves_utils.dart';
import 'package:aves/model/security/attempt_guard.dart';
import 'package:aves/model/security/nuke.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/filter_editors/code_dialog.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:aves/widgets/common/fx/app_mark.dart';
import 'package:aves/widgets/security/security_screen_background.dart';

// Covers the app with an opaque lock screen while the app is locked.
// The content below is kept (so the state is preserved when locking again) but cannot be seen or used.
class AppLockGate extends StatelessWidget {
  final Widget? child;

  const AppLockGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appLock,
      builder: (context, _) {
        final covered = !appLock.ready || appLock.locked;
        final nebula = Theme.of(context).nebula;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (appLock.ready && child != null) ExcludeSemantics(excluding: covered, child: child!),
            if (covered)
              Positioned.fill(
                child: appLock.ready ? const _LockScreen() : ColoredBox(color: nebula.securityScrim),
              ),
          ],
        );
      },
    );
  }
}

// the screen sits above the Navigator, so it needs its own Overlay (text selection handles require one)
class _LockScreen extends StatefulWidget {
  const _LockScreen();

  @override
  State<_LockScreen> createState() => _LockScreenHostState();
}

class _LockScreenHostState extends State<_LockScreen> {
  late final OverlayEntry _entry = OverlayEntry(builder: (context) => const _LockBody());

  @override
  void dispose() {
    _entry.remove();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}

class _LockBody extends StatefulWidget {
  const _LockBody();

  @override
  State<_LockBody> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockBody> {
  final _controller = PinInputController();
  String? _message;
  bool _fake = false;
  int _fails = 0;
  bool _showBiometric = false;
  bool _checking = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final canBio = appLock.lockTypeName != 'system' && await appLock.canUseBiometric();
    final remaining = await AttemptGuard.app.remainingCooldown();
    if (!mounted) return;
    setState(() => _showBiometric = canBio && remaining == null);
    if (remaining != null) {
      _showCooldown(remaining);
    }
  }

  // blocks any entry while the cooldown lasts
  void _showCooldown(Duration remaining) {
    _timer?.cancel();
    var seconds = remaining.inSeconds + 1;
    void update() {
      if (!mounted) return;
      final m = (seconds ~/ 60).toString();
      final s = (seconds % 60).toString().padLeft(2, '0');
      setState(() => _message = context.l10n.appLockCooldownMessage('$m:$s'));
    }

    FocusManager.instance.primaryFocus?.unfocus();
    update();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds--;
      if (seconds <= 0) {
        timer.cancel();
        if (mounted) setState(() => _message = null);
        _refresh();
      } else {
        update();
      }
    });
  }

  bool get _blocked => _timer?.isActive ?? false;

  Future<void> _onCode(String code) async {
    // Some PIN field versions emit onCompleted twice. In particular, never let a panic PIN
    // trigger destructive handling twice for one physical entry.
    if (_blocked || _checking) {
      _controller.clear();
      return;
    }
    _checking = true;
    try {
      final result = await appLock.attemptPin(code);
      _controller.clear();
      await _handle(result);
    } catch (e, stack) {
      await reportService.recordError(e, stack);
      _controller.clear();
      // Verification/runtime errors must not be interpreted as a wrong PIN or trigger a nuke.
      if (mounted) setState(() => _message = context.l10n.genericFailureFeedback);
    } finally {
      _checking = false;
    }
  }

  Future<void> _onBiometric() async {
    if (_blocked || _checking) return;
    _checking = true;
    try {
      final bool ok;
      try {
        ok = await LocalAuthentication().authenticate(localizedReason: context.l10n.appLockBiometricReason);
      } on PlatformException catch (e, stack) {
        await reportService.recordError(e, stack);
        return;
      }
      if (!ok) {
        // local_auth reports rejection and cancellation with the same boolean; record only in
        // the biometric-only counter so cancelling the prompt can never trigger a nuke.
        await appLock.biometricFailed();
        await _refresh();
        return;
      }
      await _handle(await appLock.biometricSucceeded());
    } catch (error, stack) {
      await reportService.recordError(error, stack);
      if (mounted) setState(() => _message = context.l10n.genericFailureFeedback);
    } finally {
      _checking = false;
    }
  }

  Future<void> _onAlternativeLock() async {
    if (_blocked || _checking) return;
    final type = VaultLockType.values.safeByName(appLock.lockTypeName);
    if (type == null) {
      if (mounted) setState(() => _message = context.l10n.genericFailureFeedback);
      return;
    }
    _checking = true;
    try {
      final ok = await SecretLock.challenge(
        context,
        type,
        context.l10n.appLockTitle,
        AppLock.alternativeSecretKeyFor(appLock.lockTypeName),
        guard: AttemptGuard.app,
        onNuke: Nuke.nukeEverything,
      );
      if (ok) {
        await appLock.alternativeSucceeded();
      } else {
        await _refresh();
      }
    } catch (error, stack) {
      await reportService.recordError(error, stack);
      if (mounted) setState(() => _message = context.l10n.genericFailureFeedback);
    } finally {
      _checking = false;
    }
  }

  Future<void> _loadFails() async {
    final fails = await AttemptGuard.app.failures();
    if (mounted) setState(() => _fails = fails);
  }

  Future<void> _handle(AppLockResult result) async {
    unawaited(_loadFails());
    switch (result) {
      case AppLockResult.unlocked:
        break;
      case AppLockResult.panic:
        // looks like a wrong PIN, while everything is wiped in the background
        setState(() => _fake = true);
        unawaited(Nuke.nukeEverything());
      case AppLockResult.nuke:
        setState(() => _fake = true);
        await Nuke.nukeEverything();
      case AppLockResult.cooldown:
        await HapticFeedback.vibrate();
        final remaining = await AttemptGuard.app.remainingCooldown();
        if (remaining != null) _showCooldown(remaining);
      case AppLockResult.wrong:
        if (mounted) setState(() => _message = context.l10n.appLockWrongPin);
        await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nebula = Theme.of(context).nebula;
    final textTheme = Theme.of(context).textTheme;
    return SecurityScreenBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      nebula.securitySurface.withValues(alpha: .96),
                      nebula.securityInputFieldBg.withValues(alpha: .94),
                      nebula.securitySurface.withValues(alpha: .99),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: nebula.securityCrystalEdge.withValues(alpha: .72), width: 1.2),
                  boxShadow: [
                    BoxShadow(color: nebula.securityBubbleGlow.withValues(alpha: .24), blurRadius: 36, spreadRadius: -8),
                    BoxShadow(color: Colors.black.withValues(alpha: .32), blurRadius: 24, offset: const Offset(0, 12)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-.35, -.45),
                          colors: [
                            nebula.securityBubbleGlow.withValues(alpha: .48),
                            nebula.securitySurface.withValues(alpha: .92),
                            nebula.securityScrim.withValues(alpha: .7),
                          ],
                          stops: const [0, .6, 1],
                        ),
                        border: Border.all(color: nebula.securityCrystalEdge.withValues(alpha: .78), width: 1.2),
                        boxShadow: [BoxShadow(color: nebula.securityBubbleGlow.withValues(alpha: .24), blurRadius: 24, spreadRadius: -4)],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const AppMark(size: 46),
                          Positioned(
                            right: 12, bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: nebula.securitySurface, shape: BoxShape.circle,
                                border: Border.all(color: nebula.securityAccent, width: 1.2),
                              ),
                              child: Icon(Icons.lock_rounded, size: 15, color: nebula.securityAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(_fake ? l10n.appLockWrongPin : l10n.appLockTitle,
                      style: textTheme.headlineSmall?.copyWith(
                        color: nebula.securityOnSurface, fontWeight: FontWeight.w800, letterSpacing: .2),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    if (!_fake)
                      Text(l10n.settingsAppLockSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: nebula.securityOnSurface.withValues(alpha: .68), height: 1.4),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 26),
                    if (!_fake && !_blocked && appLock.lockTypeName == 'code')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: nebula.securityInputFieldBg.withValues(alpha: .68),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: nebula.securityInputFieldBorder.withValues(alpha: .72)),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: CodeDialog.fieldWidth,
                            child: MaterialPinField(
                              length: CodeDialog.length, pinController: _controller,
                              keyboardType: TextInputType.number, autoFocus: true, obscureText: true,
                              onChanged: (v) {}, onCompleted: _onCode,
                            ),
                          ),
                        ),
                      ),
                    if (!_fake && !_blocked && appLock.lockTypeName != 'code')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: FilledButton.icon(
                          onPressed: _onAlternativeLock,
                          icon: const Icon(Icons.lock_open),
                          label: Text(l10n.itemLockUnlockButton),
                        ),
                      ),
                    if (_fails > 0 && !_fake)
                      Padding(padding: const EdgeInsets.only(top: 20), child: FailsafeBuddy(fails: _fails)),
                    if (_message != null && !_fake)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: nebula.securityAlert.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: nebula.securityAlert.withValues(alpha: .4)),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 18, color: nebula.securityAlert),
                                const SizedBox(width: 9),
                                Flexible(
                                  child: Text(
                                    _message!,
                                    textAlign: TextAlign.start,
                                    softWrap: true,
                                    style: TextStyle(
                                      color: nebula.securityAlert,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                      letterSpacing: 0,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_showBiometric && !_fake)
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: nebula.securityAccent,
                            side: BorderSide(color: nebula.securityCrystalEdge.withValues(alpha: .82)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          onPressed: _onBiometric,
                          icon: const Icon(Icons.fingerprint),
                          label: Text(l10n.appLockUseBiometric),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
