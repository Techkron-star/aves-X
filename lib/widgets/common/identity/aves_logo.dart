import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_palettes.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_logo_art.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';

// Aves-X logo: the bat artwork of `aves_logo.svg`, painted from its exact paths
// (see `aves_logo_art.dart`).
//
// Colors come from two sources:
// - Nosferatu Glass (and every crystal theme that opts out of dynamic color)
//   paints the artwork with its own ruby/black fills, exactly as the SVG,
// - the default / Material You themes paint the silhouette with a gradient
//   derived from the `ColorScheme`, so the logo follows the system seed color,
// - monochrome paints the silhouette with the ambient `IconTheme` ink, like an
//   icon.
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

    late final Color? tint;
    late final List<Color>? gradient;
    late final Color ringOuter;
    late final Color ringInner;

    if (monochrome) {
      // single ink: the exact silhouette, like a themed icon
      tint = ink;
      gradient = null;
      ringOuter = colors.surfaceContainerHighest;
      ringInner = colors.surface;
    } else if (dynamicColor) {
      // Material You: primary/secondary/tertiary follow the dynamic seed
      tint = null;
      gradient = [colors.primary.withValues(alpha: .95), colors.secondary, colors.tertiary];
      ringOuter = colors.surfaceContainerHighest;
      ringInner = colors.surface;
    } else {
      // fixed crystal identity (Nosferatu Glass and the other crystal themes):
      // the original artwork fills, untouched
      tint = null;
      gradient = null;
      ringOuter = tokens.securityScrim;
      ringInner = tokens.securitySurface;
    }

    final motion = (animate && settings.animate) ? const Duration(milliseconds: 240) : Duration.zero;
    // only the look or the size restarts the animation
    final look = '$monochrome-$size-${Object.hashAll(gradient ?? const <Color>[])}-${tint?.hashCode}';

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
            painter: AvesLogoArtPainter(tint: tint, gradient: gradient, fit: .95),
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
