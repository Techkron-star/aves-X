import 'dart:math';

import 'package:aves/model/settings/settings.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

// Badge shown over locked thumbnails, in place of a plain padlock icon.
// When the item was just locked (`fresh`), it plays a short animation over the thumbnail:
// two chains crossing in an X, then the padlock falling on the crossing.
// With "Bat glass": ruby chains and a translucent bat with a keyhole, with a shimmering light inside.
class LockedBadge extends StatefulWidget {
  final bool fresh;

  const LockedBadge({super.key, this.fresh = false});

  @override
  State<LockedBadge> createState() => _LockedBadgeState();
}

class _LockedBadgeState extends State<LockedBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  bool get _playing => widget.fresh && settings.animate;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bat = settings.batGlass;
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = min(constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0, constraints.maxHeight.isFinite ? constraints.maxHeight : 120.0);
        final lockSize = (box * .4).clamp(22.0, 64.0);
        final scale = box / 220;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final chains = Curves.easeOut.transform((t / 0.35).clamp(0, 1));
            final fall = Curves.bounceOut.transform(((t - 0.3) / 0.45).clamp(0, 1));
            final shake = t > 0.6 && t < 0.78 ? sin((t - 0.6) * 90) * 2 : 0.0;
            return Stack(
              alignment: Alignment.center,
              children: [
                // the chains stay in place once locked
                Positioned.fill(
                  child: CustomPaint(painter: _ChainsPainter(progress: chains, ruby: bat, scale: scale)),
                ),
                Transform.translate(
                  offset: Offset(shake, -(1 - fall) * box * .9),
                  child: SizedBox(
                    width: lockSize,
                    height: lockSize,
                    child: _Shimmer(
                      enabled: bat && settings.animate,
                      child: CustomPaint(painter: _PadlockPainter(bat: bat, open: false)),
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

// a soft light sweeping across the child, keeping its shape and details
class _Shimmer extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const _Shimmer({required this.enabled, required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _Shimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) _controller.repeat();
    if (!widget.enabled) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0x00FFFFFF), Color(0xB3FFB3BF), Color(0x00FFFFFF)],
          stops: const [.25, .5, .75],
          transform: _Slide(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
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
  final bool ruby;

  const _ChainsPainter({required this.progress, required this.ruby, required this.scale});

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
          ..shader = (ruby
                  ? const LinearGradient(colors: [Color(0xFFFF6A80), Color(0xFF8E0F26)])
                  : const LinearGradient(colors: [Color(0xFFE0E0E0), Color(0xFF6E6E6E)]))
              .createShader(rect.outerRect);
        canvas.drawRRect(rect, fill);
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4 * scale
            ..color = ruby ? const Color(0xCCFFB3BF) : const Color(0xFF3A3A3A),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChainsPainter old) => old.progress != progress || old.ruby != ruby || old.scale != scale;
}

class _PadlockPainter extends CustomPainter {
  final bool bat, open;

  const _PadlockPainter({required this.bat, required this.open});

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
    // keyhole, with a small key shape when unlocked
    final hole = Paint()..color = const Color(0xFF1A0308);
    canvas.drawCircle(const Offset(50, 50), 6, hole);
    canvas.drawPath(Path()..moveTo(46.5, 54)..lineTo(53.5, 54)..lineTo(55.5, 70)..lineTo(44.5, 70)..close(), hole);
    if (open) {
      canvas.drawLine(const Offset(50, 40), const Offset(50, 30), Paint()..color = const Color(0xFFFFB3BF)..strokeWidth = 3..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _PadlockPainter old) => old.bat != bat || old.open != open;
}
