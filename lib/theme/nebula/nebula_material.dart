import 'package:aves/theme/nebula/nebula_palette.dart';
import 'package:aves/theme/nebula/nebula_palettes.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:material_ui/material_ui.dart';

// The "material" a Nebula theme paints its surfaces and security emblem with.
//
// Each material has its own aesthetic, not just its own colors:
// - ruby: Nosferatu Glass, a cut red diamond with a bat emblem.
// - nightDemon: Obsidian Glass (code name Night Demon), black volcanic glass with glowing violet cracks,
//   beveled corners and a demon eye emblem.
// - godly: Aureate Glass (code name Godly), burnished gold leaf with divine rays, soft corners
//   and a haloed, winged padlock.
enum NebulaMaterial {
  ruby, nightDemon, godly, forge, hermetic, eclipse, solarFlare, voidGlass,
  crimson, neon, emerald, aurora, sapphire, amber, onyx, pearl, ivory, imperial,
}

@immutable
class NebulaMaterialStyle {
  final NebulaMaterial material;

  // glows, progress rings and selection
  final Color accent;
  // bright rim of the glass surfaces
  final Color edge;
  // smoked panel behind menus, sheets and cards (callers apply their own alpha)
  final Color surface;
  // smoked tone of dialogs
  final Color dialogSurface;
  // smoked tone of the progress overlay
  final Color feedbackSurface;
  // light reflection painted over the blurred surfaces
  final Gradient highlight;
  // lens over the selected navigation item
  final List<Color> lens;
  final Color lensBorder;
  // liquid highlight flowing inside icons
  final Color liquidHighlight;
  final Color liquidDeep;
  // translucent buttons
  final Color buttonFill;
  final Color buttonBorder;
  // light sweeping across the security emblem
  final Color shimmer;
  // chains crossing behind the security emblem: gradient and outline
  final List<Color> chain;
  final Color chainStroke;
  // progress overlay disc
  final List<Color> feedbackGradient;
  final Color feedbackBorder;

  const NebulaMaterialStyle({
    required this.material,
    required this.accent,
    required this.edge,
    required this.surface,
    required this.dialogSurface,
    required this.feedbackSurface,
    required this.highlight,
    required this.lens,
    required this.lensBorder,
    required this.liquidHighlight,
    required this.liquidDeep,
    required this.buttonFill,
    required this.buttonBorder,
    required this.shimmer,
    required this.chain,
    required this.chainStroke,
    required this.feedbackGradient,
    required this.feedbackBorder,
  });

