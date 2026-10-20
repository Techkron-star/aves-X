import 'dart:async';

import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/fx/diamond.dart';
import 'package:aves/model/security/attempt_guard.dart';
import 'package:aves/model/security/bat_curity.dart';
import 'package:aves/model/security/failsafe.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/lock_animation.dart';
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

// the screen sits above the Navigator, so it needs its own Overlay (text selection handles require one)
class _LockdownScreen extends StatefulWidget {
  const _LockdownScreen();

  @override
  State<_LockdownScreen> createState() => _LockdownScreenHostState();
}

class _LockdownScreenHostState extends State<_LockdownScreen> {
  late final OverlayEntry _entry = OverlayEntry(builder: (context) => const _LockdownBody());

  @override
  void dispose() {
    _entry.remove();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}

class _LockdownBody extends StatefulWidget {
  const _LockdownBody();

  @override
  State<_LockdownBody> createState() => _LockdownScreenState();
}

class _LockdownScreenState extends State<_LockdownBody> {
  final _controller = PinInputController();
  String? _message;
  Timer? _timer;
  int _fails = 0;

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
    final fails = await AttemptGuard.master.failures();
    final remaining = await AttemptGuard.master.remainingCooldown();
    if (!mounted) return;
    setState(() => _fails = fails);
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
    final fails = await AttemptGuard.master.failures();
    if (mounted) setState(() => _fails = fails);
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
      color: Colors.black,
      // deep ruby crystal with a slow glint: Fail-Safe has taken control
      child: AnimatedCrystal(
        animate: !settings.performanceMode,
        opacity: .3,
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
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _FailsafeBuddy(fails: _fails),
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
      ),
    );
  }
}

// Fail-Safe's little character: comments on the failed attempts with growing suspicion
class _FailsafeBuddy extends StatelessWidget {
  const _FailsafeBuddy({required this.fails});

  final int fails;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = switch (fails) {
      <= 0 => l10n.failsafeBuddy0,
      1 => l10n.failsafeBuddy1,
      2 => l10n.failsafeBuddy2,
      3 => l10n.failsafeBuddy3,
      _ => l10n.failsafeBuddy4,
    };
    final alert = fails >= 3;
    final color = alert ? const Color(0xFFFF5A6E) : const Color(0xFF3DDC84);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.5), color: Colors.black54),
          child: const Center(child: BatMark(size: 22)),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Container(
              key: ValueKey(fails.clamp(0, 4)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                border: Border.all(color: color.withValues(alpha: .6)),
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(16),
                  topEnd: Radius.circular(16),
                  bottomEnd: Radius.circular(16),
                  bottomStart: Radius.circular(3),
                ),
              ),
              child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }
}
