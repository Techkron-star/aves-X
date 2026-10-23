import 'dart:async';

import 'package:aves/widgets/security/failsafe_lockdown.dart';

import 'package:aves/model/security/app_lock.dart';
import 'package:aves/model/security/attempt_guard.dart';
import 'package:aves/model/security/nuke.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/filter_editors/code_dialog.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

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
    final canBio = await appLock.canUseBiometric();
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
      _controller.clear();
      // Verification/runtime errors must not be interpreted as a wrong PIN or trigger a nuke.
      if (mounted) setState(() => _message = context.l10n.genericFailureFeedback);
    } finally {
      _checking = false;
    }
  }

  Future<void> _onBiometric() async {
    if (_blocked) return;
    bool? ok;
    try {
      ok = await LocalAuthentication().authenticate(localizedReason: context.l10n.appLockBiometricReason);
    } on PlatformException {
      return;
    }
    await _handle(ok ? await appLock.biometricSucceeded() : await appLock.biometricFailed());
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
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: scheme.primary),
                const SizedBox(height: 16),
                Text(_fake ? l10n.appLockWrongPin : l10n.appLockTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                if (!_fake && !_blocked)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                    width: CodeDialog.fieldWidth,
                    child: MaterialPinField(
                      length: CodeDialog.length,
                      pinController: _controller,
                      keyboardType: TextInputType.number,
                      autoFocus: true,
                      obscureText: true,
                      onChanged: (v) {},
                      onCompleted: _onCode,
                    ),
                    ),
                  ),
                if (_fails > 0 && !_fake)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: FailsafeBuddy(fails: _fails),
                  ),
                if (_message != null && !_fake)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(_message!, textAlign: TextAlign.center, style: TextStyle(color: scheme.error)),
                  ),
                if (_showBiometric && !_fake)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton.icon(
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
    );
  }
}
