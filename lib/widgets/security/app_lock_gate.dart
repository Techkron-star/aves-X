import 'dart:async';

import 'package:aves/model/security/app_lock.dart';
import 'package:aves/model/security/attempt_guard.dart';
import 'package:aves/model/security/nuke.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/filter_editors/code_dialog.dart';
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
        return Stack(
          fit: StackFit.expand,
          children: [
            if (appLock.ready && child != null) ExcludeSemantics(excluding: covered, child: child!),
            if (covered)
              Positioned.fill(
                child: appLock.ready ? const _LockScreen() : const ColoredBox(color: Color(0xFF000000)),
              ),
          ],
        );
      },
    );
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen();

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  final _controller = PinInputController();
  String? _message;
  bool _fake = false;
  bool _showBiometric = false;
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
    if (_blocked) {
      _controller.clear();
      return;
    }
    final result = await appLock.attemptPin(code);
    _controller.clear();
    await _handle(result);
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

  Future<void> _handle(AppLockResult result) async {
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
                if (!_fake)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
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
