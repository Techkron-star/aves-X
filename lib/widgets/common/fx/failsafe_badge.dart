import 'package:aves/model/security/master_code.dart';
import 'dart:math' as math;

import 'package:aves/model/security/failsafe.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/lock_animation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

// only the safe-mode banner still uses a fixed alert red (tokenized in the lockdown phase)
const _alert = Color(0xFFFF3B3B);

// "Failsafe: online" indicator with a radar pulse. Tap to see the diagnosis.
class FailsafeBadge extends StatefulWidget {
  const FailsafeBadge({super.key, this.forceAlert = false, this.interactive = true});

  final bool forceAlert;
  // false: no tap to open the report (welcome screens)
  final bool interactive;

  @override
  State<FailsafeBadge> createState() => _FailsafeBadgeState();
}

class _FailsafeBadgeState extends State<FailsafeBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  // irrelevant when the pulse is disabled: the radar stays still
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _syncAnimation();
    // accessibility change ('animate') or performance mode can be toggled while the badge is alive
    settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (settings.animate == _animating) return;
    // settings can notify during a build: start/stop the ticker after the frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncAnimation();
    });
  }

  void _syncAnimation() {
    // settings.animate already includes !performanceMode
    _animating = settings.animate;
    if (_animating) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    settings.removeListener(_onSettingsChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: failsafe.safeMode,
      builder: (context, safeMode, _) {
        final safe = safeMode || widget.forceAlert;
        final nebula = Theme.of(context).nebula;
        final color = safe ? nebula.securityAlert : nebula.securityOk;
        return InkWell(
          onTap: (widget.forceAlert || !widget.interactive) ? null : () => showFailsafeReport(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // the pulse repaints a few dozen pixels, keep it away from the tile/parent
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => CustomPaint(
                            size: const Size.square(36),
                            painter: _RadarPainter(_controller.value, color, safe),
                          ),
                        ),
                      ),
                      const BatMark(size: 16),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.forceAlert ? context.l10n.failsafeLockdownActive : (safe ? context.l10n.failsafeSafeMode : context.l10n.failsafeOnline),
                        style: TextStyle(color: color, fontWeight: FontWeight.w600, letterSpacing: .6),
                      ),
                      if (!widget.forceAlert)
                        Text(
                          context.l10n.failsafeTapForReport,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter(this.t, this.color, this.alert);

  final double t;
  final Color color;
  final bool alert;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r - 1, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: .35));
    // two expanding rings, the alert state pulses faster
    for (final phase in [0.0, .5]) {
      final p = ((t * (alert ? 2 : 1)) + phase) % 1.0;
      canvas.drawCircle(
        c,
        r * (.3 + .7 * p),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = color.withValues(alpha: (1 - p) * .7),
      );
    }
    // rotating sweep
    final angle = t * 2 * math.pi;
    final rect = Rect.fromCircle(center: c, radius: r - 2);
    canvas.drawArc(
      rect,
      angle - .9,
      .9,
      true,
      Paint()
        ..shader = SweepGradient(
          startAngle: angle - .9,
          endAngle: angle,
          colors: [color.withValues(alpha: 0), color.withValues(alpha: .5)],
          transform: GradientRotation(angle - .9),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t || old.color != color;
}

// top strip shown over everything while in safe mode
class SafeModeBanner extends StatelessWidget {
  const SafeModeBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<bool>(
          valueListenable: failsafe.safeMode,
          builder: (context, safe, _) {
            if (!safe) return const SizedBox();
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 2, bottom: 3),
                  color: _alert.withValues(alpha: .92),
                  alignment: Alignment.center,
                  child: Text(
                    context.l10n.failsafeSafeMode.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

Future<void> showFailsafeReport(BuildContext context) {
  final report = failsafe.buildReport();
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.failsafeReportTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(report, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
        ),
      ),
      actions: [
        if (failsafe.safeMode.value)
          TextButton(
            onPressed: () async {
              if (await MasterCode.require(context) && context.mounted) {
                await failsafe.exitSafeMode();
                if (context.mounted) Navigator.maybeOf(context)?.pop();
              }
            },
            child: Text(context.l10n.failsafeExitSafeMode),
          ),
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: report)),
          child: Text(context.l10n.failsafeCopy),
        ),
        TextButton(
          onPressed: () => Navigator.maybeOf(context)?.pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    ),
  );
}
