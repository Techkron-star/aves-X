import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:material_ui/material_ui.dart';

/// Color treatments for the Aves-X bat mark.
///
/// Every variant is derived from the active [ColorScheme], so the logo follows
/// the app theme, the system light/dark mode and the dynamic (Material You)
/// seed color. Nothing is hardcoded here.
enum AppLogoVariant {
  /// Four dynamic accents, led by `colorScheme.primary`.
  primary,

  /// Same idea, led by `colorScheme.secondary`.
  secondary,

  /// Soft `*Container` roles, for use over surfaces.
  tonal,

  /// Transparent shapes with a single `colorScheme.primary` outline.
  outline,

  /// Single ink color, suitable for themed/Material You surfaces.
  /// Takes `IconTheme.of(context).color` when available.
  monochrome,
}

/// Flat, vector Aves-X logo painted with Material 3 / Material You roles.
///
/// ```dart
/// const AppLogo.tonal(size: 48)
/// AppLogo(variant: AppLogoVariant.secondary, size: 32)
/// ```
///
/// The widget is RTL-aware (mirrors the mark) and respects the parent
/// [IconTheme] for both size (when [size] is null) and the monochrome ink.
class AppLogo extends StatelessWidget {
  /// Optional explicit edge length. Defaults to `IconTheme.of(context).size`,
  /// then to 24.
  final double? size;

  final AppLogoVariant variant;

  /// Optional accessibility label. The mark is decorative by default.
  final String? semanticLabel;

  const AppLogo({
    super.key,
    this.size,
    this.variant = AppLogoVariant.primary,
    this.semanticLabel,
  });

  const AppLogo.primary({super.key, this.size, this.semanticLabel}) : variant = AppLogoVariant.primary;

  const AppLogo.secondary({super.key, this.size, this.semanticLabel}) : variant = AppLogoVariant.secondary;

  const AppLogo.tonal({super.key, this.size, this.semanticLabel}) : variant = AppLogoVariant.tonal;

  const AppLogo.outline({super.key, this.size, this.semanticLabel}) : variant = AppLogoVariant.outline;

  const AppLogo.monochrome({super.key, this.size, this.semanticLabel}) : variant = AppLogoVariant.monochrome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final iconTheme = IconTheme.of(context);
    final dimension = size ?? iconTheme.size ?? 24;

    final (fills, stroke) = _resolveColors(colors, iconTheme.color);

    Widget child = SizedBox.square(
      dimension: dimension,
      child: CustomPaint(
        painter: AppLogoPainter(fills: fills, stroke: stroke),
        isComplex: true,
        willChange: false,
      ),
    );

    child = Transform.flip(
      flipX: context.isRtl,
      child: child,
    );

    return Semantics(
      label: semanticLabel,
      image: true,
      child: child,
    );
  }

  /// Maps the seeded [ColorScheme] roles to the four shapes of the mark.
  (List<Color?>, Color?) _resolveColors(ColorScheme colors, Color? iconColor) {
    switch (variant) {
      case AppLogoVariant.primary:
        return (
          <Color?>[colors.primary, colors.tertiary, colors.secondary, colors.primaryContainer],
          null,
        );
      case AppLogoVariant.secondary:
        return (
          <Color?>[colors.secondary, colors.primary, colors.tertiary, colors.secondaryContainer],
          null,
        );
      case AppLogoVariant.tonal:
        return (
          <Color?>[colors.primaryContainer, colors.tertiaryContainer, colors.secondaryContainer, colors.surfaceContainerHighest],
          null,
        );
      case AppLogoVariant.outline:
        return (const <Color?>[null, null, null, null], colors.primary);
      case AppLogoVariant.monochrome:
        final ink = iconColor ?? colors.onSurface;
        return (<Color?>[ink, ink, ink, ink], null);
    }
  }
}

/// Paints the four flat bat shapes. Mirrors [AvesLogoPainter] geometry, but with
/// injectable Material 3 colors and no hardcoded palette.
class AppLogoPainter extends CustomPainter {
  /// One fill per shape, in order: lower left, centre, right, upper left.
  /// A `null` entry draws no fill (used by [AppLogoVariant.outline]).
  final List<Color?> fills;

  /// Optional outline painted on top of every shape.
  final Color? stroke;

