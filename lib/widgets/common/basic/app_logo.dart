import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_logo_art.dart';
import 'package:material_ui/material_ui.dart';

/// Color treatments for the Aves-X bat artwork.
///
/// Every variant is derived from the active [ColorScheme], so the logo follows
/// the app theme, the system light/dark mode and the dynamic (Material You)
/// seed color. Nothing is hardcoded here.
///
/// The geometry is the one of `aves_logo.svg` (see [AvesLogoArtPainter]); the
/// variants only choose how the ink is laid over it:
/// - gradient variants paint the silhouette with two scheme roles,
/// - [outline] and [monochrome] paint it with a single role/ink.
enum AppLogoVariant {
  /// Two dynamic accents, led by `colorScheme.primary`.
  primary,

  /// Same idea, led by `colorScheme.secondary`.
  secondary,

  /// Soft `*Container` roles, for use over surfaces.
  tonal,

  /// A muted single-role silhouette, for watermarks and disabled states.
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
/// The friend of this widget is [AvesLogoArtPainter] (exact artwork geometry)
/// and the Nebula theme tokens: when Nosferatu Glass is active the
/// `ColorScheme` is built from the ruby seed, so the "brand" look is preserved
/// without hardcoding colors.
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

    final (tint, gradient) = _resolveInk(colors, iconTheme.color);

    final borderRadius = BorderRadius.circular(radius);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final motion = (animate && !reduceMotion) ? const Duration(milliseconds: 220) : Duration.zero;

    // the painter itself is cheap (the artwork paths are parsed once per
    // process); the switch only runs when the variant or the edge length
    // changes, so theme changes cross-fade instead of popping
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
            painter: AvesLogoArtPainter(tint: tint, gradient: gradient, fit: .95),
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

  /// Maps the seeded [ColorScheme] roles to the ink of the artwork.
  (Color?, List<Color>?) _resolveInk(ColorScheme colors, Color? iconColor) {
    switch (variant) {
      case AppLogoVariant.primary:
        return (null, <Color>[colors.primary, colors.tertiary]);
      case AppLogoVariant.secondary:
        return (null, <Color>[colors.secondary, colors.primary]);
      case AppLogoVariant.tonal:
        return (null, <Color>[colors.primaryContainer, colors.tertiaryContainer]);
      case AppLogoVariant.outline:
        return (colors.onSurfaceVariant.withValues(alpha: .55), null);
      case AppLogoVariant.monochrome:
        return (iconColor ?? colors.onSurface, null);
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
