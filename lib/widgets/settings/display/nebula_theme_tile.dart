import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tiles/sub_page.dart';
import 'package:aves/widgets/settings/nebula/nebula_tab.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';

// Entrada de Ajustes → Pantalla → Tema Nebula.
//
// Ya no dibuja el selector aquí: abre la pestaña Nebula (`NebulaTab`), que reúne
// la vista galáctica y el selector de tema con sus descripciones.
// El tile sigue leyendo `SettingKeys.nebulaThemeKey`, así que la búsqueda de
// ajustes y el resumen del valor actual funcionan igual que antes.
class SettingsTileDisplayNebulaTheme extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.nebulaThemeKey];

  @override
  String title(BuildContext context) => context.l10n.settingsNebulaTheme;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    title: title,
    subtitle: (context) => Text(context.l10n.settingsNebulaThemeSubtitle),
    routeName: NebulaTab.routeName,
    builder: (context) => const NebulaTab(),
  );
}
