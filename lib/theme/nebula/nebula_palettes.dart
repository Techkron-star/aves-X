import 'package:aves/theme/nebula/nebula_palette.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:material_ui/material_ui.dart';

// Phase 1 palettes.
//
// Themes without an entry here fall back to `aves` until their own palette is defined, so that a stale
// or hand-edited setting can never leave the app without a theme.
const Map<NebulaTheme, NebulaPalette> nebulaPalettes = {
  // default Aves theme: no overrides, it delegates to the legacy light/dark/black themes.
  // The colors below are neutral placeholders: the effective colors come from the legacy ColorScheme,
  // and the Fail-Safe tokens are derived from that scheme too.
  NebulaTheme.aves: NebulaPalette(
    theme: NebulaTheme.aves,
    brightness: null,
    darkOnly: false,
    allowDynamicColor: true,
    seed: Color(0xFFC62828), // same as `AvesColorsData.defaultAccent`
    accent: Color(0xFFC62828),
    surface: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F2FA),
    surfaceContainer: Color(0xFFF3EDF7),
    surfaceContainerHigh: Color(0xFFECE6F0),
    surfaceContainerHighest: Color(0xFFE6E0E9),
    outlineVariant: Color(0xFFCAC4D0),
    treatment: NebulaSurfaceTreatment.flat,
    glow: Color(0x66C62828),
    crystalEdge: Color(0x66FFFFFF),
    crystalHighlight: Color(0x33FFFFFF),
    crystalBody: [
      Color(0xFFFFFFFF),
      Color(0xFFE0E0E0),
      Color(0xFF9E9E9E),
      Color(0xFF424242),
    ],
    liquidIcons: false,
  ),
  // exact copy of the legacy `Themes.batGlassTheme` values, so that the switch to the Nebula Engine
  // does not change the Bat-Glass look in any way
  NebulaTheme.batGlass: NebulaPalette(
    theme: NebulaTheme.batGlass,
    brightness: Brightness.dark,
    darkOnly: true,
    allowDynamicColor: false,
    seed: Color(0xFFE0183E),
    accent: Color(0xFFE0183E),
    surface: Color(0xFF000000),
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF0E0407),
    surfaceContainer: Color(0xFF16060B),
    surfaceContainerHigh: Color(0xFF1F0910),
    surfaceContainerHighest: Color(0xFF2A0D16),
    outlineVariant: Color(0xFF5A1626),
    treatment: NebulaSurfaceTreatment.rubyCrystal,
    glow: Color(0xFFE0183E),
    crystalEdge: Color(0x80FF3B5C),
    crystalHighlight: Color(0x55E0183E),
    crystalBody: [
      Color(0xFFFF4A66),
      Color(0xFFD81B3F),
      Color(0xFF8E0E2B),
      Color(0xFF4A0414),
    ],
    liquidIcons: true,
    filledButtonBackground: Color(0xB3C4122F),
    filledButtonBorder: Color(0x99FFB3BF),
  ),
};

// Palette actually used for a theme. Unknown or not-yet-implemented themes fall back to the default one.
NebulaPalette nebulaPaletteFor(NebulaTheme theme) => nebulaPalettes[theme] ?? nebulaPalettes[NebulaTheme.aves]!;
