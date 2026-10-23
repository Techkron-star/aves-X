import 'dart:math';

import 'package:material_ui/material_ui.dart';

// Black Hole look: an event horizon (pure black) ringed by a glowing accretion disk
// that slowly spins, with the light bent over the top of the hole (gravitational lensing).
class BlackHoleDisc extends StatefulWidget {
  final double size;
  final bool animate;

  const BlackHoleDisc({super.key, this.size = 56, this.animate = true});

  @override
  State<BlackHoleDisc> createState() => _BlackHoleDiscState();
}

class _BlackHoleDiscState extends State<BlackHoleDisc> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 9));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(BlackHoleDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(painter: _BlackHolePainter(_controller.value)),
      ),
    );
  }
}

class _BlackHolePainter extends CustomPainter {
  final double t;

  const _BlackHolePainter(this.t);

  static const _disk = [
    Color(0xFFFF8A1F),
    Color(0xFFFFE9B0),
    Color(0xFFB04BFF),
    Color(0xFFC4122F),
    Color(0xFFFF8A1F),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final pulse = .5 + .5 * sin(t * 2 * pi);
    final r = size.shortestSide * .43;

    canvas.drawCircle(
      center,
      r * (1.02 + .045 * pulse),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            const Color(0x22FF7A18).withValues(alpha: .45 + .25 * pulse),
            const Color(0x00B04BFF),
            Colors.transparent,
          ],
          stops: const [.46, .70, .86, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.1)),
    );

    // Tilted accretion disc: a soft outer band plus a sharper inner lane.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.32);
    canvas.scale(1, .3);
    final ringRect = Rect.fromCircle(center: Offset.zero, radius: r * 1.02);
    canvas.drawCircle(
      Offset.zero,
      r * .72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * (.19 + .025 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .055)
        ..shader = SweepGradient(
          colors: _disk,
          stops: const [0, .19, .43, .72, 1],
          transform: GradientRotation(t * 2 * pi),
        ).createShader(ringRect),
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * .83),
      -.12 * pi + t * 2 * pi,
      1.28 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * .035
        ..color = const Color(0xFFFFE9B0).withValues(alpha: .42 + .3 * pulse),
    );
    canvas.restore();

    // Gravitationally lensed light forms a counter-rotating inner arc.
    canvas.drawCircle(
      center,
      r * .46,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * (.045 + .012 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .035)
        ..shader = SweepGradient(
          colors: _disk,
          transform: GradientRotation(-t * 2 * pi + pi),
        ).createShader(Rect.fromCircle(center: center, radius: r * .46)),
    );
    canvas.drawArc(
      Rect.fromCenter(center: center, width: r * 1.8, height: r * .56),
      .04 * pi,
      .92 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * .045
        ..color = const Color(0xFFFFF1CF).withValues(alpha: .28 + .3 * pulse),
    );

    // Hot fragments follow the disc and leave short luminous trails.
    for (var i = 0; i < 9; i++) {
      final angle = t * 2 * pi * (i.isEven ? 1 : -.68) + i * 2 * pi / 9;
      final orbit = r * (.79 + (i % 3) * .045);
      final point = Offset(
        center.dx + cos(angle) * orbit,
        center.dy + sin(angle) * orbit * .30,
      );
      final tangent = Offset(sin(angle), -cos(angle) * .30);
      final trail = Path()
        ..moveTo(point.dx - tangent.dx * r * .10, point.dy - tangent.dy * r * .10)
        ..lineTo(point.dx, point.dy);
      canvas.drawPath(
        trail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r * .022
          ..color = const Color(0xFFFF8A1F).withValues(alpha: .35 + .3 * pulse),
      );
      canvas.drawCircle(
        point,
        r * (.018 + (i % 3) * .004),
        Paint()
          ..color = i.isEven ? const Color(0xFFFFE9B0) : const Color(0xFFFF8A1F)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .025),
      );
    }

    canvas.drawCircle(center, r * .39, Paint()..color = Colors.black);
    canvas.drawCircle(
      center,
      r * (.395 + .004 * pulse),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 + pulse * .8
        ..color = Colors.white.withValues(alpha: .30 + pulse * .28),
    );
  }

  @override
  bool shouldRepaint(_BlackHolePainter oldDelegate) => oldDelegate.t != t;
}

/// A compact Black Hole mark for the trash destination. The recognizable bin
/// remains in the foreground, while the accretion disc animates behind it.
class BlackHoleIcon extends StatelessWidget {
  final Widget child;
  final double size;
  final bool animate;

  const BlackHoleIcon({
    super.key,
    required this.child,
    this.size = 30,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        BlackHoleDisc(size: size, animate: animate),
        SizedBox.square(
          dimension: size * .62,
          child: FittedBox(
            fit: BoxFit.contain,
            child: IconTheme.merge(
              data: const IconThemeData(color: Colors.white),
              child: child,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Subtle pendulum motion for the bin icon when Black Hole is not enabled.
/// Reduced-motion and performance preferences disable it entirely.
class TrashIconMotion extends StatefulWidget {
  final Widget child;
  final bool animate;

  const TrashIconMotion({super.key, required this.child, this.animate = true});

  @override
  State<TrashIconMotion> createState() => _TrashIconMotionState();
}

class _TrashIconMotionState extends State<TrashIconMotion> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant TrashIconMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      if (!widget.animate) return child!;
      final swing = sin(_controller.value * 2 * pi);
      return Transform.rotate(
        angle: swing * .035,
        child: Transform.scale(
          scale: 1 + swing * swing * .02,
          child: child,
        ),
      );
    },
  );
}