  AppLogoPainter({required this.fills, this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final dim = size.shortestSide / 100;
    final paths = _buildPaths(dim);

    for (var i = 0; i < paths.length; i++) {
      final fill = i < fills.length ? fills[i] : null;
      if (fill != null) {
        canvas.drawPath(
          paths[i],
          Paint()
            ..style = PaintingStyle.fill
            ..color = fill,
        );
      }
    }

    if (stroke != null) {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = stroke!
        ..strokeWidth = dim * 3.050970
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Stroke over fill, like the original mark.
      for (final path in paths) {
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  List<Path> _buildPaths(double dim) {
    final path0 = Path();
    path0.moveTo(31.784 * dim, 63.612 * dim);
    path0.lineTo(48.252 * dim, 80.08 * dim);
    final radius = Radius.elliptical(2.911 * dim, 2.911 * dim);
    path0.arcToPoint(Offset(48.252 * dim, 84.196 * dim), radius: radius, rotation: 0, largeArc: false, clockwise: true);
    path0.lineTo(40.379 * dim, 92.069 * dim);
    path0.arcToPoint(Offset(19.072 * dim, 92.069 * dim), radius: Radius.elliptical(15.067 * dim, 15.067 * dim), rotation: 0, largeArc: false, clockwise: true);
    path0.lineTo(11.2 * dim, 84.197 * dim);
    path0.arcToPoint(Offset(11.2 * dim, 80.08 * dim), radius: radius, rotation: 0, largeArc: false, clockwise: true);
    path0.lineTo(27.668 * dim, 63.612 * dim);
    path0.arcToPoint(Offset(31.785 * dim, 63.612 * dim), radius: radius, rotation: 0, largeArc: false, clockwise: true);
    path0.close();

    final path1 = Path();
    path1.moveTo(56.368 * dim, 39.026 * dim);
    path1.lineTo(72.837 * dim, 55.494 * dim);
    final radius2 = Radius.elliptical(2.904 * dim, 2.904 * dim);
    path1.arcToPoint(Offset(72.837 * dim, 59.611 * dim), radius: radius2, rotation: 0, largeArc: false, clockwise: true);
    path1.lineTo(56.367 * dim, 76.079 * dim);
    path1.arcToPoint(Offset(52.252 * dim, 76.079 * dim), radius: radius2, rotation: 0, largeArc: false, clockwise: true);
    path1.lineTo(35.784 * dim, 59.611 * dim);
    path1.arcToPoint(Offset(35.784 * dim, 55.495 * dim), radius: radius2, rotation: 0, largeArc: false, clockwise: true);
    path1.lineTo(52.252 * dim, 39.027 * dim);
    path1.arcToPoint(Offset(56.368 * dim, 39.027 * dim), radius: radius2, rotation: 0, largeArc: false, clockwise: true);
    path1.close();

    final path2 = Path();
    path2.moveTo(60.37 * dim, 30.908 * dim);
    final radius4 = Radius.elliptical(2.91 * dim, 2.91 * dim);
    path2.arcToPoint(Offset(60.37 * dim, 35.025 * dim), radius: radius4, rotation: 0, largeArc: false, clockwise: false);
    path2.lineTo(76.838 * dim, 51.492 * dim);
    path2.arcToPoint(Offset(80.954 * dim, 51.492 * dim), radius: radius4, rotation: 0, largeArc: false, clockwise: false);
    path2.lineTo(97.422 * dim, 35.025 * dim);
    path2.arcToPoint(Offset(97.422 * dim, 30.908 * dim), radius: radius4, rotation: 0, largeArc: false, clockwise: false);
    path2.lineTo(89.248 * dim, 22.734 * dim);
    path2.arcToPoint(Offset(68.544 * dim, 22.734 * dim), radius: Radius.elliptical(14.64 * dim, 14.64 * dim), rotation: 0, largeArc: false, clockwise: false);
    path2.close();
    path2.moveTo(76.624 * dim, 30.695 * dim);
    final radius5 = Radius.elliptical(3.213 * dim, 3.213 * dim);
    path2.arcToPoint(Offset(81.167 * dim, 30.695 * dim), radius: radius5, rotation: 0, largeArc: false, clockwise: true);
    path2.arcToPoint(Offset(81.167 * dim, 35.237 * dim), radius: radius5, rotation: 0, largeArc: false, clockwise: true);
    path2.arcToPoint(Offset(76.624 * dim, 35.237 * dim), radius: radius5, rotation: 0, largeArc: false, clockwise: true);
    path2.arcToPoint(Offset(76.624 * dim, 30.694 * dim), radius: radius5, rotation: 0, largeArc: false, clockwise: true);
    path2.close();

    final path3 = Path();
    path3.moveTo(24.305 * dim, 6.96 * dim);
    path3.lineTo(48.35 * dim, 31.004 * dim);
    path3.arcToPoint(Offset(48.35 * dim, 35.121 * dim), radius: radius, rotation: 0, largeArc: false, clockwise: true);
    path3.lineTo(31.882 * dim, 51.588 * dim);
    path3.arcToPoint(Offset(27.765 * dim, 51.588 * dim), radius: radius, rotation: 0, largeArc: false, clockwise: true);
    path3.lineTo(17.084 * dim, 40.907 * dim);
    path3.arcToPoint(Offset(17.084 * dim, 8.75 * dim), radius: Radius.elliptical(22.738 * dim, 22.738 * dim), rotation: 0, largeArc: false, clockwise: true);
    path3.lineTo(18.874 * dim, 6.96 * dim);
    path3.arcToPoint(Offset(24.305 * dim, 6.96 * dim), radius: Radius.elliptical(3.84 * dim, 3.84 * dim), rotation: 0, largeArc: false, clockwise: true);
    path3.close();

    return [path0, path1, path2, path3];
  }

  @override
  bool shouldRepaint(covariant AppLogoPainter oldDelegate) {
    if (oldDelegate.stroke != stroke) return true;
    if (oldDelegate.fills.length != fills.length) return true;
    for (var i = 0; i < fills.length; i++) {
      if (oldDelegate.fills[i] != fills[i]) return true;
    }
    return false;
  }
}