  // Corner language is part of the identity: each theme owns a deliberate silhouette.
  ShapeBorder shape(double radius, BorderSide side) => switch (material) {
    NebulaMaterial.ruby => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: side),
    NebulaMaterial.nightDemon => BeveledRectangleBorder(borderRadius: BorderRadius.circular(radius * .62), side: side),
    NebulaMaterial.godly => ContinuousRectangleBorder(borderRadius: BorderRadius.circular(radius * 1.55), side: side),
    NebulaMaterial.forge => BeveledRectangleBorder(borderRadius: BorderRadius.circular(radius * 1.15), side: side),
    NebulaMaterial.hermetic => BeveledRectangleBorder(borderRadius: BorderRadius.circular(radius * .22), side: side),
    NebulaMaterial.eclipse => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * .45), side: side),
    NebulaMaterial.solarFlare => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 1.3), side: side),
    NebulaMaterial.voidGlass => BeveledRectangleBorder(borderRadius: BorderRadius.circular(radius * .16), side: side),
    NebulaMaterial.crimson => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * .58), side: side),
    NebulaMaterial.neon => BeveledRectangleBorder(borderRadius: BorderRadius.circular(radius * .95), side: side),
    NebulaMaterial.emerald => ContinuousRectangleBorder(borderRadius: BorderRadius.circular(radius * .78), side: side),
    NebulaMaterial.aurora => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 1.7), side: side),
    NebulaMaterial.sapphire => BeveledRectangleBorder(borderRadius: BorderRadius.circular(radius * .48), side: side),
    NebulaMaterial.amber => ContinuousRectangleBorder(borderRadius: BorderRadius.circular(radius * 1.08), side: side),
    NebulaMaterial.onyx => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * .24), side: side),
    NebulaMaterial.pearl => ContinuousRectangleBorder(borderRadius: BorderRadius.circular(radius * 1.85), side: side),
    NebulaMaterial.ivory => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 1.12), side: side),
    NebulaMaterial.imperial => BeveledRectangleBorder(borderRadius: BorderRadius.circular(radius * .12), side: side),
  };

  // Bottom sheets retain the same corner language while leaving their lower edge square.
  ShapeBorder topShape(double radius, BorderSide side) => switch (material) {
    NebulaMaterial.ruby => RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius)), side: side),
    NebulaMaterial.nightDemon => BeveledRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * .62)), side: side),
    NebulaMaterial.godly => ContinuousRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * 1.55)), side: side),
    NebulaMaterial.forge => BeveledRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * 1.15)), side: side),
    NebulaMaterial.hermetic => BeveledRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * .22)), side: side),
    NebulaMaterial.eclipse => RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * .45)), side: side),
    NebulaMaterial.solarFlare => RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * 1.3)), side: side),
    NebulaMaterial.voidGlass => BeveledRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * .16)), side: side),
    NebulaMaterial.crimson => RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * .58)), side: side),
    NebulaMaterial.neon => BeveledRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * .95)), side: side),
    NebulaMaterial.emerald => ContinuousRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * .78)), side: side),
    NebulaMaterial.aurora => RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * 1.7)), side: side),
    NebulaMaterial.sapphire => BeveledRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * .48)), side: side),
    NebulaMaterial.amber => ContinuousRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * 1.08)), side: side),
    NebulaMaterial.onyx => RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * .24)), side: side),
    NebulaMaterial.pearl => ContinuousRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * 1.85)), side: side),
    NebulaMaterial.ivory => RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * 1.12)), side: side),
    NebulaMaterial.imperial => BeveledRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * .12)), side: side),
  };

  /// Derives auxiliary materials from the selected theme's canonical palette.
  factory NebulaMaterialStyle.fromPalette(NebulaPalette palette, NebulaMaterial material) {
    final crystal = palette.crystalBody;
    final bright = crystal.isNotEmpty ? crystal.first : palette.accent;
    final deep = crystal.isNotEmpty ? crystal.last : palette.surface;
    return NebulaMaterialStyle(
      material: material,
      accent: palette.accent,
      edge: palette.crystalEdge,
      surface: palette.surfaceContainerHigh,
      dialogSurface: palette.surfaceContainerHigh.withValues(alpha: .94),
      feedbackSurface: palette.surfaceContainerLowest.withValues(alpha: .94),
      highlight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          palette.crystalHighlight.withValues(alpha: palette.crystalHighlight.a * .82),
          palette.crystalEdge.withValues(alpha: palette.crystalEdge.a * .52),
          palette.surface.withValues(alpha: .08),
          palette.accent.withValues(alpha: .12),
          palette.surface.withValues(alpha: .18),
        ],
        stops: const [0, .2, .48, .76, 1],
      ),
      lens: [
        palette.crystalHighlight.withValues(alpha: palette.crystalHighlight.a * .8),
        palette.glow.withValues(alpha: palette.glow.a * .48),
        palette.accent.withValues(alpha: .08),
      ],
      lensBorder: palette.crystalEdge,
      liquidHighlight: bright,
      liquidDeep: palette.accent,
      buttonFill: palette.filledButtonBackground ?? palette.accent.withValues(alpha: .2),
      buttonBorder: palette.filledButtonBorder ?? palette.crystalEdge,
      shimmer: palette.crystalHighlight,
      chain: [palette.accent, deep],
      chainStroke: palette.crystalEdge,
      feedbackGradient: [palette.glow.withValues(alpha: .38), palette.surfaceContainerLowest.withValues(alpha: .96)],
      feedbackBorder: palette.crystalEdge,
    );
  }
}

