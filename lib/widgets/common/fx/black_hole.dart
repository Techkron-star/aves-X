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
    final r = size.shortestSide / 2;

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
