import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:material_ui/material_ui.dart';

// Aves-X logo using the Nosferatu bat mark.
// Replaces the original PNG with a vector bat that follows the theme.
class AvesLogo extends StatelessWidget {
  const AvesLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.nebula;

    Widget child = CustomPaint(
      size: Size.square(size),
      painter: _AvesLogoPainter(tokens: tokens),
    );

    if (context.select<Settings, bool>((v) => v.themeColorMode == AvesThemeColorMode.monochrome)) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(theme.colorScheme.onSurface, BlendMode.modulate),
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.modulate),
          child: child,
        ),
      );
    }

    return Transform.flip(
      flipX: context.isRtl,
      child: CircleAvatar(
        backgroundColor: tokens.securityScrim,
        radius: size / 2,
        child: CircleAvatar(
          backgroundColor: tokens.securitySurface,
          radius: size / 2 - 2,
          child: child,
        ),
      ),
    );
  }
}

// Paints the Nosferatu bat mark using Nebula tokens.
class _AvesLogoPainter extends CustomPainter {
  const _AvesLogoPainter({required this.tokens});

  final NebulaTokens tokens;

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

    // Bat body with gradient
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.securityAccent.withValues(alpha: .7),
            tokens.securityAccent.withValues(alpha: .6),
            tokens.securityCrystalBody[2],
          ],
        ).createShader(bounds),
    );

    // Bat outline
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = tokens.securityCrystalEdge,
    );

    // Keyhole (cut out)
    final keyholePath = Path()
      ..addOval(Rect.fromCircle(center: const Offset(50, 50), radius: 6))
      ..moveTo(46.5, 54)
      ..lineTo(53.5, 54)
      ..lineTo(55.5, 70)
      ..lineTo(44.5, 70)
      ..close();

    // Keyhole cutout (punch through)
    canvas.drawPath(
      keyholePath,
      Paint()
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.clear
        ..color = Colors.transparent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}