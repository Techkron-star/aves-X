import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/nebula/nebula_tab.dart';
import 'package:aves/widgets/settings/nebula/nebula_theme_selector.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

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
  Widget build(BuildContext context) => Selector<Settings, NebulaTheme>(
    selector: (context, s) => s.nebulaTheme,
    builder: (context, theme, _) {
      final l10n = context.l10n;
      return ListTile(
        title: Text(title(context)),
        subtitle: Text(l10n.nebulaTabTileSubtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nebulaThemeName(context, theme),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
        onTap: () => Navigator.maybeOf(context)?.push(
          MaterialPageRoute(
            settings: const RouteSettings(name: NebulaTab.routeName),
            builder: (context) => const NebulaTab(),
          ),
        ),
      );
    },
  );
}
