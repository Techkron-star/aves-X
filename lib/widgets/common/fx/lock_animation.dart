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
  final bool keyhole = true;
  const _PadlockPainter({required this.material, required this.open, this.style});

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
    } else if (material == NebulaMaterial.imperial) {
      _paintCrest(canvas);
    } else if (material == NebulaMaterial.solarFlare) {
      _paintSun(canvas);
    } else if (material == NebulaMaterial.abyssal) {
      _paintJelly(canvas);
    } else if (material == NebulaMaterial.sakura) {
      _paintBlossom(canvas);
    } else if (material == NebulaMaterial.aurora) {
      _paintAurora(canvas);
    } else if (material == NebulaMaterial.sapphire) {
      _paintGem(canvas);
    } else if (material == NebulaMaterial.amber) {
      _paintResin(canvas);
    } else if (material == NebulaMaterial.onyx) {
      _paintOnyx(canvas);
    } else if (material == NebulaMaterial.pearl) {
      _paintPearl(canvas);
    } else if (material == NebulaMaterial.ivory) {
      _paintIvory(canvas);
    } else if (material == NebulaMaterial.neon) {
      _paintNeon(canvas);
    } else if (material == NebulaMaterial.voidGlass) {
      _paintVoid(canvas);
    } else if (material == NebulaMaterial.forge) {
      _paintAnvil(canvas);
    } else if (material == NebulaMaterial.hermetic) {
      _paintCircle(canvas);
    } else if (material == NebulaMaterial.eclipse) {
      _paintMoon(canvas);
    } else if (material == NebulaMaterial.crimson) {
      _paintHeart(canvas);
    } else if (material == NebulaMaterial.emerald) {
      _paintPrism(canvas);
    } else if (material == NebulaMaterial.noxTerroris) {
      _paintNoxTerroris(canvas);
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
      case NebulaMaterial.abyssal:
      case NebulaMaterial.sakura:
      case NebulaMaterial.imperial:
        stroke(polygon(const [Offset(50, 5), Offset(83, 17), Offset(78, 51), Offset(50, 78), Offset(22, 51), Offset(17, 17)]), width: 2.4, color: light);
        final spine = Paint()..color = accent;
        spine.strokeWidth = 1.5;
        canvas.drawLine(const Offset(50, 18), const Offset(50, 65), spine);
        for (final point in const [Offset(25, 22), Offset(75, 22), Offset(50, 70)]) { dot(point, 2.2, light); }
        break;
      case NebulaMaterial.noxTerroris:
        stroke(polygon(const [Offset(50, 5), Offset(78, 24), Offset(82, 51), Offset(64, 75), Offset(50, 84), Offset(36, 75), Offset(18, 51), Offset(22, 24)]), width: 2.4, color: light);
        stroke(Path()..moveTo(27, 42)..quadraticBezierTo(38, 34, 47, 43)..quadraticBezierTo(38, 51, 27, 42), width: 1.6, color: accent);
        stroke(Path()..moveTo(53, 43)..quadraticBezierTo(64, 35, 73, 43)..quadraticBezierTo(64, 51, 53, 43), width: 1.4, color: light);
        stroke(Path()..moveTo(50, 42)..lineTo(50, 61), width: 2.0, color: accent);
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

  // the shackle of the padlocks below: lifts when the item is unlocked
  void _shackle(Canvas canvas, Color color, {double width = 7, Color? glow}) {
    final lift = open ? -7.0 * (open ? 1.0 : 0.0) : 0.0;
    final path = Path()
      ..moveTo(35, 50 + lift)
      ..lineTo(35, 34 + lift)
      ..cubicTo(35, 10 + lift, 65, 10 + lift, 65, 34 + lift)
      ..lineTo(65, open ? 40 + lift : 50);
    if (glow != null) {
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = width + 4..strokeCap = StrokeCap.round..color = glow..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3));
    }
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = width..strokeCap = StrokeCap.round..color = color);
  }

  void _keyhole(Canvas canvas, Offset c, Color color, {double scale = 1}) {
    if (!keyhole) return;
    canvas.drawCircle(c, 4.6 * scale, Paint()..color = color);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 2.4 * scale, c.dy + 2 * scale)
        ..lineTo(c.dx + 2.4 * scale, c.dy + 2 * scale)
        ..lineTo(c.dx + 3.4 * scale, c.dy + 11 * scale)
        ..lineTo(c.dx - 3.4 * scale, c.dy + 11 * scale)
        ..close(),
      Paint()..color = color,
    );
  }

  // Imperial: a riveted steel padlock under a gilded pair of wings.
  void _paintCrest(Canvas canvas) {
    const gold = Color(0xFFD4A72A);
    const light = Color(0xFFFFE9A3);
    final wing = Path()
      ..moveTo(30, 54)
      ..quadraticBezierTo(8, 46, 2, 18)
      ..quadraticBezierTo(14, 30, 24, 30)
      ..quadraticBezierTo(10, 20, 10, 6)
      ..quadraticBezierTo(24, 24, 34, 32)
      ..quadraticBezierTo(24, 40, 36, 44)
      ..close();
    void drawWing() {
      canvas.drawPath(
        wing,
        Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, gold, Color(0xFF7A5A08)]).createShader(wing.getBounds()),
      );
      canvas.drawPath(wing, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..strokeJoin = StrokeJoin.round..color = const Color(0xFF3A2A04));
    }

    canvas.save();
    canvas.translate(0, open ? -4.0 * (open ? 1.0 : 0.0) : 0);
    drawWing();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    drawWing();
    canvas.restore();

    _shackle(canvas, const Color(0xFFB8B8BA), width: 7);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(24, 48, 52, 42), const Radius.circular(5));
    canvas.drawRRect(
      body,
      Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF5A5A5E), Color(0xFF2A2A2C), Color(0xFF111112)]).createShader(body.outerRect),
    );
    canvas.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..color = gold);
    canvas.drawRRect(body.deflate(4), Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = light.withValues(alpha: .5));
    for (final p in const [Offset(30, 54), Offset(70, 54), Offset(30, 84), Offset(70, 84)]) {
      canvas.drawCircle(p, 2.2, Paint()..color = gold);
      canvas.drawCircle(p + const Offset(-.6, -.6), .8, Paint()..color = light);
    }
    canvas.drawCircle(const Offset(50, 66), 8.5, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = gold);
    _keyhole(canvas, const Offset(50, 64), const Color(0xFF050505), scale: .9);
  }

  // Solar Flare: a star with a fiery corona and a keyhole of light.
  void _paintSun(Canvas canvas) {
    const core = Color(0xFFFFF3C4);
    const hot = Color(0xFFFFB300);
    const deep = Color(0xFFE65100);
    const c = Offset(50, 62);
    canvas.drawCircle(c, 44, Paint()..shader = const RadialGradient(colors: [Color(0x66FFB300), Color(0x00FFB300)]).createShader(Rect.fromCircle(center: c, radius: 44)));
    // flare rays around the star
    final ray = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 3.2..color = hot;
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6 + (open ? .26 * (open ? 1.0 : 0.0) : 0);
      final len = i.isEven ? 11.0 : 7.0;
      canvas.drawLine(c + Offset(cos(a), sin(a)) * 27, c + Offset(cos(a), sin(a)) * (27 + len), ray);
    }
    _shackle(canvas, const Color(0xFFFFD54F), width: 6, glow: const Color(0x66FFB300));
    canvas.drawCircle(c, 26, Paint()..shader = const RadialGradient(center: Alignment(-.3, -.4), colors: [core, hot, deep, Color(0xFF5A1500)], stops: [0, .35, .75, 1]).createShader(Rect.fromCircle(center: c, radius: 26)));
    canvas.drawCircle(c, 26, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = core.withValues(alpha: .9));
    // a sunspot and a granule
    canvas.drawCircle(const Offset(61, 70), 3.2, Paint()..color = const Color(0xFF3A0C00).withValues(alpha: .6));
    canvas.drawCircle(const Offset(40, 52), 2.2, Paint()..color = core.withValues(alpha: .7));
    _keyhole(canvas, const Offset(50, 58), const Color(0xFF2A0800), scale: .85);
  }

  // Abyssal: a glowing jellyfish bell with trailing tentacles.
  void _paintJelly(Canvas canvas) {
    const teal = Color(0xFF1DE9C6);
    const pale = Color(0xFFB2FFF2);
    // tentacles
    final tent = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 2.2;
    for (var i = 0; i < 5; i++) {
      final x = 32.0 + i * 9;
      final sway = open ? 5.0 * (open ? 1.0 : 0.0) : 0.0;
      tent.color = teal.withValues(alpha: .35 + .1 * (i % 2));
      canvas.drawPath(
        Path()
          ..moveTo(x, 78)
          ..cubicTo(x - 6 + sway, 86, x + 6 - sway, 92, x - 2 + sway, 99),
        tent,
      );
    }
    _shackle(canvas, pale, width: 5.5, glow: const Color(0x881DE9C6));
    final bell = Path()
      ..moveTo(20, 80)
      ..cubicTo(14, 40, 86, 40, 80, 80)
      ..quadraticBezierTo(70, 74, 62, 80)
      ..quadraticBezierTo(50, 72, 38, 80)
      ..quadraticBezierTo(30, 74, 20, 80)
      ..close();
    canvas.drawPath(bell, Paint()..color = teal.withValues(alpha: .4)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5));
    canvas.drawPath(
      bell,
      Paint()..shader = const RadialGradient(center: Alignment(-.3, -.6), radius: 1.1, colors: [Color(0xCC9BFFF0), Color(0xAA1DC9B8), Color(0xCC053A52)]).createShader(bell.getBounds()),
    );
    canvas.drawPath(bell, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..strokeJoin = StrokeJoin.round..color = pale);
    // inner glow rings
    canvas.drawPath(Path()..moveTo(30, 66)..quadraticBezierTo(50, 52, 70, 66), Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = pale.withValues(alpha: .6));
    canvas.drawCircle(const Offset(36, 56), 2.2, Paint()..color = Colors.white.withValues(alpha: .7));
    _keyhole(canvas, const Offset(50, 60), const Color(0xFF021F2A), scale: .8);
  }

  // Sakura: red lacquer padlock engraved with a cherry blossom, one petal drifting away.
  void _paintBlossom(Canvas canvas) {
    const pink = Color(0xFFFFC2D4);
    _shackle(canvas, pink, width: 6);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(22, 46, 56, 44), const Radius.circular(14));
    canvas.drawRRect(
      body,
      Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE35577), Color(0xFFA32346), Color(0xFF560F26)]).createShader(body.outerRect),
    );
    canvas.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = pink.withValues(alpha: .9));
    // lacquer sheen
    canvas.drawPath(Path()..moveTo(30, 54)..quadraticBezierTo(50, 48, 70, 54), Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..color = Colors.white.withValues(alpha: .28));
    // blossom
    const c = Offset(50, 69);
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5 - pi / 2 + (open ? .3 * (open ? 1.0 : 0.0) : 0);
      final tip = c + Offset(cos(a), sin(a)) * 16;
      final l = c + Offset(cos(a - .6), sin(a - .6)) * 10;
      final r = c + Offset(cos(a + .6), sin(a + .6)) * 10;
      canvas.drawPath(
        Path()..moveTo(c.dx, c.dy)..quadraticBezierTo(l.dx, l.dy, tip.dx, tip.dy)..quadraticBezierTo(r.dx, r.dy, c.dx, c.dy)..close(),
        Paint()..color = pink.withValues(alpha: .92),
      );
    }
    _keyhole(canvas, c + const Offset(0, -2), const Color(0xFF3A0A1C), scale: .6);
    // drifting petal
    canvas.save();
    canvas.translate(84, 22 + (open ? 10.0 * (open ? 1.0 : 0.0) : 0));
    canvas.rotate(.7);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 10, height: 5.5), Paint()..color = pink.withValues(alpha: .85));
    canvas.restore();
  }

  // Aurora: a dark shield with three ribbons of northern light and a few stars.
  void _paintAurora(Canvas canvas) {
    const green = Color(0xFF69F0AE);
    const cyan = Color(0xFF18FFFF);
    _shackle(canvas, const Color(0xFFB9F6CA), width: 6, glow: const Color(0x6600E676));
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(22, 46, 56, 44), const Radius.circular(16));
    canvas.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B3A44), Color(0xFF04141E)]).createShader(body.outerRect));
    canvas.save();
    canvas.clipRRect(body);
    for (var i = 0; i < 3; i++) {
      final c = [green, cyan, const Color(0xFFB388FF)][i];
      final y = 56.0 + i * 8;
      canvas.drawPath(
        Path()..moveTo(18, y)..cubicTo(34, y - 12, 44, y + 12, 58, y - 4)..cubicTo(66, y - 12, 76, y - 2, 84, y - 8),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 4.5..strokeCap = StrokeCap.round..color = c.withValues(alpha: .55)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5),
      );
    }
    canvas.restore();
    canvas.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = green);
    for (final p in const [Offset(32, 53), Offset(66, 52), Offset(72, 62)]) {
      canvas.drawCircle(p, 1, Paint()..color = Colors.white.withValues(alpha: .85));
    }
    _keyhole(canvas, const Offset(50, 64), const Color(0xFF021014), scale: .9);
  }

  // Sapphire: an emerald-cut gem with step facets.
  void _paintGem(Canvas canvas) {
    const pale = Color(0xFFBBDEFB);
    _shackle(canvas, pale, width: 6);
    final gem = Path()
      ..moveTo(32, 46)..lineTo(68, 46)..lineTo(80, 58)..lineTo(80, 80)..lineTo(68, 92)..lineTo(32, 92)..lineTo(20, 80)..lineTo(20, 58)..close();
    canvas.drawPath(gem, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4F8DF5), Color(0xFF1A4BB5), Color(0xFF081C5C)]).createShader(gem.getBounds()));
    final inner = Path()
      ..moveTo(36, 54)..lineTo(64, 54)..lineTo(72, 62)..lineTo(72, 76)..lineTo(64, 84)..lineTo(36, 84)..lineTo(28, 76)..lineTo(28, 62)..close();
    canvas.drawPath(inner, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = pale.withValues(alpha: .6));
    canvas.drawPath(
      Path()..moveTo(32, 46)..lineTo(36, 54)..moveTo(68, 46)..lineTo(64, 54)..moveTo(80, 58)..lineTo(72, 62)..moveTo(80, 80)..lineTo(72, 76)..moveTo(68, 92)..lineTo(64, 84)..moveTo(32, 92)..lineTo(36, 84)..moveTo(20, 80)..lineTo(28, 76)..moveTo(20, 58)..lineTo(28, 62),
      Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = pale.withValues(alpha: .45),
    );
    canvas.drawPath(gem, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeJoin = StrokeJoin.round..color = pale);
    canvas.drawPath(Path()..moveTo(26, 50)..lineTo(44, 50)..lineTo(30, 66)..close(), Paint()..color = Colors.white.withValues(alpha: .22));
    _keyhole(canvas, const Offset(50, 63), const Color(0xFF04123A), scale: .85);
  }

  // Amber: a drop of fossil resin with a padlock-shaped shadow trapped inside.
  void _paintResin(Canvas canvas) {
    const honey = Color(0xFFFFC04D);
    final drop = Path()
      ..moveTo(50, 10)
      ..cubicTo(60, 30, 84, 50, 80, 72)
      ..cubicTo(77, 92, 23, 92, 20, 72)
      ..cubicTo(16, 50, 40, 30, 50, 10)
      ..close();
    canvas.save();
    canvas.translate(0, open ? -4.0 : 0.0);
    canvas.drawPath(drop, Paint()..color = const Color(0x66FFB300)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4));
    canvas.drawPath(drop, Paint()..shader = const RadialGradient(center: Alignment(-.3, -.5), radius: 1.1, colors: [Color(0xFFFFE082), Color(0xFFE58A00), Color(0xFF6B3500)]).createShader(drop.getBounds()));
    canvas.drawPath(drop, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeJoin = StrokeJoin.round..color = honey);
    final dark = Paint()..color = const Color(0xFF3A1A00).withValues(alpha: .6);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(38, 60, 24, 20), const Radius.circular(4)), dark);
    canvas.drawPath(
      Path()..moveTo(43, 60)..lineTo(43, 52)..arcToPoint(const Offset(57, 52), radius: const Radius.circular(7))..lineTo(57, 60),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 3.4..strokeCap = StrokeCap.round..color = const Color(0xFF3A1A00).withValues(alpha: .6),
    );
    if (keyhole) canvas.drawCircle(const Offset(50, 69), 2.2, Paint()..color = const Color(0xFFFFE082));
    for (final p in const [Offset(34, 62), Offset(66, 54), Offset(58, 84)]) {
      canvas.drawCircle(p, 2, Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = Colors.white.withValues(alpha: .6));
    }
    canvas.drawPath(Path()..moveTo(32, 54)..quadraticBezierTo(36, 40, 46, 30), Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..color = Colors.white.withValues(alpha: .32));
    canvas.restore();
  }

  // Onyx: a polished black disc, a thin white ring, nothing else.
  void _paintOnyx(Canvas canvas) {
    _shackle(canvas, const Color(0xFFE6E6E8), width: 4);
    const c = Offset(50, 66);
    canvas.drawCircle(c, 27, Paint()..shader = const RadialGradient(center: Alignment(-.4, -.5), radius: 1.1, colors: [Color(0xFF4A4A50), Color(0xFF111113), Color(0xFF000000)]).createShader(Rect.fromCircle(center: c, radius: 27)));
    canvas.drawCircle(c, 27, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = Colors.white.withValues(alpha: .85));
    canvas.drawArc(Rect.fromCircle(center: c, radius: 21), pi * 1.1, pi * .5, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..color = Colors.white.withValues(alpha: .35));
    _keyhole(canvas, c + const Offset(0, -6), const Color(0xFFF2F2F4), scale: .8);
  }

  // Pearl: a lustrous sphere with an iridescent sheen.
  void _paintPearl(Canvas canvas) {
    _shackle(canvas, const Color(0xFFF5E1EC), width: 5);
    const c = Offset(50, 66);
    canvas.drawCircle(c, 29, Paint()..color = const Color(0x55FFC2DD)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4));
    canvas.drawCircle(c, 27, Paint()..shader = const RadialGradient(center: Alignment(-.35, -.45), radius: 1.05, colors: [Color(0xFFFFFFFF), Color(0xFFF6DDE9), Color(0xFFBBA3C2), Color(0xFF7D6B8C)], stops: [0, .35, .75, 1]).createShader(Rect.fromCircle(center: c, radius: 27)));
    canvas.drawCircle(c, 27, Paint()..shader = const SweepGradient(colors: [Color(0x44A7FFEB), Color(0x44FFB3D1), Color(0x44D1C4E9), Color(0x44FFE9A3), Color(0x44A7FFEB)]).createShader(Rect.fromCircle(center: c, radius: 27)));
    canvas.drawOval(Rect.fromCenter(center: const Offset(40, 54), width: 14, height: 8), Paint()..color = Colors.white.withValues(alpha: .7));
    _keyhole(canvas, c + const Offset(0, -4), const Color(0xFF5A4660), scale: .8);
  }

  // Ivory: an ornate cream plaque in a gold frame, with scrolled corners.
  void _paintIvory(Canvas canvas) {
    const gold = Color(0xFFE6C068);
    _shackle(canvas, gold, width: 6);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(22, 46, 56, 44), const Radius.circular(6));
    canvas.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF8E1), Color(0xFFEBD8A8), Color(0xFFC9A862)]).createShader(body.outerRect));
    canvas.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..color = gold);
    canvas.drawRRect(body.deflate(4), Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = const Color(0xFF9C7A2C));
    final scroll = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..strokeCap = StrokeCap.round..color = const Color(0xFF9C7A2C);
    for (final (corner, dx, dy) in const [(Offset(27, 51), 1.0, 1.0), (Offset(73, 51), -1.0, 1.0), (Offset(27, 85), 1.0, -1.0), (Offset(73, 85), -1.0, -1.0)]) {
      canvas.drawPath(Path()..moveTo(corner.dx + dx * 9, corner.dy)..quadraticBezierTo(corner.dx, corner.dy, corner.dx, corner.dy + dy * 9), scroll);
    }
    _keyhole(canvas, const Offset(50, 64), const Color(0xFF4A3510), scale: .95);
  }

  // Neon: a padlock made of glowing tubes.
  void _paintNeon(Canvas canvas) {
    const pink = Color(0xFFFF2D95);
    const cyan = Color(0xFF00E5FF);
    void tube(Path path, Color color, double width) {
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = width + 5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = color.withValues(alpha: .45)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3));
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = width..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = color);
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = width * .35..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = Colors.white.withValues(alpha: .9));
    }

    final lift = open ? -7.0 : 0.0;
    tube(Path()..moveTo(35, 50 + lift)..lineTo(35, 34 + lift)..cubicTo(35, 10 + lift, 65, 10 + lift, 65, 34 + lift)..lineTo(65, open ? 40 + lift : 50), cyan, 4.5);
    tube(Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(22, 48, 56, 42), const Radius.circular(6))), pink, 4.5);
    if (keyhole) {
      tube(Path()..addOval(Rect.fromCircle(center: const Offset(50, 64), radius: 4.5)), cyan, 2.6);
      tube(Path()..moveTo(50, 69)..lineTo(50, 79), cyan, 2.6);
    }
  }

  // Void: a black hole with a tilted, glowing accretion disc; the keyhole is the event horizon.
  void _paintVoid(Canvas canvas) {
    const green = Color(0xFF39FF14);
    const c = Offset(50, 66);
    _shackle(canvas, const Color(0xFF9AA09A), width: 5);
    canvas.drawCircle(c, 33, Paint()..color = green.withValues(alpha: .25)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-.35 + (open ? .5 : 0));
    final disc = Rect.fromCenter(center: Offset.zero, width: 72, height: 18);
    canvas.drawOval(disc, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = green.withValues(alpha: .4)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3));
    canvas.drawOval(disc, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = const Color(0xFFCCFFC2));
    canvas.restore();
    canvas.drawCircle(c, 22, Paint()..color = Colors.black);
    canvas.drawCircle(c, 22, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = green);
    canvas.drawArc(Rect.fromCircle(center: c, radius: 26), pi * 1.2, pi * .6, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..strokeCap = StrokeCap.round..color = Colors.white.withValues(alpha: .7));
    _keyhole(canvas, c + const Offset(0, -6), green, scale: .75);
  }

  // Forge: an iron anvil with a molten keyhole.
  void _paintAnvil(Canvas canvas) {
    const orange = Color(0xFFFF6D00);
    _shackle(canvas, const Color(0xFF9A8F8A), width: 6.5);
    final anvil = Path()
      ..moveTo(14, 56)..lineTo(78, 56)..quadraticBezierTo(90, 56, 92, 64)..lineTo(70, 66)..lineTo(66, 72)..lineTo(70, 88)..lineTo(78, 92)..lineTo(24, 92)..lineTo(32, 88)..lineTo(36, 72)..lineTo(32, 66)..lineTo(14, 64)..close();
    canvas.drawPath(anvil, Paint()..color = orange.withValues(alpha: .35)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4));
    canvas.drawPath(anvil, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A7F7A), Color(0xFF3E3430), Color(0xFF1A1411)]).createShader(anvil.getBounds()));
    canvas.drawPath(anvil, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeJoin = StrokeJoin.round..color = const Color(0xFFD7C2B8));
    canvas.drawLine(const Offset(18, 59), const Offset(76, 59), Paint()..strokeWidth = 1.6..color = Colors.white.withValues(alpha: .4));
    // glowing metal on the face
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 57), width: 26, height: 5), Paint()..color = orange.withValues(alpha: .9)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2));
    _keyhole(canvas, const Offset(51, 70), const Color(0xFFFFB300), scale: .55);
  }

  // Hermetic: a circle of arts with a hexagram and a glowing center.
  void _paintCircle(Canvas canvas) {
    const green = Color(0xFF38D39A);
    const violet = Color(0xFFB388FF);
    _shackle(canvas, green.withValues(alpha: .9), width: 5);
    const c = Offset(50, 68);
    canvas.drawCircle(c, 29, Paint()..color = green.withValues(alpha: .25)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5));
    canvas.drawCircle(c, 26, Paint()..shader = const RadialGradient(colors: [Color(0xFF16423A), Color(0xFF081A1E)]).createShader(Rect.fromCircle(center: c, radius: 26)));
    canvas.drawCircle(c, 26, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = green);
    canvas.drawCircle(c, 21, Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = violet.withValues(alpha: .8));
    for (var k = 0; k < 2; k++) {
      final path = Path();
      for (var i = 0; i < 3; i++) {
        final a = k * pi / 3 + i * 2 * pi / 3 - pi / 2 + (open ? .5 : 0);
        final p = c + Offset(cos(a), sin(a)) * 19;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = (k == 0 ? green : violet).withValues(alpha: .9));
    }
    _keyhole(canvas, c + const Offset(0, -5), const Color(0xFFE0FFF2), scale: .65);
  }

  // Eclipse: a black moon with a corona and a diamond ring glint.
  void _paintMoon(Canvas canvas) {
    const cyan = Color(0xFF9AF5FF);
    _shackle(canvas, const Color(0xFF7FD8E8), width: 5.5, glow: const Color(0x6629D9FF));
    const c = Offset(50, 66);
    final ray = Paint()..strokeWidth = 1.4..strokeCap = StrokeCap.round;
    for (var i = 0; i < 24; i++) {
      final a = i * 2 * pi / 24;
      final len = i.isEven ? 11.0 : 6.0;
      ray.shader = ui.Gradient.linear(c + Offset(cos(a), sin(a)) * 24, c + Offset(cos(a), sin(a)) * (24 + len), [cyan.withValues(alpha: .8), cyan.withValues(alpha: 0)]);
      canvas.drawLine(c + Offset(cos(a), sin(a)) * 24, c + Offset(cos(a), sin(a)) * (24 + len), ray);
    }
    canvas.drawCircle(c, 25, Paint()..color = const Color(0x6629D9FF)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4));
    canvas.drawCircle(c, 23, Paint()..color = const Color(0xFF000206));
    canvas.drawCircle(c, 23, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = cyan);
    final g = c + Offset(cos(-pi * (open ? .5 : .8)), sin(-pi * (open ? .5 : .8))) * 23;
    canvas.drawCircle(g, 9, Paint()..shader = ui.Gradient.radial(g, 9, [Colors.white.withValues(alpha: .8), cyan.withValues(alpha: .25), cyan.withValues(alpha: 0)], const [0, .35, 1]));
    canvas.drawCircle(g, 1.8, Paint()..color = Colors.white);
    _keyhole(canvas, c + const Offset(0, -5), cyan, scale: .7);
  }

  // Crimson: a faceted blood-ruby heart.
  void _paintHeart(Canvas canvas) {
    const red = Color(0xFFFF1744);
    _shackle(canvas, const Color(0xFFE08A9A), width: 5.5);
    final heart = Path()
      ..moveTo(50, 92)
      ..cubicTo(8, 66, 12, 38, 32, 40)
      ..cubicTo(42, 41, 48, 48, 50, 54)
      ..cubicTo(52, 48, 58, 41, 68, 40)
      ..cubicTo(88, 38, 92, 66, 50, 92)
      ..close();
    canvas.drawPath(heart, Paint()..color = red.withValues(alpha: .4)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4));
    canvas.drawPath(heart, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF4D6D), Color(0xFFB0102E), Color(0xFF4A0414)]).createShader(heart.getBounds()));
    canvas.drawPath(Path()..moveTo(50, 54)..lineTo(34, 62)..lineTo(50, 92)..moveTo(50, 54)..lineTo(66, 62)..lineTo(50, 92)..moveTo(34, 62)..lineTo(24, 50)..moveTo(66, 62)..lineTo(76, 50), Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = Colors.white.withValues(alpha: .3));
    canvas.drawPath(heart, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeJoin = StrokeJoin.round..color = const Color(0xFFFFB3C0));
    canvas.drawPath(Path()..moveTo(24, 50)..quadraticBezierTo(28, 44, 36, 44), Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..strokeCap = StrokeCap.round..color = Colors.white.withValues(alpha: .6));
    _keyhole(canvas, const Offset(50, 62), const Color(0xFF2A0610), scale: .85);
  }

  // Emerald: a hexagonal prism with a vein of gold.
  void _paintPrism(Canvas canvas) {
    const gold = Color(0xFFFFD54F);
    const pale = Color(0xFFB9F6CA);
    _shackle(canvas, gold, width: 5.5);
    final prism = Path()..moveTo(50, 44)..lineTo(78, 58)..lineTo(78, 82)..lineTo(50, 96)..lineTo(22, 82)..lineTo(22, 58)..close();
    canvas.drawPath(prism, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4EE0A0), Color(0xFF138A5E), Color(0xFF04301F)]).createShader(prism.getBounds()));
    canvas.drawPath(Path()..moveTo(50, 44)..lineTo(50, 96)..moveTo(22, 58)..lineTo(50, 70)..lineTo(78, 58), Paint()..style = PaintingStyle.stroke..strokeWidth = .9..color = pale.withValues(alpha: .5));
    canvas.drawPath(Path()..moveTo(50, 44)..lineTo(22, 58)..lineTo(50, 70)..close(), Paint()..color = Colors.white.withValues(alpha: .18));
    canvas.drawPath(Path()..moveTo(26, 86)..cubicTo(36, 78, 44, 88, 54, 78)..cubicTo(62, 70, 70, 80, 76, 72), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..strokeCap = StrokeCap.round..color = gold);
    canvas.drawPath(prism, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeJoin = StrokeJoin.round..color = pale);
    _keyhole(canvas, const Offset(50, 63), const Color(0xFF03281A), scale: .8);
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
  // Nox Terroris: a sealed ossuary mask with a vertical, predatory eye.
  void _paintNoxTerroris(Canvas canvas) {
    const bone = Color(0xFFDCE8B0);
    const acid = Color(0xFFB7D86B);
    _shackle(canvas, const Color(0xFF657A38), width: 5.5, glow: const Color(0x5539FF14));
    final mask = Path()
      ..moveTo(50, 20)..lineTo(76, 32)..lineTo(82, 55)..lineTo(68, 78)
      ..lineTo(50, 91)..lineTo(32, 78)..lineTo(18, 55)..lineTo(24, 32)..close();
    canvas.drawPath(mask, Paint()..color = acid.withValues(alpha: .16)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4));
    canvas.drawPath(mask, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF343A2C), Color(0xFF151A15), Color(0xFF050706)]).createShader(mask.getBounds()));
    canvas.drawPath(mask, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeJoin = StrokeJoin.round..color = bone);
    final crown = Path()
      ..moveTo(31, 31)..lineTo(25, 9)..lineTo(42, 25)
      ..moveTo(50, 25)..lineTo(50, 4)..lineTo(59, 24)
      ..moveTo(69, 31)..lineTo(78, 11)..lineTo(63, 25);
    canvas.drawPath(crown, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = bone.withValues(alpha: .88));
    final socket = Path()..moveTo(27, 43)..quadraticBezierTo(39, 34, 47, 44)..quadraticBezierTo(38, 53, 27, 43)..close();
    canvas.drawPath(socket, Paint()..color = const Color(0xFF010302));
    canvas.drawOval(Rect.fromCenter(center: const Offset(38, 44), width: 3.8, height: 13), Paint()..color = acid);
    canvas.drawCircle(const Offset(38, 44), 6, Paint()..color = acid.withValues(alpha: .12)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3));
    final deadSocket = Path()..moveTo(55, 43)..quadraticBezierTo(66, 36, 74, 45)..quadraticBezierTo(65, 53, 55, 43)..close();
    canvas.drawPath(deadSocket, Paint()..color = const Color(0xFF010302));
    canvas.drawLine(const Offset(61, 43), const Offset(67, 47), Paint()..strokeWidth = 1.2..color = bone.withValues(alpha: .55));
    final jaw = Path()..moveTo(35, 64)..lineTo(44, 69)..lineTo(50, 65)..lineTo(56, 69)..lineTo(65, 64);
    canvas.drawPath(jaw, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..color = bone.withValues(alpha: .78));
    canvas.drawPath(Path()..moveTo(40, 67)..lineTo(43, 76)..lineTo(47, 70)..moveTo(60, 67)..lineTo(57, 76)..lineTo(53, 70),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeJoin = StrokeJoin.round..color = bone);
    _keyhole(canvas, const Offset(50, 57), acid, scale: .52);
    if (open) {
      canvas.drawLine(const Offset(50, 78), const Offset(50, 85), Paint()..strokeWidth = 2.2..strokeCap = StrokeCap.round..color = acid);
    }
  }


}