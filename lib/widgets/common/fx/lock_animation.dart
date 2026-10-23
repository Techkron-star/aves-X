import 'dart:math';

import 'package:aves/model/settings/settings.dart';
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

class LockedBadgeState extends State<LockedBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _unlockController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  bool get _playing => widget.fresh && settings.animate && !settings.performanceMode;
  bool _unlocking = false;

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
    if (_unlocking) return;
    _unlocking = true;
    _unlockController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _unlocking = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // the lock art follows the active Nebula theme: only the default Aves theme
    // keeps the neutral metal look, every Nebula theme tints it with its crystal
    final nebulaTheme = settings.nebulaTheme;
    final bat = nebulaTheme == NebulaTheme.nosferatuGlass;
    final themed = nebulaTheme != NebulaTheme.aves;
    final tokens = themed ? Theme.of(context).nebula : null;
    final chainColor = bat
        ? const Color(0xFFFF6A80)
        : (tokens?.securityCrystalBody.first ?? const Color(0xFFE0E0E0));
    final chainFillEnd = bat
        ? const Color(0xFF8E0F26)
        : (tokens?.securityCrystalBody[1] ?? const Color(0xFF6E6E6E));
    final chainStroke = bat
        ? const Color(0xCCFFB3BF)
        : (tokens?.securityCrystalEdge ?? const Color(0xFF3A3A3A));
    final padlockBody = bat
        ? const [Color(0xFFFF6A80), Color(0xFF8E0F26)]
        : (tokens != null
            ? [tokens.securityCrystalBody.first, tokens.securityCrystalBody[1]]
            : const [Color(0xFFF2C94C), Color(0xFFB8860B)]);
    final padlockShackle = bat
        ? const Color(0xFFFFB3BF)
        : (tokens?.securityCrystalHighlight ?? const Color(0xFFB8B8B8));
    final padlockStroke = bat
        ? const Color(0xCCFFB3BF)
        : (tokens?.securityCrystalEdge ?? const Color(0xFF5C4300));
    final padlockKeyhole = bat
        ? const Color(0xFF1A0308)
        : (tokens?.securityBubbleSurface ?? const Color(0xFF3B2A00));
    final padlockKey = bat
        ? const Color(0xFFFFB3BF)
        : (tokens?.securityBubbleInk ?? const Color(0xFFB8B8B8));
    final shimmerColor = bat
        ? const Color(0xFFFFB3BF)
        : (tokens?.securityAccent ?? const Color(0xFFFFFFFF));

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
            final unlockProgress = Curves.easeOut.transform(_unlockController.value);
            final isUnlocking = _unlockController.value > 0 && _unlockController.value < 1;
            return Stack(
              alignment: Alignment.center,
              children: [
                // the chains stay in place once locked (not in performance mode: padlock only)
                if (!settings.performanceMode && !isUnlocking)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ChainsPainter(
                        progress: chains,
                        scale: scale,
                        fillStart: chainColor,
                        fillEnd: chainFillEnd,
                        strokeColor: chainStroke,
                      ),
                    ),
                  ),
                Transform.translate(
                  offset: Offset(shake, -(1 - fall) * box * .9),
                  child: SizedBox(
                    width: lockSize,
                    height: lockSize,
                    child: _Shimmer(
                      enabled: bat && settings.animate,
                      shimmerColor: shimmerColor,
                      child: CustomPaint(
                        painter: _PadlockPainter(
                          bat: bat,
                          open: isUnlocking,
                          openProgress: _unlockController.value,
                          bodyGradient: padlockBody,
                          shackleColor: padlockShackle,
                          strokeColor: padlockStroke,
                          keyholeColor: padlockKeyhole,
                          keyColor: padlockKey,
                          shimmerColor: shimmerColor,
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
  final Color shimmerColor;
  final Widget child;

  const _Shimmer({required this.enabled, required this.shimmerColor, required this.child});

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
            colors: [const Color(0x00FFFFFF), shimmerColor.withValues(alpha: .7 * e), const Color(0x00FFFFFF)],
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
  final Color fillStart, fillEnd, strokeColor;

  const _ChainsPainter({
    required this.progress,
    required this.scale,
    required this.fillStart,
    required this.fillEnd,
    required this.strokeColor,
  });

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
          ..shader = LinearGradient(colors: [fillStart, fillEnd]).createShader(rect.outerRect);
        canvas.drawRRect(rect, fill);
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4 * scale
            ..color = strokeColor,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChainsPainter old) =>
      old.progress != progress || old.scale != scale || old.fillStart != fillStart || old.fillEnd != fillEnd || old.strokeColor != strokeColor;
}

class _PadlockPainter extends CustomPainter {
  final bool bat;
  final bool open;
  final bool keyhole;
  final double openProgress;
  final List<Color> bodyGradient;
  final Color shackleColor;
  final Color strokeColor;
  final Color keyholeColor;
  final Color keyColor;
  final Color shimmerColor;

  const _PadlockPainter({
    required this.bat,
    required this.open,
    this.keyhole = true,
    this.openProgress = 0.0,
    required this.bodyGradient,
    required this.shackleColor,
    required this.strokeColor,
    required this.keyholeColor,
    required this.keyColor,
    required this.shimmerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s);
    if (bat) {
      _paintBat(canvas);
    } else {
      _paintPadlock(canvas);
    }
  }

  void _paintPadlock(Canvas canvas) {
    final shackle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = shackleColor;
    final shacklePath = Path()
      ..moveTo(32, 46)
      ..lineTo(32, 32)
      ..arcToPoint(const Offset(68, 32), radius: const Radius.circular(18), clockwise: true)
      ..lineTo(68, open ? 30 : 46);
    canvas.drawPath(shacklePath, shackle);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(22, 44, 56, 44), const Radius.circular(9));
    canvas.drawRRect(body, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: bodyGradient).createShader(body.outerRect));
    canvas.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = strokeColor);
    canvas.drawCircle(const Offset(50, 62), 6, Paint()..color = keyholeColor);
    canvas.drawRect(const Rect.fromLTWH(47.5, 62, 5, 14), Paint()..color = keyholeColor);
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
    final hole = Paint()..color = keyholeColor;
    canvas.drawCircle(const Offset(50, 50), 6, hole);
    canvas.drawPath(Path()..moveTo(46.5, 54)..lineTo(53.5, 54)..lineTo(55.5, 70)..lineTo(44.5, 70)..close(), hole);
    if (open) {
      canvas.drawLine(const Offset(50, 40), const Offset(50, 30), Paint()..color = keyColor..strokeWidth = 3..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _PadlockPainter old) =>
      old.bat != bat || old.open != open || old.keyhole != keyhole || old.openProgress != openProgress;
}