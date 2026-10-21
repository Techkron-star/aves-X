import 'package:flutter/material.dart';

// Translucent ruby bat mark: the "bat" of the former Bat-Glass, drawn without a padlock.
// Used by the About screen, the Fail-Safe comic bubble and the lockdown screen.
// The padlock itself is drawn by `_PadlockPainter` in `lock_animation.dart`.
class AppMark extends StatelessWidget {
  final double size;
  final bool mirrored;

  const AppMark({super.key, this.size = 28, this.mirrored = false});

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: mirrored,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: const AppMarkPainter()),
      ),
    );
  }
}

// Ruby bat with a keyhole (static: no open/animate state).
class AppMarkPainter extends CustomPainter {
  const AppMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s);
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
  }

  @override
  bool shouldRepaint(covariant AppMarkPainter old) => false;
}
