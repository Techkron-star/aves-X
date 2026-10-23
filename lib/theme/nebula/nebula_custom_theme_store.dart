import 'dart:convert';

import 'package:aves/theme/nebula/nebula_custom_theme.dart';

// Storage serialization for user-created Nebula themes.
//
// Themes are persisted as a single JSON list in the app preferences (see
// `CustomNebulaThemeSettings`), instead of one file per theme. This keeps the
// import/export format identical to a standalone `.json` file, but avoids the
// extra `path_provider` plugin, file permissions and asynchronous file IO.
class NebulaCustomThemeStore {
  // Preference key holding the JSON list of custom themes.
  static const preferenceKey = 'nebula_custom_themes';

  static int _compare(CustomNebulaTheme a, CustomNebulaTheme b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());

  // Serializes every theme into the JSON list stored in the preferences.
  static String encodeAll(List<CustomNebulaTheme> themes) => jsonEncode(themes.map((v) => v.toJson()).toList());

  // Parses the JSON list stored in the preferences, skipping corrupted entries
  // so that a single bad theme never hides the rest.
  static List<CustomNebulaTheme> decodeAll(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final themes = <CustomNebulaTheme>[];
      for (final item in decoded) {
        if (item is Map) {
          try {
            themes.add(CustomNebulaTheme.fromJson(item.cast<String, dynamic>()));
          } catch (_) {
            // ignore corrupted entry
          }
        }
      }
      themes.sort(_compare);
      return themes;
    } catch (_) {
      return const [];
    }
  }

  // Adds [theme] to [themes], replacing the entry with the same id.
  static List<CustomNebulaTheme> upsert(List<CustomNebulaTheme> themes, CustomNebulaTheme theme) {
    final result = themes.where((v) => v.id != theme.id).toList()..add(theme);
    result.sort(_compare);
    return result;
  }

  // Removes the theme with [id] from [themes].
  static List<CustomNebulaTheme> remove(List<CustomNebulaTheme> themes, String id) => themes.where((v) => v.id != id).toList();

  // Pretty printed JSON for clipboard export.
  static String exportToJson(CustomNebulaTheme theme) => const JsonEncoder.withIndent('  ').convert(theme.toJson());

  // Parses an exported theme. Throws [FormatException] when the payload is not
  // valid JSON or does not match the expected schema.
  static CustomNebulaTheme importFromJson(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map) {
      throw const FormatException('Theme JSON must be an object');
    }
    return CustomNebulaTheme.fromJson(decoded.cast<String, dynamic>());
  }

  // Base template offered when creating a new custom theme.
  static String get template => kCustomNebulaThemeTemplate;
}
