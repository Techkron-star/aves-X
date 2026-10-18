import 'dart:async';

import 'package:aves/model/security/attempt_guard.dart';
import 'package:aves/model/security/bat_curity.dart';
import 'package:aves/model/security/failsafe.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/failsafe_badge.dart';
import 'package:aves/widgets/dialogs/filter_editors/code_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

// Covers the whole app while the Failsafe lockdown is on. Only the Master Code lifts it.
// The content below is kept but cannot be seen or used.
class FailsafeLockdownGate extends StatelessWidget {
  final Widget? child;

  const FailsafeLockdownGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: failsafe.lockdown,
      builder: (context, locked, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (child != null) ExcludeSemantics(excluding: locked, child: child!),
            if (locked) const Positioned.fill(child: _LockdownScreen()),
          ],
        );
      },
    );
  }
}

class _LockdownScreen extends StatefulWidget {
  const _LockdownScreen();

  @override
  State<_LockdownScreen> createState() => _LockdownScreenState();
}

class _LockdownScreenState extends State<_LockdownScreen> {
  final _controller = PinInputController();
  String? _message;
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

  bool get _blocked => _timer?.isActive ?? false;

  Future<void> _refresh() async {
    final remaining = await AttemptGuard.master.remainingCooldown();
    if (!mounted) return;
    if (remaining != null) _showCooldown(remaining);
  }

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
      } else {
        update();
      }
    });
  }

  Future<void> _onCode(String code) async {
    if (_blocked) {
      _controller.clear();
      return;
    }
    final ok = await batCurity.matches('master_code', code);
    _controller.clear();
    if (ok) {
      await AttemptGuard.master.reset();
      await AttemptGuard.app.reset();
      await failsafe.releaseLockdown();
      return;
    }
    // every failure makes the cooldown longer
    await AttemptGuard.master.registerFailure();
    final remaining = await AttemptGuard.master.remainingCooldown();
    if (!mounted) return;
    if (remaining != null) {
      _showCooldown(remaining);
    } else {
      setState(() => _message = context.l10n.appLockWrongPin);
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
                const FailsafeBadge(forceAlert: true),
                const SizedBox(height: 16),
                Text(l10n.failsafeLockdownTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(l10n.failsafeLockdownMessage, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (!_blocked)
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
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(_message!, textAlign: TextAlign.center, style: TextStyle(color: scheme.error)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
