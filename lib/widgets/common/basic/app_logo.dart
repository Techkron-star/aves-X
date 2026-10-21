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
/// AppLogo.tonal(size: 40, framed: true, elevation: 1)
/// ```
///
/// The widget is RTL-aware (mirrors the mark) and respects the parent
/// [IconTheme] for both size (when [size] is null) and the monochrome ink.
///
/// Material 3 Expressive treatment:
/// - optional rounded container ([framed]) filled with a container role,
/// - elevation levels 0/1/2/3 expressed with the scheme shadow color,
/// - state layers (hover/focus/pressed/dragged) from `colorScheme.onSurface`
///   when the logo is interactive ([onTap] set),
/// - short cross-fade/scale motion when the variant or the size changes.
///
/// The friends of this widget are [AppLogoPainter] (shapes) and the Nebula
/// theme tokens: when Nosferatu Glass is active the `ColorScheme` is built from
/// the ruby seed, so the "brand" look is preserved without hardcoding colors.
class AppLogo extends StatelessWidget {
  /// Optional explicit edge length. Defaults to `IconTheme.of(context).size`,
  /// then to 24.
  final double? size;

  final AppLogoVariant variant;

  /// Optional accessibility label. The mark is decorative by default.
  final String? semanticLabel;

  /// Whether the mark is drawn over a Material 3 container. Off by default, so
  /// the mark keeps behaving like a plain icon.
  final bool framed;

  /// Container color, overriding the role picked for [variant].
  final Color? containerColor;

  /// Material 3 elevation level: `0` (none), `1`, `2` or `3`.
  /// Only visible over a container (see [framed]).
  final double elevation;

  /// Corner radius of the container and of the ink state layer.
  /// `16` follows the Material 3 Expressive shape scale.
  final double radius;

  /// Makes the logo interactive: adds an ink state layer. `null` keeps it
  /// decorative, with no state layer, as Material 3 expects.
  final VoidCallback? onTap;

  /// Animates variant/size/decoration changes. Set to `false` in performance
  /// mode or when the caller already knows motion is not wanted.
  final bool animate;

  const AppLogo({
    super.key,
    this.size,
    this.variant = AppLogoVariant.primary,
    this.semanticLabel,
    this.framed = false,
    this.containerColor,
    this.elevation = 0,
    this.radius = 16,
    this.onTap,
    this.animate = true,
  });

  const AppLogo.primary({super.key, this.size, this.semanticLabel, this.onTap, this.animate = true})
    : variant = AppLogoVariant.primary,
      framed = false,
      containerColor = null,
      elevation = 0,
      radius = 16;

  const AppLogo.secondary({super.key, this.size, this.semanticLabel, this.onTap, this.animate = true})
    : variant = AppLogoVariant.secondary,
      framed = false,
      containerColor = null,
      elevation = 0,
      radius = 16;

  const AppLogo.tonal({super.key, this.size, this.semanticLabel, this.onTap, this.animate = true})
    : variant = AppLogoVariant.tonal,
      framed = false,
      containerColor = null,
      elevation = 0,
      radius = 16;

  const AppLogo.outline({super.key, this.size, this.semanticLabel, this.onTap, this.animate = true})
    : variant = AppLogoVariant.outline,
      framed = false,
      containerColor = null,
      elevation = 0,
      radius = 16;

  const AppLogo.monochrome({super.key, this.size, this.semanticLabel, this.onTap, this.animate = true})
    : variant = AppLogoVariant.monochrome,
      framed = false,
      containerColor = null,
      elevation = 0,
      radius = 16;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconTheme = IconTheme.of(context);
    final dimension = size ?? iconTheme.size ?? 24;

    final (fills, stroke) = _resolveColors(colors, iconTheme.color);

    final borderRadius = BorderRadius.circular(radius);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final motion = (animate && !reduceMotion) ? const Duration(milliseconds: 220) : Duration.zero;

    // the painter itself is cheap; the switch only runs when the variant or the
    // edge length changes, so theme changes cross-fade instead of popping
    Widget mark = SizedBox.square(
      dimension: dimension,
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
          dimension: dimension,
          child: CustomPaint(
            key: ValueKey('${variant.name}-$dimension'),
            painter: AppLogoPainter(fills: fills, stroke: stroke),
            isComplex: true,
            willChange: false,
          ),
        ),
      ),
    );

    Widget child = SizedBox.square(
      dimension: dimension,
      child: AnimatedContainer(
        duration: motion,
        curve: Curves.easeOutCubic,
        decoration: framed
            ? BoxDecoration(
                color: containerColor ?? _resolveContainer(colors),
                borderRadius: borderRadius,
                boxShadow: _elevationShadows(elevation, colors),
              )
            : null,
        child: _withStateLayer(colors, borderRadius, mark),
      ),
    );

    return Semantics(
      label: semanticLabel,
      image: true,
      button: onTap != null,
      child: Transform.flip(
        flipX: context.isRtl,
        child: child,
      ),
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

  /// Container role of the optional frame, following the variant.
  Color _resolveContainer(ColorScheme colors) => switch (variant) {
    AppLogoVariant.primary => colors.primaryContainer,
    AppLogoVariant.secondary => colors.secondaryContainer,
    AppLogoVariant.tonal => colors.tertiaryContainer,
    AppLogoVariant.outline => colors.surfaceContainerHigh,
    AppLogoVariant.monochrome => colors.surfaceContainerHighest,
  };

  /// Material 3 elevation levels 1/2/3, using the scheme shadow color so the
  /// logo follows dark themes and Material You instead of a fixed black.
  List<BoxShadow> _elevationShadows(double level, ColorScheme colors) {
    if (level <= 0) return const [];
    final shadow = colors.shadow;
    if (level <= 1) {
      return [BoxShadow(color: shadow.withValues(alpha: .12), blurRadius: 3, offset: const Offset(0, 1))];
    }
    if (level <= 2) {
      return [BoxShadow(color: shadow.withValues(alpha: .16), blurRadius: 6, offset: const Offset(0, 2))];
    }
    return [BoxShadow(color: shadow.withValues(alpha: .20), blurRadius: 8, offset: const Offset(0, 3))];
  }

  /// Ink state layer of an interactive logo: hover 8%, focus/pressed 12%,
  /// dragged 16% of `colorScheme.onSurface`, clipped to the rounded shape.
  Widget _withStateLayer(ColorScheme colors, BorderRadius borderRadius, Widget child) {
    final onTap = this.onTap;
    if (onTap == null) return child;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: borderRadius),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.dragged)) {
            return colors.onSurface.withValues(alpha: .16);
          }
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.focused)) {
            return colors.onSurface.withValues(alpha: .12);
          }
          if (states.contains(WidgetState.hovered)) {
            return colors.onSurface.withValues(alpha: .08);
          }
          return null;
        }),
        child: child,
      ),
    );
  }
}

/// Paints the four flat bat shapes. Mirrors the `AvesLogo` geometry, but with
/// injectable Material 3 colors and no hardcoded palette.
///
/// Every shape is built from `lineTo` segments joined by conjunctive arcs, so
/// the outline is already rounded like the Material 3 Expressive shape scale.
/// The frame, its elevation (`colorScheme.shadow`) and the state layers live in
/// [AppLogo], where they can react to the scheme without repainting paths.
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
