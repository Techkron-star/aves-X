// Nebula Engine: the umbrella of the visual themes of Aves-X.
//
// Phase 1 themes only change the palette and the surface treatment, reusing the Nosferatu Glass base.
// Phase 2 themes add their own shaders and animations (not implemented yet).
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
  };

  // 1: palettes and surfaces, no own effects. 2: own shaders/animations.
  int get phase => switch (this) {
    .aves || .nosferatuGlass || .obsidianGlass || .aureateGlass => 1,
    .forgeGlass || .hermeticGlass => 2,
  };

  // only phase 1 themes can be offered by the selector for now
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
