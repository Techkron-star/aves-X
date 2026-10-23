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
    final r = size.shortestSide * .43;

    // faint halo around everything
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, const Color(0x33FF7A18), Colors.transparent],
          stops: const [.5, .78, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // accretion disk: a flattened, tilted ring whose colors turn around the hole
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.32);
    canvas.scale(1, .3);
    final ringRect = Rect.fromCircle(center: Offset.zero, radius: r * .9);
    canvas.drawCircle(
      Offset.zero,
      r * .68,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .24
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .05)
        ..shader = SweepGradient(colors: _disk, transform: GradientRotation(t * 2 * pi)).createShader(ringRect),
    );
    canvas.restore();

    // lensed light bent over the hole
    canvas.drawCircle(
      center,
      r * .43,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .06
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .03)
        ..shader = SweepGradient(colors: _disk, transform: GradientRotation(t * 2 * pi + pi)).createShader(Rect.fromCircle(center: center, radius: r * .43)),
    );

    // event horizon and its thin photon ring
    canvas.drawCircle(center, r * .39, Paint()..color = Colors.black);
    canvas.drawCircle(
      center,
      r * .395,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .45),
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
