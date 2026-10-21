import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_palettes.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';

// Aves-X logo using the Nosferatu bat mark.
// Replaces the original PNG with a vector bat that follows the theme.
//
// Colors come from two sources:
// - Nosferatu Glass (and every crystal theme that opts out of dynamic color)
//   keeps its fixed ruby identity from the Nebula tokens,
// - the default / Material You themes derive the gradient from the
//   `ColorScheme`, so the logo follows the system seed color,
// - monochrome uses the ambient `IconTheme` ink, like an icon.
class AvesLogo extends StatelessWidget {
  const AvesLogo({super.key, required this.size, this.semanticLabel, this.animate = true});

  final double size;

  /// Accessibility label. Defaults to the app name.
  final String? semanticLabel;

  /// Cross-fades the mark when the theme, the ink or the size changes.
  /// `settings.animate` already covers performance mode and accessibility.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = theme.nebula;
    final settings = context.watch<Settings>();
    final palette = nebulaPaletteFor(settings.effectiveNebulaTheme);

    final monochrome = settings.themeColorMode == AvesThemeColorMode.monochrome;
    final dynamicColor = palette.allowDynamicColor;
    final ink = IconTheme.of(context).color ?? colors.onSurface;

    late final List<Color> fill;
    late final Color? edge;
    late final Color ringOuter;
    late final Color ringInner;

    if (monochrome) {
      // single ink, no outline: reads like a themed icon
      fill = [ink, ink, ink];
      edge = null;
      ringOuter = colors.surfaceContainerHighest;
      ringInner = colors.surface;
    } else if (dynamicColor) {
      // Material You: primary/secondary/tertiary follow the dynamic seed
      fill = [
        colors.primary.withValues(alpha: .9),
        colors.secondary.withValues(alpha: .75),
        colors.tertiary,
      ];
      edge = colors.outlineVariant;
      ringOuter = colors.surfaceContainerHighest;
      ringInner = colors.surface;
    } else {
      // fixed crystal identity (Nosferatu Glass and the other crystal themes)
      final body = tokens.securityCrystalBody;
      fill = [
        tokens.securityAccent.withValues(alpha: .70),
        tokens.securityAccent.withValues(alpha: .60),
        body.length > 2 ? body[2] : tokens.securityAccent,
      ];
      edge = tokens.securityCrystalEdge;
      ringOuter = tokens.securityScrim;
      ringInner = tokens.securitySurface;
    }

    final motion = (animate && settings.animate) ? const Duration(milliseconds: 240) : Duration.zero;
    // only the look or the size restarts the animation
    final look = '$monochrome-$size-${Object.hashAll(fill)}-${edge?.hashCode}';

    Widget child = SizedBox.square(
      dimension: size,
      child: AnimatedSwitcher(
        duration: motion,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: .92, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: SizedBox.square(
          key: ValueKey(look),
          dimension: size,
          child: CustomPaint(
            painter: _AvesLogoPainter(fill: fill, edge: edge),
            isComplex: true,
            willChange: false,
          ),
        ),
      ),
    );

    final avatar = CircleAvatar(
      backgroundColor: ringOuter,
      radius: size / 2,
      child: CircleAvatar(
        backgroundColor: ringInner,
        radius: size / 2 - 2,
        child: child,
      ),
    );

    return Semantics(
      label: semanticLabel ?? context.l10n.appName,
      image: true,
      child: Transform.flip(
        flipX: context.isRtl,
        child: avatar,
      ),
    );
  }
}

// Paints the Nosferatu bat mark. The colors are injected by [AvesLogo], from
// the Nebula tokens or from the `ColorScheme`, so the same geometry serves the
// brand look and Material You.
class _AvesLogoPainter extends CustomPainter {
  const _AvesLogoPainter({required this.fill, this.edge});

  final List<Color> fill;
  final Color? edge;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
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

    // Bat body: gradient for the brand/scheme look, flat for monochrome
    final Paint bodyPaint;
    if (fill.length < 2) {
      bodyPaint = Paint()..color = fill.isEmpty ? const Color(0x00FF6A80) : fill.first;
    } else {
      bodyPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: fill,
        ).createShader(path.getBounds());
    }
    canvas.drawPath(path, bodyPaint);

    // Bat outline
    final edge = this.edge;
    if (edge != null) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = edge,
      );
    }

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
  bool shouldRepaint(covariant _AvesLogoPainter oldDelegate) => oldDelegate.edge != edge || !listEquals(oldDelegate.fill, fill);
}