// Themes without an entry here have no glass material (the default Aves theme, the phase 2 themes).
// The ruby values are an exact copy of the constants that used to be hard-coded for Bat-Glass,
// so that Nosferatu Glass does not change in any way.
const Map<NebulaTheme, NebulaMaterialStyle> _legacyNebulaMaterials = {
  NebulaTheme.nosferatuGlass: NebulaMaterialStyle(
    material: NebulaMaterial.ruby,
    accent: Color(0xFFE0183E),
    edge: Color(0x80FF3B5C),
    surface: Color(0xFF2A0710),
    dialogSurface: Color(0xCC24060E),
    feedbackSurface: Color(0xCC14030A),
    highlight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x55E0183E), Color(0x14400010)],
    ),
    lens: [Color(0x55FF3B5C), Color(0x14E0183E)],
    lensBorder: Color(0x99FF6A80),
    liquidHighlight: Color(0xFFFF8A9B),
    liquidDeep: Color(0xFFE0183E),
    buttonFill: Color(0xB3C4122F),
    buttonBorder: Color(0x99FFB3BF),
    shimmer: Color(0xFFFFB3BF),
    chain: [Color(0xFFFF6A80), Color(0xFF8E0F26)],
    chainStroke: Color(0xCCFFB3BF),
    feedbackGradient: [Color(0x66E0183E), Color(0xCC14030A)],
    feedbackBorder: Color(0x99FF6A80),
  ),
  // Night Demon: purple hellfire on black glass
  NebulaTheme.obsidianGlass: NebulaMaterialStyle(
    material: NebulaMaterial.nightDemon,
    accent: Color(0xFF9B5DE5),
    edge: Color(0x809B5DE5),
    surface: Color(0xFF12001F),
    dialogSurface: Color(0xCC0B0314),
    feedbackSurface: Color(0xCC07010E),
    highlight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x449B5DE5), Color(0x14080010)],
    ),
    lens: [Color(0x559B5DE5), Color(0x146A1B9A)],
    lensBorder: Color(0x99B388FF),
    liquidHighlight: Color(0xFFD9B8FF),
    liquidDeep: Color(0xFF6A1B9A),
    buttonFill: Color(0xB36A1B9A),
    buttonBorder: Color(0x99B388FF),
    shimmer: Color(0xFFD9B8FF),
    chain: [Color(0xFF4A2A7A), Color(0xFF0B0314)],
    chainStroke: Color(0xCC9B5DE5),
    feedbackGradient: [Color(0x669B5DE5), Color(0xCC07010E)],
    feedbackBorder: Color(0x999B5DE5),
  ),
  // Godly: burnished gold and divine light
  NebulaTheme.aureateGlass: NebulaMaterialStyle(
    material: NebulaMaterial.godly,
    accent: Color(0xFFE8C547),
    edge: Color(0x80FFE08A),
    surface: Color(0xFF221B0D),
    dialogSurface: Color(0xCC221A0A),
    feedbackSurface: Color(0xCC1A1407),
    highlight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x55F5C542), Color(0x14402C00)],
    ),
    lens: [Color(0x55FFE08A), Color(0x14B8860B)],
    lensBorder: Color(0x99FFE08A),
    liquidHighlight: Color(0xFFFFF2C0),
    liquidDeep: Color(0xFFD4AF37),
    buttonFill: Color(0xB3B8860B),
    buttonBorder: Color(0x99FFE08A),
    shimmer: Color(0xFFFFF2C0),
    chain: [Color(0xFFFFE9A3), Color(0xFF8A6508)],
    chainStroke: Color(0xCCFFF2C0),
    feedbackGradient: [Color(0x66F5C542), Color(0xCC1A1407)],
    feedbackBorder: Color(0x99FFE08A),
  ),
};


