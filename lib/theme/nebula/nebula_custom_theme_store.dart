import 'dart:convert';
import 'dart:io';

import 'package:aves/theme/nebula/nebula_custom_theme.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Almacenamiento de temas Nebula personalizados.
//
// Los temas se guardan como archivos JSON en el directorio de archivos de la
// app (`<filesDir>/nebula_themes/`). Cada tema es un archivo independiente
// llamado `<id>.json`. El tema activo se recuerda en la preferencia
// `nebula_custom_theme_key` (en el módulo de display).
//
// Los temas integrados (Nosferatu, Obsidian, etc.) no se almacenan aquí: vienen
// de `nebula_palettes.dart`. Esta tienda solo gestiona temas creados por el
// usuario mediante importación o edición de plantilla.
class NebulaCustomThemeStore {
  static const _folderName = 'nebula_themes';
  static const _extension = '.json';

  Directory? _dir;
  Directory get _themesDir {
    _dir ??= Directory(p.join(await _localPath(), _folderName));
    return _dir!;
  }

  Future<String> _localPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Carga todos los temas personalizados disponibles.
  Future<List<CustomNebulaTheme>> loadAll() async {
    final dir = _themesDir;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      return const <CustomNebulaTheme>[];
    }

    final themes = <CustomNebulaTheme>[];
    for (final entity in await dir.list()) {
      if (entity is File && entity.path.endsWith(_extension)) {
        try {
          final json = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
          themes.add(CustomNebulaTheme.fromJson(json));
        } catch (_) {
          // Ignorar archivos corruptos: no deben bloquear la carga de los demás
        }
      }
    }

    // Ordenar alfabéticamente por nombre
    themes.sort((a, b) => a.name.compareTo(b.name));
    return themes;
  }

  /// Guarda un tema personalizado, sobrescribiendo si ya existe con ese id.
  Future<void> save(CustomNebulaTheme theme) async {
    final dir = _themesDir;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File(p.join(dir.path, '${theme.id}$_extension'));
    await file.writeAsString(jsonEncode(theme.toJson()), flush: true);
  }

  /// Elimina un tema personalizado por su id.
  Future<void> delete(String id) async {
    final file = File(p.join(_themesDir.path, '$id$_extension'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Exporta un tema a un string JSON listo para compartir/guardar.
  static String exportToJson(CustomNebulaTheme theme) => jsonEncode(theme.toJson());

  /// Importa un tema desde un string JSON, validando el esquema.
  /// Lanza [FormatException] si el JSON es inválido.
  static CustomNebulaTheme importFromJson(String json) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return CustomNebulaTheme.fromJson(decoded);
  }

  /// Devuelve la plantilla base para crear un nuevo tema personalizado.
  static String get template => kCustomNebulaThemeTemplate;
}
