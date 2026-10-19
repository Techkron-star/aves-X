import 'dart:async';

import 'package:aves/model/security/app_lock.dart';
import 'package:aves/model/security/failsafe.dart';
import 'package:aves/model/security/failsafe_config.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/failsafe_badge.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

// First launch: Fail-Safe introduces itself and replaces the usual "accept the terms" window.
// The terms are there (short version), accepted by holding a button; declining closes the app.
Future<void> maybeShowFailsafeWelcome(GlobalKey<NavigatorState> navigatorKey) async {
  if (!await failsafe.needsWelcome) return;
  // wait for the app to be usable (not locked, not in lockdown)
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 750));
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) continue;
    if (!appLock.ready || appLock.locked || failsafe.lockdown.value) continue;

    final accepted = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Fail-Safe',
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
      pageBuilder: (context, _, _) => const PopScope(canPop: false, child: _Wizard()),
    );
    if (accepted == true) {
      // only marked once the terms were accepted: otherwise it asks again at the next launch
      await failsafe.markWelcomed();
    } else {
      await SystemNavigator.pop();
    }
    return;
  }
}

class _Wizard extends StatefulWidget {
  const _Wizard();

  @override
  State<_Wizard> createState() => _WizardState();
}

class _WizardState extends State<_Wizard> {
  final _pager = PageController();
  int _page = 0;
  bool _lockdown = true;

  static const _pageCount = 4;

  @override
  void initState() {
    super.initState();
    FailsafeConfig.lockdownEnabled.then((v) {
      if (mounted) setState(() => _lockdown = v);
    });
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _next() => _pager.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pager,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Step(
                    active: _page == 0,
                    lines: [l10n.failsafeWizGreeting, l10n.failsafeWizGreeting2],
                    big: true,
                  ),
                  _Step(
                    active: _page == 1,
                    lines: [l10n.failsafeWizDoes1, l10n.failsafeWizDoes2, l10n.failsafeWizDoes3],
                  ),
                  _TermsStep(
                    active: _page == 2,
                    onAccepted: _next,
                  ),
                  _SetupStep(
                    lockdown: _lockdown,
                    onLockdown: (v) async {
                      await FailsafeConfig.setLockdownEnabled(v);
                      if (mounted) setState(() => _lockdown = v);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? scheme.primary : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  if (_page < 2) FilledButton(onPressed: _next, child: Text(l10n.failsafeWizNext)),
                  if (_page == 2)
                    TextButton(
                      onPressed: () => Navigator.maybeOf(context)?.pop(false),
                      child: Text(l10n.failsafeWizDecline),
                    ),
                  if (_page == 3)
                    FilledButton(onPressed: () => Navigator.maybeOf(context)?.pop(true), child: Text(l10n.failsafeWizFinish)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatefulWidget {
  const _Step({required this.active, required this.lines, this.big = false});

  final bool active;
  final List<String> lines;
  final bool big;

  @override
  State<_Step> createState() => _StepState();
}

class _StepState extends State<_Step> {
  int _line = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: FailsafeBadge()),
          const SizedBox(height: 28),
          for (var i = 0; i < widget.lines.length; i++)
            if (i <= _line)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: widget.active
                    ? Typewriter(
                        text: widget.lines[i],
                        style: i == 0 && widget.big ? textTheme.headlineMedium : textTheme.titleMedium,
                        onDone: () {
                          if (mounted && _line == i && i < widget.lines.length - 1) {
                            Future<void>.delayed(const Duration(milliseconds: 350), () {
                              if (mounted) setState(() => _line = i + 1);
                            });
                          }
                        },
                      )
                    : const SizedBox(),
              ),
        ],
      ),
    );
  }
}

class _TermsStep extends StatelessWidget {
  const _TermsStep({required this.active, required this.onAccepted});

  final bool active;
  final VoidCallback onAccepted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final terms = [
      (Icons.cloud_off_outlined, l10n.failsafeWizTerm1),
      (Icons.lock_outline, l10n.failsafeWizTerm2),
      (Icons.warning_amber_outlined, l10n.failsafeWizTerm3),
      (Icons.favorite_outline, l10n.failsafeWizTerm4),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.failsafeWizTermsTitle, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 18),
          for (final (icon, text) in terms)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: scheme.primary),
                  const SizedBox(width: 14),
                  Expanded(child: Text(text)),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Center(child: Padding(padding: const EdgeInsets.only(bottom: 40), child: HoldToAccept(label: l10n.failsafeWizHold, onAccepted: onAccepted))),
        ],
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({required this.lockdown, required this.onLockdown});

  final bool lockdown;
  final ValueChanged<bool> onLockdown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: FailsafeBadge()),
          const SizedBox(height: 24),
          Text(l10n.failsafeWizSetupTitle, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.failsafeLockdownOption),
            subtitle: Text(l10n.failsafeLockdownOptionSubtitle),
            value: lockdown,
            onChanged: onLockdown,
          ),
          const SizedBox(height: 8),
          Text(l10n.failsafeWizSetupMore, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// text that types itself, tap to show it all
class Typewriter extends StatefulWidget {
  const Typewriter({super.key, required this.text, this.style, this.onDone});

  final String text;
  final TextStyle? style;
  final VoidCallback? onDone;

  @override
  State<Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<Typewriter> {
  int _count = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 28), (timer) {
      if (!mounted) return;
      if (_count >= widget.text.length) {
        timer.cancel();
        widget.onDone?.call();
        return;
      }
      setState(() => _count++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _skip() {
    if (_count < widget.text.length) {
      setState(() => _count = widget.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      // the full text takes the space from the start, so that the layout does not jump while typing
      child: Stack(
        children: [
          Opacity(opacity: 0, child: Text(widget.text, style: widget.style)),
          Text(widget.text.substring(0, _count), style: widget.style),
        ],
      ),
    );
  }
}

// a button that must be held to be accepted, with a ring that fills up
class HoldToAccept extends StatefulWidget {
  const HoldToAccept({super.key, required this.label, required this.onAccepted});

  final String label;
  final VoidCallback onAccepted;

  @override
  State<HoldToAccept> createState() => _HoldToAcceptState();
}

class _HoldToAcceptState extends State<HoldToAccept> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        widget.onAccepted();
      }
    });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.status == AnimationStatus.completed ? null : _controller.reverse(),
      onTapCancel: () => _controller.status == AnimationStatus.completed ? null : _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: CircularProgressIndicator(value: _controller.value, strokeWidth: 5, color: scheme.primary, backgroundColor: scheme.outlineVariant),
            ),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary.withValues(alpha: .15 + .5 * _controller.value)),
              child: Icon(Icons.fingerprint, size: 40, color: scheme.primary),
            ),
            Positioned(
              bottom: -26,
              child: Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}
