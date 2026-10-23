// Nebula Engine: the umbrella of the visual themes of Aves-X.
//
// Every Nebula theme owns a palette and a surface treatment; phase 2 themes also add a dedicated visual effect.
enum NebulaTheme {
  // default Aves theme: delegates to the legacy light/dark/black themes
  aves,
  // Nosferatu Glass: the former Bat-Glass ruby crystal theme
  nosferatuGlass,
  // Obsidian Glass: the former Night Demon theme
  obsidianGlass,
  // Aureate Glass: the former Godly theme
  aureateGlass,
  // Forge Glass: the former Cosmic Forge theme (phase 2 effects)
  forgeGlass,
  // Hermetic Glass: the former Hermetisc theme (phase 2 effects)
  hermeticGlass,
  // Eclipse Glass: deep midnight blue surfaces with electric cyan crystal (phase 2 effects)
  eclipseGlass,
  // Solar Flare Glass: molten orange on black with gold crystal (phase 2 effects)
  solarFlareGlass,
  // Void Glass: graphite black surfaces with neon green crystal (phase 2 effects)
  voidGlass,
  // Crimson Glass: burgundy black surfaces with dark red crystal (phase 2 effects)
  crimsonGlass,
  // Neon Glass: hot pink and electric blue crystal on black (phase 2 effects)
  neonGlass,
  // Emerald Glass: deep forest emerald crystal with gold veins (phase 2 effects)
  emeraldGlass,
  // Aurora Glass: polar green and ice blue dancing over black like northern lights (phase 2 effects)
  auroraGlass,
  // Sapphire Glass: deep royal sapphire with brilliant cyan highlights (phase 2 effects)
  sapphireGlass,
  // Amber Glass: warm fossil amber with honey orange and gold tones (phase 2 effects)
  amberGlass,
  // Onyx Glass: pure black with graphite grey and soft white — minimalist monochrome (phase 2 effects)
  onyxGlass,
  // Pearl Glass: soft pearl white with shell pink and subtle gold — elegant and luminous (phase 2 effects)
  pearlGlass,
  // Ivory Glass: warm ivory cream with champagne gold accents — classic elegance (phase 2 effects)
  ivoryGlass,
  // Imperial Glass: gunmetal steel, brass rivets, parchment and aquila gold — the Adeptus aesthetic (phase 2 effects)
  imperialGlass,
}

extension NebulaThemeInfo on NebulaTheme {
  // Stable identifier, persisted in the settings. Never rename it.
  String get id => switch (this) {
    .aves => 'aves',
    .nosferatuGlass => 'nosferatu_glass',
    .obsidianGlass => 'obsidian_glass',
    .aureateGlass => 'aureate_glass',
    .forgeGlass => 'forge_glass',
    .hermeticGlass => 'hermetic_glass',
    .eclipseGlass => 'eclipse_glass',
    .solarFlareGlass => 'solar_flare_glass',
    .voidGlass => 'void_glass',
    .crimsonGlass => 'crimson_glass',
    .neonGlass => 'neon_glass',
    .emeraldGlass => 'emerald_glass',
    .auroraGlass => 'aurora_glass',
    .sapphireGlass => 'sapphire_glass',
    .amberGlass => 'amber_glass',
    .onyxGlass => 'onyx_glass',
    .pearlGlass => 'pearl_glass',
    .ivoryGlass => 'ivory_glass',
    .imperialGlass => 'imperial_glass',
  };

  // 1: foundational palette/material themes. 2: dedicated visual-effect themes.
  int get phase => switch (this) {
    .aves || .nosferatuGlass => 1,
    .obsidianGlass || .aureateGlass || .forgeGlass || .hermeticGlass || .eclipseGlass || .solarFlareGlass || .voidGlass || .crimsonGlass || .neonGlass || .emeraldGlass || .auroraGlass || .sapphireGlass || .amberGlass || .onyxGlass || .pearlGlass || .ivoryGlass || .imperialGlass => 2,
  };

  // Retained as the phase label used by selector stickers; it no longer controls availability.
  bool get isPhase1 => phase == 1;
}

// Legacy ids kept for installs that predate the Nosferatu Glass rename, so a stored theme is never lost.
const Map<String, NebulaTheme> _legacyNebulaThemeIds = {
  'bat_glass': NebulaTheme.nosferatuGlass,
  'night_demon': NebulaTheme.obsidianGlass,
  'godly': NebulaTheme.aureateGlass,
  'cosmic_forge': NebulaTheme.forgeGlass,
  'hermetisc': NebulaTheme.hermeticGlass,
};

// Parses a persisted theme id, or returns null when the value is unknown (old, corrupted or removed theme).
NebulaTheme? nebulaThemeFromId(String? id) {
  if (id == null) return null;
  for (final theme in NebulaTheme.values) {
    if (theme.id == id) return theme;
  }
  return _legacyNebulaThemeIds[id];
}
