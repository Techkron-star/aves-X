import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

// How the surfaces on top of the color scheme are painted.
enum NebulaSurfaceTreatment {
  // plain Material surfaces
  flat,
  // Bat-Glass: smoked ruby crystal, light blur and faceted edges
  rubyCrystal,
  // frosted neutral glass, like Glass-Everywhere
  frosted,
  // Godly: gold crystal
  goldCrystal,
}

// A Nebula palette: colors and surface treatment only.
//
// It intentionally carries no effect or animation, so that phase 1 themes stay as cheap as Bat-Glass.
// `brightness == null` means the theme follows the user brightness setting, like the default Aves theme,
// which delegates to the legacy light/dark/black themes.
@immutable
class NebulaPalette {
  final NebulaTheme theme;

  final Brightness? brightness;

  // the theme is always used with `ThemeMode.dark`
  final bool darkOnly;

  // whether the system dynamic color may replace `accent` (never for the crystal themes)
  final bool allowDynamicColor;

  final Color seed;
  final Color accent;

  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color outlineVariant;

  final NebulaSurfaceTreatment treatment;

  // soft light around crystals and bubble glows
  final Color glow;
  // bright bevelled edge of the crystal
  final Color crystalEdge;
  // table highlight of the crystal
  final Color crystalHighlight;
  // crystal body gradient, from the brightest facet to the deepest one
  final List<Color> crystalBody;
  // whether icons get the liquid highlight
  final bool liquidIcons;

  // optional translucent "crystal" button instead of the solid fill
  final Color? filledButtonBackground;
  final Color? filledButtonBorder;

  const NebulaPalette({
    required this.theme,
    required this.brightness,
    required this.darkOnly,
    required this.allowDynamicColor,
    required this.seed,
    required this.accent,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.outlineVariant,
    required this.treatment,
    required this.glow,
    required this.crystalEdge,
    required this.crystalHighlight,
    required this.crystalBody,
    required this.liquidIcons,
    this.filledButtonBackground,
    this.filledButtonBorder,
  });

  @override
  bool operator ==(Object other) =>
      other is NebulaPalette &&
      other.theme == theme &&
      other.brightness == brightness &&
      other.darkOnly == darkOnly &&
      other.allowDynamicColor == allowDynamicColor &&
      other.seed == seed &&
      other.accent == accent &&
      other.surface == surface &&
      other.surfaceContainerLowest == surfaceContainerLowest &&
      other.surfaceContainerLow == surfaceContainerLow &&
      other.surfaceContainer == surfaceContainer &&
      other.surfaceContainerHigh == surfaceContainerHigh &&
      other.surfaceContainerHighest == surfaceContainerHighest &&
      other.outlineVariant == outlineVariant &&
      other.treatment == treatment &&
      other.glow == glow &&
      other.crystalEdge == crystalEdge &&
      other.crystalHighlight == crystalHighlight &&
      listEquals(other.crystalBody, crystalBody) &&
      other.liquidIcons == liquidIcons &&
      other.filledButtonBackground == filledButtonBackground &&
      other.filledButtonBorder == filledButtonBorder;

  @override
  int get hashCode => Object.hashAll([
    theme,
    brightness,
    darkOnly,
    allowDynamicColor,
    seed,
    accent,
    surface,
    surfaceContainerLowest,
    surfaceContainerLow,
    surfaceContainer,
    surfaceContainerHigh,
    surfaceContainerHighest,
    outlineVariant,
    treatment,
    glow,
    crystalEdge,
    crystalHighlight,
    Object.hashAll(crystalBody),
    liquidIcons,
    filledButtonBackground,
    filledButtonBorder,
  ]);
}
