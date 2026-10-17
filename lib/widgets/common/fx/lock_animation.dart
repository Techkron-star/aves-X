import 'dart:math';

import 'package:aves/model/settings/settings.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

// Short animation shown after locking an album or an item:
// two chains crossing in an X, then a padlock falling on the crossing.
// With "Bat glass": ruby chains, and a translucent bat with a keyhole instead of the padlock.
Future<void> showLockAnimation(BuildContext context, {required bool locked}) async {
  if (!settings.animate) return;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black38,
    transitionDuration: Duration.zero,
    useRootNavigator: true,
    pageBuilder: (context, _, __) => _LockAnimation(locked: locked, bat: settings.batGlass),
  );
}

class _LockAnimation extends StatefulWidget {
  final bool locked, bat;

  const _LockAnimation({required this.locked, required this.bat});

  @override
  State<_LockAnimation> createState() => _LockAnimationState();
}

class _LockAnimationState extends State<_LockAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150));

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
    // the "impact" of the padlock on the chains
    Future.delayed(const Duration(milliseconds: 620), () => HapticFeedback.heavyImpact());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 220,
          height: 220,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final chains = Curves.easeOut.transform((t / 0.35).clamp(0, 1));
              final fall = Curves.bounceOut.transform(((t - 0.3) / 0.45).clamp(0, 1));
              final fade = 1 - Curves.easeIn.transform(((t - 0.85) / 0.15).clamp(0, 1));
              final shake = t > 0.62 && t < 0.8 ? sin((t - 0.62) * 90) * 3 : 0.0;
              return Opacity(
                opacity: fade,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _ChainsPainter(progress: chains, ruby: widget.bat, broken: !widget.locked)),
                    ),
                    Transform.translate(
                      offset: Offset(shake, -(1 - fall) * 190),
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: CustomPaint(painter: _PadlockPainter(bat: widget.bat, open: !widget.locked)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChainsPainter extends CustomPainter {
  final double progress;
  final bool ruby, broken;

  const _ChainsPainter({required this.progress, required this.ruby, required this.broken});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final reach = size.width * 0.46 * progress;
    for (final angle in [pi / 4, -pi / 4]) {
      final dir = Offset(cos(angle), sin(angle));
      const linkLength = 16.0;
      final count = (reach * 2 / linkLength).floor();
      for (var i = 0; i < count; i++) {
        final d = -reach + (i + .5) * linkLength;
        canvas.save();
        canvas.translate(c.dx + dir.dx * d, c.dy + dir.dy * d);
        canvas.rotate(angle + (i.isEven ? 0 : pi / 2));
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: linkLength + 4, height: i.isEven ? 11 : 6),
          const Radius.circular(5),
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
            ..strokeWidth = 1.4
            ..color = ruby ? const Color(0xCCFFB3BF) : const Color(0xFF3A3A3A),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChainsPainter old) => old.progress != progress || old.ruby != ruby;
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
