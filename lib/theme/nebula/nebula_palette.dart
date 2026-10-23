import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

// How the surfaces on top of the color scheme are painted.
enum NebulaSurfaceTreatment {
  // plain Material surfaces
  flat,
  // Nosferatu Glass: smoked ruby crystal, light blur and faceted edges
  nosferatuGlass,
  // frosted neutral glass, like Glass-Everywhere
  frosted,
  // Aureate Glass: gold crystal
  aureateGlass,
  // Obsidian Glass: blood-ruby crystal over near-black surfaces
  obsidianGlass,
  // Forge Glass: cosmic violet crystal with molten-orange glints (phase 2 effects)
  forgeGlass,
  // Hermetic Glass: emerald crystal with violet edges (phase 2 effects)
  hermeticGlass,
  // Eclipse Glass: deep midnight blue crystal with electric cyan accents (phase 2 effects)
  eclipseGlass,
  // Solar Flare Glass: molten orange crystal with gold accents (phase 2 effects)
  solarFlareGlass,
  // Void Glass: neon green crystal on graphite black (phase 2 effects)
  voidGlass,
  // Crimson Glass: burgundy crystal with dark red accents (phase 2 effects)
  crimsonGlass,
  // Neon Glass: hot pink and electric blue crystal on black (phase 2 effects)
  neonGlass,
  // Emerald Glass: deep forest emerald crystal with gold veins (phase 2 effects)
  emeraldGlass,
  // Aurora Glass: polar green and ice blue dancing like northern lights (phase 2 effects)
  auroraGlass,
  // Sapphire Glass: deep royal sapphire with brilliant cyan highlights (phase 2 effects)
  sapphireGlass,
  // Amber Glass: warm fossil amber with honey orange and gold (phase 2 effects)
  amberGlass,
  // Onyx Glass: pure black with graphite grey — minimalist monochrome (phase 2 effects)
  onyxGlass,
  // Pearl Glass: soft pearl white with shell pink and subtle gold (phase 2 effects)
  pearlGlass,
  // Ivory Glass: warm ivory cream with champagne gold accents (phase 2 effects)
  ivoryGlass,
  // Imperial Glass: gunmetal steel with brass rivets and aquila gold (phase 2 effects)
  imperialGlass,
  // Abyssal Glass: bioluminescent teal over abyssal navy
  abyssalGlass,
  // Sakura Glass: ink black with cherry blossom pink and lacquer red
  sakuraGlass,
  // Nox Terroris: matte void, ossuary bone and a toxic watching eye.
  noxTerroris,
}

// A Nebula palette: colors and surface treatment only.
//
// It intentionally carries no effect or animation, so that phase 1 themes stay as cheap as Nosferatu Glass.
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
