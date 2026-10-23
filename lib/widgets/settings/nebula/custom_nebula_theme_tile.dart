import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tiles/sub_page.dart';
import 'package:aves/widgets/settings/nebula/custom_nebula_theme_page.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';

// Entrada de Ajustes → Nebula Engine → Temas personalizados.
// Permite importar, exportar, editar y eliminar temas Nebula creados por el usuario.
class SettingsTileCustomNebulaTheme extends SettingsTile {
  SettingsTileCustomNebulaTheme();

  @override
  List<String> get settingKeys => [SettingKeys.nebulaCustomThemeKey];

  @override
  String title(BuildContext context) => context.l10n.settingsCustomNebulaTheme;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    title: title,
    subtitle: (context) => Text(context.l10n.settingsCustomNebulaThemeSubtitle),
    routeName: CustomNebulaThemePage.routeName,
    builder: (context) => const CustomNebulaThemePage(),
  );
}
