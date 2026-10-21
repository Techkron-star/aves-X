// Nebula Engine: the umbrella of the visual themes of Aves-X.
//
// Phase 1 themes only change the palette and the surface treatment, reusing the Bat-Glass base.
// Phase 2 themes add their own shaders and animations (not implemented yet).
enum NebulaTheme {
  // default Aves theme: delegates to the legacy light/dark/black themes
  aves,
  batGlass,
  nightDemon,
  godly,
  cosmicForge,
  hermetisc,
}

extension NebulaThemeInfo on NebulaTheme {
  // Stable identifier, persisted in the settings. Never rename it.
  String get id => switch (this) {
    .aves => 'aves',
    .batGlass => 'bat_glass',
    .nightDemon => 'night_demon',
    .godly => 'godly',
    .cosmicForge => 'cosmic_forge',
    .hermetisc => 'hermetisc',
  };

  // 1: palettes and surfaces, no own effects. 2: own shaders/animations.
  int get phase => switch (this) {
    .aves || .batGlass || .nightDemon || .godly => 1,
    .cosmicForge || .hermetisc => 2,
  };

  // only phase 1 themes can be offered by the selector for now
  bool get isPhase1 => phase == 1;
}

// Parses a persisted theme id, or returns null when the value is unknown (old, corrupted or removed theme).
NebulaTheme? nebulaThemeFromId(String? id) {
  if (id == null) return null;
  for (final theme in NebulaTheme.values) {
    if (theme.id == id) return theme;
  }
  return null;
}
