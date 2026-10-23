import 'package:aves/model/security/master_code.dart';
import 'dart:math' as math;

import 'package:aves/model/security/failsafe.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/security/failsafe_sprite.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

const _alert = Color(0xFFFF3B3B);

class FailsafeBadge extends StatefulWidget {
  const FailsafeBadge({super.key, this.forceAlert = false, this.interactive = true});

  final bool forceAlert;
  final bool interactive;

  @override
  State<FailsafeBadge> createState() => _FailsafeBadgeState();
}

class _FailsafeBadgeState extends State<FailsafeBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _syncAnimation();
    settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (settings.animate == _animating) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncAnimation();
    });
  }

  void _syncAnimation() {
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
        final title = widget.forceAlert
            ? context.l10n.failsafeLockdownActive
            : (safe ? context.l10n.failsafeSafeMode : context.l10n.failsafeOnline);
        return InkWell(
          onTap: (widget.forceAlert || !widget.interactive) ? null : () => showFailsafeReport(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: nebula.securityBubbleSurface.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: .28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) => CustomPaint(
                                size: const Size.square(30),
                                painter: _RadarPainter(_controller.value, color, safe),
                              ),
                            ),
                          ),
                          FailsafeSprite(
                            size: 20,
                            mood: widget.forceAlert
                                ? FailsafeSpriteMood.lockdown
                                : safeMode
                                    ? FailsafeSpriteMood.alert
                                    : FailsafeSpriteMood.idle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
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
    canvas.drawCircle(
      c,
      r * .35,
      Paint()
        ..color = color.withValues(alpha: .09)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.7),
    );
    canvas.drawCircle(c, r - 3, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: .38));
    for (final phase in [0.0, .5]) {
      final p = ((t * (alert ? 2 : 1)) + phase) % 1.0;
      final fade = math.pow(1 - p, 1.35).toDouble();
      canvas.drawCircle(
        c,
        r * (.24 + .58 * p),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.35
          ..color = color.withValues(alpha: fade * .66)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .4),
      );
    }
    final angle = t * 2 * math.pi;
    final rect = Rect.fromCircle(center: c, radius: r - 4);
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
