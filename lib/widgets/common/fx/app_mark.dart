import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves/theme/nebula/nebula_palettes.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/widgets/common/identity/aves_logo_art.dart';
import 'package:material_ui/material_ui.dart';

// Bat mark: the Aves-X artwork of `aves_logo.svg`, drawn without a padlock.
// Used by the About screen, the Fail-Safe comic bubble and the lockdown screen.
// The padlock itself is drawn by `_PadlockPainter` in `lock_animation.dart`.
//
// The geometry is shared with [AvesLogo] and with the Android launcher icon, so
// the same drawing appears everywhere; the tone only decides the ink.

/// Color source of the mark.
enum AppMarkTone {
  /// Follows the active identity: Nosferatu keeps its original ink while every
  /// other glass theme receives palette-specific ink.
  auto,

  /// Original artwork fills, exactly as the source SVG (ruby, black, highlights).
  brand,

  /// Silhouette painted with a gradient derived from `ColorScheme`
  /// (Material You seed).
  scheme,

  /// Single ink color from `IconTheme.of(context).color`, else `onSurface`.
  monochrome,
}

class AppMark extends StatelessWidget {
  final double size;
  final bool mirrored;
  final AppMarkTone tone;

  /// Optional accessibility label. The mark is decorative by default.
  final String? semanticLabel;

  /// Cross-fades the mark when the theme/size changes. `settings.animate`
  /// already includes performance mode and the accessibility setting.
  final bool animate;

  const AppMark({
    super.key,
    this.size = 28,
    this.mirrored = false,
    this.tone = AppMarkTone.auto,
    this.semanticLabel,
    this.animate = true,
  });

  const AppMark.monochrome({super.key, this.size = 28, this.mirrored = false, this.semanticLabel, this.animate = true})
    : tone = AppMarkTone.monochrome;

  const AppMark.brand({super.key, this.size = 28, this.mirrored = false, this.semanticLabel, this.animate = true})
    : tone = AppMarkTone.brand;

  const AppMark.scheme({super.key, this.size = 28, this.mirrored = false, this.semanticLabel, this.animate = true})
    : tone = AppMarkTone.scheme;

  /// `auto` keeps the original artwork for Nosferatu; the other glass themes
  /// render the same bat silhouette with identity ink derived from their palette.
  AppMarkTone get _effectiveTone =>
      tone != AppMarkTone.auto ? tone : (settings.effectiveNebulaTheme == NebulaTheme.nosferatuGlass ? AppMarkTone.brand : AppMarkTone.scheme);

  List<Color>? get _themeInk {
    final theme = settings.effectiveNebulaTheme;
    switch (theme) {
      case NebulaTheme.obsidianGlass:
        return const [Color(0xFFD9B8FF), Color(0xFF9B5DE5), Color(0xFF6A1B9A)];
      case NebulaTheme.aureateGlass:
        return const [Color(0xFFFFE9A3), Color(0xFFF2C14E), Color(0xFFB8860B)];
      case NebulaTheme.aves:
      case NebulaTheme.nosferatuGlass:
        return null;
      default:
        final palette = nebulaPalettes[theme];
        if (palette == null) return null;
        return [palette.crystalBody.first, palette.accent, palette.crystalBody.last];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).nebula;
    final iconColor = IconTheme.of(context).color;
    final effectiveTone = _effectiveTone;

    final Color? tint;
    final List<Color>? gradient;
    switch (effectiveTone) {
      case AppMarkTone.brand:
        // exact artwork fills, no injected color
        tint = null;
        gradient = null;
      case AppMarkTone.scheme:
        // Material You: the seed drives primary/secondary/tertiary
        tint = null;
        gradient = (tone == AppMarkTone.auto ? _themeInk : null) ??
            [
              colors.primary.withValues(alpha: .85),
              colors.secondary.withValues(alpha: .75),
              colors.tertiary,
            ];
      case AppMarkTone.monochrome:
        tint = iconColor ?? colors.onSurface;
        gradient = null;
      case AppMarkTone.auto:
        // resolved by `_effectiveTone`, kept for exhaustiveness
        tint = tokens.securityAccent;
        gradient = null;
    }

    final motion = (animate && settings.animate) ? const Duration(milliseconds: 240) : Duration.zero;
    // the key changes only with the look or the size, so plain rebuilds do not
    // restart the switch animation
    final look = '${effectiveTone.name}-$size-${Object.hashAll(gradient ?? const <Color>[])}-${tint?.hashCode}';

    final Widget mark = SizedBox.square(
      dimension: size,
      child: AnimatedSwitcher(
        duration: motion,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: RotationTransition(
            turns: Tween<double>(begin: -.02, end: 0).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(begin: .92, end: 1).animate(animation),
              child: child,
            ),
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

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Transform.flip(flipX: mirrored, child: mark),
    );
  }
}
