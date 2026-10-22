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
enum NebulaMaterial { ruby, nightDemon, godly }

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

  // Corner language of the floating glass surfaces: every material has its own silhouette.
  ShapeBorder shape(double radius, BorderSide side) => switch (material) {
    NebulaMaterial.ruby => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: side),
    // cut corners, like a shard of volcanic glass
    NebulaMaterial.nightDemon => BeveledRectangleBorder(borderRadius: BorderRadius.circular(radius * .75), side: side),
    // soft superellipse, like a halo
    NebulaMaterial.godly => ContinuousRectangleBorder(borderRadius: BorderRadius.circular(radius * 1.6), side: side),
  };

  // same as [shape], rounded on the top corners only (bottom sheets)
  ShapeBorder topShape(double radius, BorderSide side) => switch (material) {
    NebulaMaterial.ruby => RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius)), side: side),
    NebulaMaterial.nightDemon => BeveledRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * .75)), side: side),
    NebulaMaterial.godly => ContinuousRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * 1.6)), side: side),
  };
}

// Themes without an entry here have no glass material (the default Aves theme, the phase 2 themes).
// The ruby values are an exact copy of the constants that used to be hard-coded for Bat-Glass,
// so that Nosferatu Glass does not change in any way.
const Map<NebulaTheme, NebulaMaterialStyle> nebulaMaterials = {
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