// Built-in themes all participate in one material pipeline. The three established
// recipes above remain untouched; the remaining recipes follow their canonical palettes.
NebulaMaterial _materialForTheme(NebulaTheme theme) => switch (theme) {
  NebulaTheme.nosferatuGlass => NebulaMaterial.ruby,
  NebulaTheme.obsidianGlass => NebulaMaterial.nightDemon,
  NebulaTheme.aureateGlass => NebulaMaterial.godly,
  NebulaTheme.forgeGlass => NebulaMaterial.forge,
  NebulaTheme.hermeticGlass => NebulaMaterial.hermetic,
  NebulaTheme.eclipseGlass => NebulaMaterial.eclipse,
  NebulaTheme.solarFlareGlass => NebulaMaterial.solarFlare,
  NebulaTheme.voidGlass => NebulaMaterial.voidGlass,
  NebulaTheme.crimsonGlass => NebulaMaterial.crimson,
  NebulaTheme.neonGlass => NebulaMaterial.neon,
  NebulaTheme.emeraldGlass => NebulaMaterial.emerald,
  NebulaTheme.auroraGlass => NebulaMaterial.aurora,
  NebulaTheme.sapphireGlass => NebulaMaterial.sapphire,
  NebulaTheme.amberGlass => NebulaMaterial.amber,
  NebulaTheme.onyxGlass => NebulaMaterial.onyx,
  NebulaTheme.pearlGlass => NebulaMaterial.pearl,
  NebulaTheme.ivoryGlass => NebulaMaterial.ivory,
  NebulaTheme.imperialGlass => NebulaMaterial.imperial,
  NebulaTheme.aves => NebulaMaterial.onyx,
};

final Map<NebulaTheme, NebulaMaterialStyle> nebulaMaterials = Map.unmodifiable({
  ..._legacyNebulaMaterials,
  for (final entry in nebulaPalettes.entries)
    if (entry.key != NebulaTheme.aves && !_legacyNebulaMaterials.containsKey(entry.key))
      entry.key: NebulaMaterialStyle.fromPalette(entry.value, _materialForTheme(entry.key)),
});


// Custom themes reuse NebulaTheme.aves as their storage identity, so resolve their
// surface treatment separately. Recipes use the supplied palette colors and select
// only geometry/pattern family from the treatment.
const Map<NebulaSurfaceTreatment, NebulaMaterial> _customMaterialByTreatment = {
  NebulaSurfaceTreatment.nosferatuGlass: NebulaMaterial.crimson,
  NebulaSurfaceTreatment.frosted: NebulaMaterial.pearl,
  NebulaSurfaceTreatment.aureateGlass: NebulaMaterial.imperial,
  NebulaSurfaceTreatment.obsidianGlass: NebulaMaterial.voidGlass,
  NebulaSurfaceTreatment.forgeGlass: NebulaMaterial.forge,
  NebulaSurfaceTreatment.hermeticGlass: NebulaMaterial.hermetic,
  NebulaSurfaceTreatment.eclipseGlass: NebulaMaterial.eclipse,
  NebulaSurfaceTreatment.solarFlareGlass: NebulaMaterial.solarFlare,
  NebulaSurfaceTreatment.voidGlass: NebulaMaterial.voidGlass,
  NebulaSurfaceTreatment.crimsonGlass: NebulaMaterial.crimson,
  NebulaSurfaceTreatment.neonGlass: NebulaMaterial.neon,
  NebulaSurfaceTreatment.emeraldGlass: NebulaMaterial.emerald,
  NebulaSurfaceTreatment.auroraGlass: NebulaMaterial.aurora,
  NebulaSurfaceTreatment.sapphireGlass: NebulaMaterial.sapphire,
  NebulaSurfaceTreatment.amberGlass: NebulaMaterial.amber,
  NebulaSurfaceTreatment.onyxGlass: NebulaMaterial.onyx,
  NebulaSurfaceTreatment.pearlGlass: NebulaMaterial.pearl,
  NebulaSurfaceTreatment.ivoryGlass: NebulaMaterial.ivory,
  NebulaSurfaceTreatment.imperialGlass: NebulaMaterial.imperial,
};

/// Resolves a material recipe from a palette. Built-in palettes preserve their
/// hand-authored materials; custom palettes derive colors from their own data.
NebulaMaterialStyle? nebulaMaterialStyleForPalette(NebulaPalette palette) {
  final builtIn = nebulaMaterials[palette.theme];
  if (builtIn != null) return builtIn;
  if (palette.treatment == NebulaSurfaceTreatment.flat) return null;
  final material = _customMaterialByTreatment[palette.treatment];
  if (material == null) return null;
  return NebulaMaterialStyle.fromPalette(palette, material);
}
