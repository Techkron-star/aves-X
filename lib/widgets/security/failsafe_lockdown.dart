import 'dart:async';

import 'package:aves/model/security/failsafe_quips.dart';
import 'package:aves/model/security/failsafe_voice.dart';

import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/widgets/common/fx/diamond.dart';
import 'package:aves/model/security/attempt_guard.dart';
import 'package:aves/model/security/master_guard.dart';
import 'package:aves/model/security/failsafe.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/app_mark.dart';
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
    bool ok = false;
    try {
      ok = await masterGuard.matches('master_code', code);
    } catch (e, stack) {
      await reportService.recordError(e, stack);
      // If matching fails unexpectedly, treat as incorrect code but log the error
      ok = false;
    }
    _controller.clear();
    if (ok) {
      // Master Code correct: reset attempt guards and release lockdown
      // CRITICAL: Never register a failure for the Master Code
      await AttemptGuard.master.reset();
      await AttemptGuard.app.reset();
      await failsafe.releaseLockdown();
      return;
    }
    // Incorrect code: register failure normally
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
    final nebula = Theme.of(context).nebula;
    return Material(
      color: nebula.securityScrim,
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
                  child: FailsafeBuddy(fails: _fails),
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

// Fail-Safe's little character: comments on the failed attempts with growing suspicion.
// The line is picked at random among many for each level, and said out loud with the character's voice.
class FailsafeBuddy extends StatefulWidget {
  const FailsafeBuddy({super.key, required this.fails});

  final int fails;

  @override
  State<FailsafeBuddy> createState() => _FailsafeBuddyState();
}

class _FailsafeBuddyState extends State<FailsafeBuddy> {
  String? _line;
  int? _lineFails;
  String? _voiceError;

  // picks a new line when the number of failures changes, and says it (when there is something to react to)
  String _currentLine(BuildContext context) {
    final fails = widget.fails;
    if (_line == null || _lineFails != fails) {
      _lineFails = fails;
      final line = FailsafeQuips.pick(Localizations.localeOf(context).languageCode, fails);
      _line = line;
      if (fails > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted || _line != line) return;
          final status = await FailsafeVoice.say(line);
          if (!mounted || _line != line) return;
          // these screens have no scaffold for a snack bar, so a failure is shown right under the bubble
          setState(() => _voiceError = FailsafeVoice.isFailure(status) ? FailsafeVoice.describe(context.l10n, status) : null);
        });
      }
    }
    return _line!;
  }

  @override
  Widget build(BuildContext context) {
    final fails = widget.fails;
    final text = _currentLine(context);
    final alert = fails >= 3;
    final nebula = Theme.of(context).nebula;
    final color = alert ? nebula.securityAlert : nebula.securityOk;
    final voiceError = _voiceError;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.5), color: Colors.black54),
              child: const Center(child: AppMark(size: 22)),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Container(
                  key: ValueKey('$fails$text'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: nebula.securityBubbleSurface.withValues(alpha: .08),
                    border: Border.all(color: nebula.securityBubbleBorder.withValues(alpha: .6)),
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
        ),
        if (voiceError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_off, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Flexible(child: Text(voiceError, style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic))),
              ],
            ),
          ),
      ],
    );
  }
}
