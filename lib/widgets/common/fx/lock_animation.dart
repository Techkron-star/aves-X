import 'dart:math';
import 'dart:ui' as ui;

import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_material.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/widgets/common/fx/liquid.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

// Badge shown over locked thumbnails, in place of a plain padlock icon.
// When the item was just locked (`fresh`), it plays a short animation over the thumbnail:
// two chains crossing in an X, then the padlock falling on the crossing.
// With "Nosferatu Glass": ruby chains and a translucent bat with a keyhole, with a shimmering light inside.
// Call `playUnlockAnimation()` to play the unlock animation when the item is unlocked.
class LockedBadge extends StatefulWidget {
  final bool fresh;

  const LockedBadge({super.key, this.fresh = false});

  @override
  State<LockedBadge> createState() => LockedBadgeState();
}

class LockedBadgeState extends State<LockedBadge> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _unlockController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  bool get _playing => widget.fresh && settings.animate && !settings.performanceMode;
  bool _unlocking = false;
  bool _unlockAnimationCompleted = false;

  @override
  void initState() {
    super.initState();
    if (_playing) {
      _controller.forward();
      // the "impact" of the padlock on the chains
      Future.delayed(const Duration(milliseconds: 600), () => HapticFeedback.heavyImpact());
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _unlockController.dispose();
    super.dispose();
  }

  void playUnlockAnimation() {
    if (_unlocking || _unlockAnimationCompleted) return;

    // In reduced-motion/performance mode, remove the transition overlay immediately.
    // Do not leave a static lock sitting on top of an already-unlocked thumbnail.
    if (!settings.animate || settings.performanceMode) {
      setState(() => _unlockAnimationCompleted = true);
      return;
    }

    setState(() => _unlocking = true);
    _unlockController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _unlocking = false;
        _unlockAnimationCompleted = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = settings.materialStyle;
    // themes without their own glass material tint the chains with their Nebula tokens
    final tokens = settings.nebulaTheme == NebulaTheme.aves ? null : Theme.of(context).nebula;
    final chainColors = style?.chain ?? (tokens == null ? null : [tokens.securityCrystalHighlight, tokens.securityCrystalBody.last]);
    final chainStroke = style?.chainStroke ?? tokens?.securityCrystalEdge;
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = min(constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0, constraints.maxHeight.isFinite ? constraints.maxHeight : 120.0);
        final lockSize = (box * .4).clamp(22.0, 64.0);
        final scale = box / 220;
        return AnimatedBuilder(
          animation: Listenable.merge([_controller, _unlockController]),
          builder: (context, _) {
            final t = _controller.value;
            final chains = Curves.easeOut.transform((t / 0.35).clamp(0, 1));
            final fall = Curves.bounceOut.transform(((t - 0.3) / 0.45).clamp(0, 1));
            final shake = t > 0.6 && t < 0.78 ? sin((t - 0.6) * 90) * 2 : 0.0;
            if (_unlockAnimationCompleted) return const SizedBox.shrink();

            final unlockProgress = Curves.easeOutCubic.transform(_unlockController.value);
            final isUnlocking = _unlocking && _unlockController.value < 1;
            return Stack(
              alignment: Alignment.center,
              children: [
                // the chains stay in place once locked (not in performance mode: padlock only)
                if (!settings.performanceMode && !isUnlocking)
                  Positioned.fill(
                    child: CustomPaint(painter: _ChainsPainter(progress: chains, colors: chainColors, stroke: chainStroke, scale: scale)),
                  ),
                Transform.translate(
                  offset: Offset(
                    shake,
                    -(1 - fall) * box * .9 - box * .18 * unlockProgress,
                  ),
                  child: Opacity(
                    opacity: 1 - unlockProgress,
                    child: Transform.rotate(
                      angle: -.18 * unlockProgress,
                      child: Transform.scale(
                        scale: 1 + .3 * unlockProgress,
                        child: SizedBox(
                          width: lockSize,
                          height: lockSize,
                          child: _Shimmer(
                            enabled: style != null && settings.animate,
                            color: style?.shimmer ?? const Color(0xFFFFB3BF),
                            child: CustomPaint(
                              painter: _PadlockPainter(
                                material: style?.material,
                                style: style,
                                open: isUnlocking,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// a soft light sweeping across the child from time to time, keeping its shape and details
class _Shimmer extends StatelessWidget {
  final bool enabled;
  final Color color;
  final Widget child;

  const _Shimmer({required this.enabled, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return RandomBurst(
      enabled: enabled,
      duration: const Duration(milliseconds: 1500),
      child: child,
      builder: (context, t, child) {
        // fade in and out, so that the effect starts and ends without a visible cut
        final e = sin(pi * t);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0x00FFFFFF), color.withValues(alpha: .7 * e), const Color(0x00FFFFFF)],
            stops: const [.25, .5, .75],
            transform: _Slide(t),
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class _Slide extends GradientTransform {
  final double t;

  const _Slide(this.t);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(bounds.width * (t * 2.4 - 1.2), bounds.height * (t * 2.4 - 1.2), 0);
}

class _ChainsPainter extends CustomPainter {
  final double progress, scale;
  final List<Color>? colors;
  final Color? stroke;

  const _ChainsPainter({required this.progress, required this.colors, required this.stroke, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final reach = size.shortestSide * 0.62 * progress;
    for (final angle in [pi / 4, -pi / 4]) {
      final dir = Offset(cos(angle), sin(angle));
      final linkLength = 16.0 * scale;
      final count = (reach * 2 / linkLength).floor();
      for (var i = 0; i < count; i++) {
        final d = -reach + (i + .5) * linkLength;
        canvas.save();
        canvas.translate(c.dx + dir.dx * d, c.dy + dir.dy * d);
        canvas.rotate(angle + (i.isEven ? 0 : pi / 2));
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: linkLength + 4 * scale, height: (i.isEven ? 11 : 6) * scale),
          Radius.circular(5 * scale),
        );
        final fill = Paint()
          ..shader = (colors != null
                  ? LinearGradient(colors: colors!)
                  : const LinearGradient(colors: [Color(0xFFE0E0E0), Color(0xFF6E6E6E)]))
              .createShader(rect.outerRect);
        canvas.drawRRect(rect, fill);
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4 * scale
            ..color = stroke ?? const Color(0xFF3A3A3A),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChainsPainter old) => old.progress != progress || old.colors != colors || old.stroke != stroke || old.scale != scale;
}

class _PadlockPainter extends CustomPainter {
  // emblem of the active glass theme: a bat (Nosferatu), a demon eye (Night Demon), a haloed padlock (Godly);
  // a plain padlock without a glass theme
  final NebulaMaterial? material;
  final NebulaMaterialStyle? style;
  final bool open;
  final bool keyhole;
  const _PadlockPainter({required this.material, required this.open, this.keyhole = true, this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s);
    if (material == NebulaMaterial.ruby) {
      _paintBat(canvas);
    } else if (material == NebulaMaterial.nightDemon) {
      _paintDemon(canvas);
    } else if (material == NebulaMaterial.godly) {
      _paintHalo(canvas);
    } else if (material != null && style != null) {
      _paintSignature(canvas, material!, style!, open);
    } else {
      _paintPadlock(canvas);
    }
  }

  // Night Demon: a horned shard of obsidian with a glowing slit eye.
  // When unlocked the horns lift and the pupil widens.
  void _paintDemon(Canvas canvas) {
    const violet = Color(0xFF9B5DE5);
    const hot = Color(0xFFE9D5FF);

    // horns, drawn once and mirrored
    final horn = Path()
      ..moveTo(33, 46)
      ..quadraticBezierTo(14, 34, 22, 6)
      ..quadraticBezierTo(32, 24, 44, 36)
      ..close();
    void drawHorn() {
      canvas.drawPath(
        horn,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFF2A0A52), Color(0xFF0B0314)],
          ).createShader(horn.getBounds()),
      );
      canvas.drawPath(
        horn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round
          ..color = violet,
      );
    }

    canvas.save();
    canvas.translate(0, open ? -7.0 : 0.0);
    drawHorn();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    drawHorn();
    canvas.restore();

    // body: a cut shard
    final body = Path()
      ..moveTo(50, 38)
      ..lineTo(80, 50)
      ..lineTo(75, 78)
      ..lineTo(50, 95)
      ..lineTo(25, 78)
      ..lineTo(20, 50)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = violet.withValues(alpha: .5)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B1470), Color(0xFF150629), Color(0xFF050109)],
        ).createShader(body.getBounds()),
    );
    canvas.drawPath(
      Path()
        ..moveTo(50, 38)
        ..lineTo(40, 62)
        ..moveTo(50, 38)
        ..lineTo(60, 62)
        ..moveTo(40, 62)
        ..lineTo(50, 95)
        ..moveTo(60, 62)
        ..lineTo(50, 95),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = violet.withValues(alpha: .3),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = violet,
    );

    // the eye
    final eye = Path()
      ..moveTo(29, 64)
      ..quadraticBezierTo(50, 46, 71, 64)
      ..quadraticBezierTo(50, 82, 29, 64)
      ..close();
    canvas.drawPath(
      eye,
      Paint()
        ..color = violet.withValues(alpha: .55)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
    );
    canvas.drawPath(
      eye,
      Paint()
        ..shader = const RadialGradient(colors: [hot, Color(0xFFB26BFF), Color(0xFF6A1B9A)]).createShader(eye.getBounds()),
    );
    canvas.drawPath(
      eye,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF1A0530),
    );
    if (keyhole) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 64), width: open ? 5.5 : 2.6, height: 17),
        Paint()..color = const Color(0xFF07010F),
      );
    }
  }

  // Godly: a gold padlock with a halo above it and a pair of wings.
  // When unlocked the shackle opens and the halo rises.
  void _paintHalo(Canvas canvas) {
    const light = Color(0xFFFFF6D5);
    const aura = Offset(50, 56);

    // aura
    canvas.drawCircle(
      aura,
      46,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0x55FFF2C0), Color(0x00FFF2C0)]).createShader(Rect.fromCircle(center: aura, radius: 46)),
    );

    // wings, drawn once and mirrored
    final wing = Path()
      ..moveTo(34, 58)
      ..quadraticBezierTo(16, 40, 1, 43)
      ..quadraticBezierTo(7, 52, 3, 57)
      ..quadraticBezierTo(13, 60, 10, 67)
      ..quadraticBezierTo(21, 68, 19, 75)
      ..quadraticBezierTo(29, 73, 34, 70)
      ..close();
    void drawWing() {
      canvas.drawPath(
        wing,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xF2FFF6D5), Color(0xCCE6B94A)],
          ).createShader(wing.getBounds()),
      );
      canvas.drawPath(
        wing,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xCCB8860B),
      );
    }

    canvas.save();
    drawWing();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    drawWing();
    canvas.restore();

    // shackle
    canvas.drawPath(
      Path()
        ..moveTo(41, 52)
        ..lineTo(41, 41)
        ..arcToPoint(const Offset(59, 41), radius: const Radius.circular(9), clockwise: true)
        ..lineTo(59, open ? 38 : 52),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE8C547),
    );

    // body
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(33, 52, 34, 32), const Radius.circular(8));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE9A3), Color(0xFFB8860B)],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF5C4300),
    );
    if (keyhole) {
      final hole = Paint()..color = const Color(0xFF3B2A00);
      canvas.drawCircle(const Offset(50, 65), 4, hole);
      canvas.drawRect(const Rect.fromLTWH(48.3, 65, 3.4, 10), hole);
    }

    // halo
    final halo = Rect.fromCenter(center: Offset(50, open ? 12 : 20), width: 40, height: 11);
    canvas.drawOval(
      halo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = light.withValues(alpha: .45)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
    );
    canvas.drawOval(
      halo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFFE9A3),
    );

    // two sparkles
    for (final c in const [Offset(86, 26), Offset(14, 32)]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - 4.5)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + 4.5, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + 4.5)
          ..quadraticBezierTo(c.dx, c.dy, c.dx - 4.5, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - 4.5)
          ..close(),
        Paint()..color = light,
      );
    }
  }

  // Every remaining glass theme has a bespoke seal around a universal lock/keyhole.
  void _paintSignature(Canvas canvas, NebulaMaterial material, NebulaMaterialStyle style, bool open) {
    final accent = style.accent;
    final light = style.liquidHighlight;
    final deep = style.liquidDeep;
    void stroke(Path path, {double width = 2.2, Color? color}) {
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color ?? accent);
    }
    void dot(Offset point, double radius, Color color) {
      canvas.drawCircle(point, radius, Paint()..color = color);
    }
    Path polygon(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      return path..close();
    }

    switch (material) {
      case NebulaMaterial.forge:
        stroke(Path()..moveTo(50, 6)..cubicTo(70, 25, 34, 30, 53, 42)..cubicTo(26, 35, 27, 19, 39, 12), width: 3, color: light);
        for (final point in const [Offset(17, 31), Offset(83, 31), Offset(20, 61), Offset(80, 61)]) { dot(point, 2.4, accent); }
        break;
      case NebulaMaterial.hermetic:
        canvas.drawCircle(const Offset(50, 42), 36, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..color = accent);
        stroke(polygon(const [Offset(50, 8), Offset(81, 65), Offset(19, 65)]), width: 1.8, color: light);
        dot(const Offset(50, 8), 3, light); dot(const Offset(19, 65), 3, accent); dot(const Offset(81, 65), 3, accent);
        break;
      case NebulaMaterial.eclipse:
        canvas.drawCircle(const Offset(50, 38), 31, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..color = accent);
        canvas.drawCircle(const Offset(61, 28), 24, Paint()..color = style.surface);
        canvas.drawArc(Rect.fromCircle(center: const Offset(50, 38), radius: 31), -pi * .72, pi * 1.42, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.3..color = light);
        break;
      case NebulaMaterial.solarFlare:
        for (var i = 0; i < 12; i++) {
          final angle = i * pi / 6;
          final start = Offset(50 + cos(angle) * 34, 36 + sin(angle) * 34);
          final end = Offset(50 + cos(angle) * 43, 36 + sin(angle) * 43);
          final rayPaint = Paint()..color = i.isEven ? light : accent;
          rayPaint.strokeWidth = i.isEven ? 2.7 : 1.7;
          rayPaint.strokeCap = StrokeCap.round;
          canvas.drawLine(start, end, rayPaint);
        }
        break;
      case NebulaMaterial.voidGlass:
        stroke(polygon(const [Offset(50, 4), Offset(79, 16), Offset(92, 43), Offset(78, 70), Offset(50, 83), Offset(22, 70), Offset(8, 43), Offset(21, 16)]), width: 2.1, color: light);
        stroke(polygon(const [Offset(50, 14), Offset(70, 23), Offset(80, 43), Offset(70, 62), Offset(50, 72), Offset(30, 62), Offset(20, 43), Offset(30, 23)]), width: 1.4, color: accent);
        for (var i = 0; i < 8; i++) { final angle = i * pi / 4; dot(Offset(50 + cos(angle) * 41, 43 + sin(angle) * 35), 1.9, light); }
        break;
      case NebulaMaterial.crimson:
        for (var i = 0; i < 3; i++) { stroke(Path()..moveTo(31 + i * 19, 12)..lineTo(23 + i * 19, 31)..lineTo(34 + i * 19, 27), width: 2.7, color: i == 1 ? light : accent); }
        break;
      case NebulaMaterial.neon:
        stroke(polygon(const [Offset(25, 12), Offset(67, 12), Offset(79, 24), Offset(79, 60), Offset(25, 60)]), width: 2.2, color: light);
        stroke(polygon(const [Offset(16, 21), Offset(58, 21), Offset(70, 33), Offset(70, 69), Offset(16, 69)]), width: 1.5, color: accent);
        canvas.drawLine(const Offset(61, 12), const Offset(71, 22), Paint()..color = light..strokeWidth = 2);
        canvas.drawLine(const Offset(16, 60), const Offset(25, 69), Paint()..color = accent..strokeWidth = 2);
        break;
      case NebulaMaterial.emerald:
        stroke(Path()..moveTo(50, 7)..cubicTo(82, 26, 80, 58, 50, 77)..cubicTo(20, 58, 18, 26, 50, 7)..close(), width: 2.2, color: light);
        stroke(Path()..moveTo(50, 15)..cubicTo(49, 36, 52, 53, 50, 73), width: 1.6);
        stroke(Path()..moveTo(50, 35)..lineTo(31, 25)..moveTo(50, 47)..lineTo(68, 36)..moveTo(50, 59)..lineTo(34, 49), width: 1.4, color: light);
        break;
      case NebulaMaterial.aurora:
        stroke(Path()..moveTo(9, 30)..cubicTo(23, 10, 34, 48, 49, 29)..cubicTo(64, 10, 76, 45, 91, 25), width: 3, color: light);
        stroke(Path()..moveTo(8, 43)..cubicTo(23, 24, 36, 58, 50, 42)..cubicTo(65, 25, 77, 57, 92, 40), width: 2.2, color: accent);
        break;
      case NebulaMaterial.sapphire:
        stroke(polygon(const [Offset(50, 3), Offset(81, 30), Offset(69, 67), Offset(50, 82), Offset(31, 67), Offset(19, 30)]), width: 2.2, color: light);
        stroke(Path()..moveTo(19, 30)..lineTo(50, 38)..lineTo(81, 30)..moveTo(31, 67)..lineTo(50, 38)..lineTo(69, 67), width: 1.5);
        break;
      case NebulaMaterial.amber:
        for (final center in const [Offset(50, 15), Offset(31, 32), Offset(69, 32), Offset(31, 54), Offset(69, 54), Offset(50, 70)]) {
          stroke(polygon([Offset(center.dx, center.dy - 9), Offset(center.dx + 8, center.dy - 4), Offset(center.dx + 8, center.dy + 4), Offset(center.dx, center.dy + 9), Offset(center.dx - 8, center.dy + 4), Offset(center.dx - 8, center.dy - 4)]), width: 1.2, color: accent);
        }
        break;
      case NebulaMaterial.onyx:
        for (final radius in const [24.0, 31.0, 39.0]) {
          final ringPaint = Paint()..style = PaintingStyle.stroke..color = radius == 31 ? light : accent.withValues(alpha: .65);
          ringPaint.strokeWidth = radius == 31 ? 2.4 : 1.2;
          canvas.drawCircle(const Offset(50, 41), radius, ringPaint);
        }
        break;
      case NebulaMaterial.pearl:
        for (var i = 0; i < 5; i++) {
          final arcPaint = Paint()..style = PaintingStyle.stroke..color = i.isEven ? light : accent;
          arcPaint.strokeWidth = 1.6;
          canvas.drawArc(Rect.fromCircle(center: const Offset(50, 34), radius: 17 + i * 5.5), pi * 1.05, pi * .9, false, arcPaint);
        }
        dot(const Offset(50, 10), 2.4, light);
        break;
      case NebulaMaterial.ivory:
        stroke(Path()..moveTo(18, 46)..lineTo(18, 31)..quadraticBezierTo(50, -2, 82, 31)..lineTo(82, 46), width: 2.5, color: light);
        stroke(Path()..moveTo(22, 45)..quadraticBezierTo(32, 25, 42, 39)..moveTo(78, 45)..quadraticBezierTo(68, 25, 58, 39), width: 1.8, color: accent);
        break;
      case NebulaMaterial.imperial:
        stroke(polygon(const [Offset(50, 5), Offset(83, 17), Offset(78, 51), Offset(50, 78), Offset(22, 51), Offset(17, 17)]), width: 2.4, color: light);
        final spine = Paint()..color = accent;
        spine.strokeWidth = 1.5;
        canvas.drawLine(const Offset(50, 18), const Offset(50, 65), spine);
        for (final point in const [Offset(25, 22), Offset(75, 22), Offset(50, 70)]) { dot(point, 2.2, light); }
        break;
      case NebulaMaterial.ruby:
      case NebulaMaterial.nightDemon:
      case NebulaMaterial.godly:
        return;
    }

    final shackle = Path()
      ..moveTo(37, 49)..lineTo(37, 36)
      ..arcToPoint(const Offset(63, 36), radius: const Radius.circular(13), clockwise: true)
      ..lineTo(63, open ? 44 : 49);
    canvas.drawPath(shackle, Paint()..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round..color = style.chainStroke);
    final radius = switch (material) {
      NebulaMaterial.solarFlare => 3.0,
      NebulaMaterial.hermetic || NebulaMaterial.voidGlass || NebulaMaterial.imperial => 2.0,
      NebulaMaterial.pearl || NebulaMaterial.aurora => 15.0,
      _ => 8.0,
    };
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(27, 46, 46, 39), Radius.circular(radius));
    canvas.drawRRect(body, Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, accent, deep]).createShader(body.outerRect));
    canvas.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.7..color = style.edge);
    final keyholeColor = switch (material) {
      NebulaMaterial.pearl => const Color(0xFF583A4C),
      NebulaMaterial.ivory => const Color(0xFF51401F),
      _ => deep,
    };
    if (keyhole) {
      canvas.drawCircle(const Offset(50, 59), 4.2, Paint()..color = keyholeColor);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(47.8, 62, 4.4, 12), const Radius.circular(2)), Paint()..color = keyholeColor);
    }
    if (open) {
      final openPaint = Paint()..color = light;
      openPaint.strokeWidth = 2.4;
      openPaint.strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(50, 38), const Offset(50, 31), openPaint);
    }
  }

  void _paintPadlock(Canvas canvas) {
    final shackle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB8B8B8);
    final shacklePath = Path()
      ..moveTo(32, 46)
      ..lineTo(32, 32)
      ..arcToPoint(const Offset(68, 32), radius: const Radius.circular(18), clockwise: true)
      ..lineTo(68, open ? 30 : 46);
    canvas.drawPath(shacklePath, shackle);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(22, 44, 56, 44), const Radius.circular(9));
    canvas.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2C94C), Color(0xFFB8860B)]).createShader(body.outerRect));
    canvas.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFF5C4300));
    canvas.drawCircle(const Offset(50, 62), 6, Paint()..color = const Color(0xFF3B2A00));
    canvas.drawRect(const Rect.fromLTWH(47.5, 62, 5, 14), Paint()..color = const Color(0xFF3B2A00));
  }

  // translucent ruby bat with a keyhole
  void _paintBat(Canvas canvas) {
    final path = Path()
      // body and head
      ..moveTo(50, 22)
      ..lineTo(43, 8)
      ..lineTo(41, 26)
      // left wing
      ..cubicTo(26, 20, 8, 28, 2, 48)
      ..quadraticBezierTo(10, 50, 15, 47)
      ..quadraticBezierTo(21, 62, 29, 56)
      ..quadraticBezierTo(33, 72, 42, 64)
      ..lineTo(50, 92)
      // right wing (mirrored)
      ..lineTo(58, 64)
      ..quadraticBezierTo(67, 72, 71, 56)
      ..quadraticBezierTo(79, 62, 85, 47)
      ..quadraticBezierTo(90, 50, 98, 48)
      ..cubicTo(92, 28, 74, 20, 59, 26)
      ..lineTo(57, 8)
      ..close();
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xB3FF6A80), Color(0x99C4122F), Color(0xB37A0A1E)],
        ).createShader(bounds),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xCCFFB3BF),
    );
    if (!keyhole) return;
    // keyhole, with a small key shape when unlocked
    final hole = Paint()..color = const Color(0xFF1A0308);
    canvas.drawCircle(const Offset(50, 50), 6, hole);
    canvas.drawPath(Path()..moveTo(46.5, 54)..lineTo(53.5, 54)..lineTo(55.5, 70)..lineTo(44.5, 70)..close(), hole);
    if (open) {
      canvas.drawLine(const Offset(50, 40), const Offset(50, 30), Paint()..color = const Color(0xFFFFB3BF)..strokeWidth = 3..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _PadlockPainter old) => old.material != material || old.open != open || old.keyhole != keyhole;
}