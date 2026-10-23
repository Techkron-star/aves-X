import 'package:aves/theme/nebula/nebula_custom_theme.dart';
import 'package:aves/theme/nebula/nebula_custom_theme_store.dart';
import 'package:aves/theme/nebula/nebula_palette.dart';
import 'package:aves_model/aves_model.dart';
import 'package:collection/collection.dart';

// Settings for the custom Nebula themes.
//
// Every custom theme is stored as one JSON object inside a single JSON list
// kept in the app preferences (`nebula_custom_themes`). The theme currently in
// use is remembered by `SettingKeys.nebulaCustomThemeKey`.
//
// Built-in themes (Nosferatu, Obsidian, etc.) are defined in
// `nebula_palettes.dart` and are never stored here.
mixin CustomNebulaThemeSettings on SettingsAccess {
  // Raw JSON last decoded, to avoid reparsing on every widget rebuild.
  String? _customThemesRaw;
  List<CustomNebulaTheme> _customThemes = const [];

  /// All custom themes available on this device, sorted by name.
  List<CustomNebulaTheme> get customNebulaThemes {
    final raw = getString(NebulaCustomThemeStore.preferenceKey);
    if (raw != _customThemesRaw) {
      _customThemesRaw = raw;
      _customThemes = NebulaCustomThemeStore.decodeAll(raw);
    }
    return _customThemes;
  }

  /// Custom theme currently selected, or null when a built-in theme is in use.
  CustomNebulaTheme? get customNebulaTheme {
    final id = getString(SettingKeys.nebulaCustomThemeKey);
    if (id == null) return null;
    return customNebulaThemes.firstWhereOrNull((t) => t.id == id);
  }

  set customNebulaTheme(CustomNebulaTheme? newValue) => set(SettingKeys.nebulaCustomThemeKey, newValue?.id);

  /// Forces the cached list to be read again from the preferences.
  Future<void> refreshCustomThemes() async {
    _customThemesRaw = null;
    final themes = customNebulaThemes;
    final activeId = getString(SettingKeys.nebulaCustomThemeKey);
    if (activeId != null && themes.none((t) => t.id == activeId)) {
      // the active theme was removed or its id is no longer valid
      customNebulaTheme = null;
    }
  }

  /// All custom themes, read from the preferences on demand.
  Future<List<CustomNebulaTheme>> loadCustomThemes() async => customNebulaThemes;

  /// Saves a custom theme and makes it the active one.
  Future<void> saveCustomTheme(CustomNebulaTheme theme) async {
    _write(NebulaCustomThemeStore.upsert(customNebulaThemes, theme));
    customNebulaTheme = theme;
  }

  /// Deletes a custom theme by id, deactivating it when it was the active one.
  Future<void> deleteCustomTheme(String id) async {
    _write(NebulaCustomThemeStore.remove(customNebulaThemes, id));
    if (getString(SettingKeys.nebulaCustomThemeKey) == id) {
      customNebulaTheme = null;
    }
  }

  /// Imports a theme from a JSON string and saves it.
  /// Throws [FormatException] when the payload is invalid.
  Future<void> importCustomTheme(String json) async {
    final theme = NebulaCustomThemeStore.importFromJson(json);
    await saveCustomTheme(theme);
  }

  /// Exports a theme to a JSON string ready to be shared or stored.
  String exportCustomTheme(CustomNebulaTheme theme) => NebulaCustomThemeStore.exportToJson(theme);

  /// Base template offered when creating a new custom theme.
  String get customNebulaThemeTemplate => NebulaCustomThemeStore.template;

  void _write(List<CustomNebulaTheme> themes) {
    final raw = NebulaCustomThemeStore.encodeAll(themes);
    _customThemesRaw = raw;
    _customThemes = themes;
    set(NebulaCustomThemeStore.preferenceKey, raw);
  }
}

/// Nebula theme actually applied: either a built-in theme or a custom one.
abstract class EffectiveNebulaTheme {
  /// Palette used for rendering. Custom themes carry their own colors, while
  /// built-in themes use `nebulaPalettes`.
  NebulaPalette get palette;

  /// Surface treatment of the theme.
  NebulaSurfaceTreatment get treatment;

  /// Human readable theme name.
  String get displayName;
}

/// Adapter exposing a [CustomNebulaTheme] as an [EffectiveNebulaTheme].
class CustomNebulaThemeAdapter implements EffectiveNebulaTheme {
  final CustomNebulaTheme theme;

  CustomNebulaThemeAdapter(this.theme);

  @override
  NebulaPalette get palette => theme.toPalette();

  @override
  NebulaSurfaceTreatment get treatment => theme.treatment;

  @override
  String get displayName => theme.name;
}
