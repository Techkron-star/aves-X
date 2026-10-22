import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_custom_theme.dart';
import 'package:collection/collection.dart';
import 'package:aves/theme/nebula/nebula_custom_theme_store.dart';
import 'package:aves/theme/nebula/nebula_palette.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/foundation.dart';

// Ajustes de temas Nebula personalizados.
//
// Los temas personalizados se almacenan como archivos JSON en el directorio de
// archivos de la app (<filesDir>/nebula_themes/). El tema personalizado activo
// se recuerda en `SettingKeys.nebulaCustomThemeKey`.
//
// Los temas integrados (Nosferatu, Obsidian, etc.) se definen en
// `nebula_palettes.dart` y no se almacenan aquí.
mixin CustomNebulaThemeSettings on SettingsAccess {
  NebulaCustomThemeStore get _store => _customNebulaThemeStore;
  final NebulaCustomThemeStore _customNebulaThemeStore = NebulaCustomThemeStore();

  /// Tema personalizado actualmente seleccionado, o null si se usa un tema integrado.
  CustomNebulaTheme? get customNebulaTheme {
    final id = getString(SettingKeys.nebulaCustomThemeKey);
    if (id == null) return null;
    return _loadedThemes.firstWhereOrNull((t) => t.id == id);
  }

  set customNebulaTheme(CustomNebulaTheme? newValue) {
    set(SettingKeys.nebulaCustomThemeKey, newValue?.id);
    notifyListeners();
  }

  /// Carga todos los temas personalizados disponibles desde disco.
  Future<List<CustomNebulaTheme>> loadCustomThemes() async {
    return _store.loadAll();
  }

  /// Guarda un tema personalizado y lo activa.
  Future<void> saveCustomTheme(CustomNebulaTheme theme) async {
    await _store.save(theme);
    customNebulaTheme = theme;
    notifyListeners();
  }

  /// Elimina un tema personalizado por su id. Si es el activo, se desactiva.
  Future<void> deleteCustomTheme(String id) async {
    await _store.delete(id);
    if (customNebulaTheme?.id == id) {
      customNebulaTheme = null;
    }
    notifyListeners();
  }

  /// Exporta un tema a un string JSON listo para compartir.
  String exportCustomTheme(CustomNebulaTheme theme) => NebulaCustomThemeStore.exportToJson(theme);

  /// Importa un tema desde un string JSON y lo guarda.
  /// Lanza [FormatException] si el JSON es inválido.
  Future<void> importCustomTheme(String json) async {
    final theme = NebulaCustomThemeStore.importFromJson(json);
    await saveCustomTheme(theme);
  }

  /// Devuelve la plantilla base para crear un nuevo tema personalizado.
  String get customNebulaThemeTemplate => NebulaCustomThemeStore.template;

  // Cache de temas cargados en esta sesión
  List<CustomNebulaTheme> _loadedThemes = [];

  /// Recarga la caché de temas desde disco.
  Future<void> refreshCustomThemes() async {
    _loadedThemes = await _store.loadAll();
    // Si el tema activo ya no existe, desactivarlo
    final activeId = getString(SettingKeys.nebulaCustomThemeKey);
    if (activeId != null && _loadedThemes.none((t) => t.id == activeId)) {
      customNebulaTheme = null;
    }
  }
}

/// Tema Nebula efectivo: puede ser un tema integrado o uno personalizado.
abstract class EffectiveNebulaTheme {
  /// Paleta a usar para renderizar. Los temas personalizados llevan sus propios
  /// colores; los temas integrados usan `nebulaPalettes`.
  NebulaPalette get palette;

  /// Tratamiento de superficie del tema.
  NebulaSurfaceTreatment get treatment;

  /// Nombre legible del tema.
  String get displayName;
}

/// Adapter que expone un [CustomNebulaTheme] como [EffectiveNebulaTheme].
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
