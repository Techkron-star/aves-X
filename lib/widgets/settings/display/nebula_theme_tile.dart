import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves/widgets/common/basic/feature_sticker.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves_model/aves_model.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// Selector del tema Nebula (Ajustes → Pantalla).
//
// Muestra una "pill" por tema: las de Fase 1 (Aves, Nosferatu Glass, Obsidian Glass, Aureate Glass)
// están habilitadas, las de Fase 2 (Forge Glass, Hermetic Glass) están deshabilitadas con un tooltip
// "Próximamente: Fase 2".
// Cada pill lleva su pegatina de función (newFeature para Fase 1, experimental para Fase 2),
// el nombre y una descripción corta.
//
// Escribe `SettingKeys.nebulaThemeKey` vía `DisplaySettings.nebulaTheme`; el `Selector` reconstruye
// el tile cuando cambia la selección.
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
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  dense: true,
                  title: Text(title(context) ?? ''),
                  subtitle: Text(l10n.settingsNebulaThemeSubtitle),
                  trailing: Text(
                    _themeName(context, theme),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: NebulaTheme.values.map((t) {
                    final enabled = t.isPhase1;
                    return _NebulaThemePill(
                      theme: t,
                      selected: theme == t,
                      enabled: enabled,
                      onSelected: enabled ? () => settings.nebulaTheme = t : null,
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      );
}

// Una opción de tema: nombre, descripción corta, pegatina de función y estado (habilitado / Fase 2).
class _NebulaThemePill extends StatelessWidget {
  final NebulaTheme theme;
  final bool selected;
  final bool enabled;
  final VoidCallback? onSelected;

  const _NebulaThemePill({
    required this.theme,
    required this.selected,
    required this.enabled,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final kind = theme.isPhase1 ? StickerKind.newFeature : StickerKind.experimental;
    final name = _themeName(context, theme);
    final desc = _themeDesc(context, theme);
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: Tooltip(
        message: enabled ? null : l10n.nebulaComingSoonPhase2,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? scheme.surfaceContainer : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FeatureSticker(kind: kind),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: enabled ? null : scheme.onSurface.withValues(alpha: .5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 11,
                        color: enabled ? scheme.onSurfaceVariant : scheme.onSurface.withValues(alpha: .5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _themeName(BuildContext context, NebulaTheme theme) => switch (theme) {
      NebulaTheme.aves => context.l10n.nebulaThemeAves,
      NebulaTheme.nosferatuGlass => context.l10n.nebulaThemeNosferatuGlass,
      NebulaTheme.obsidianGlass => context.l10n.nebulaThemeObsidianGlass,
      NebulaTheme.aureateGlass => context.l10n.nebulaThemeAureateGlass,
      NebulaTheme.forgeGlass => context.l10n.nebulaThemeForgeGlass,
      NebulaTheme.hermeticGlass => context.l10n.nebulaThemeHermeticGlass,
    };

String _themeDesc(BuildContext context, NebulaTheme theme) => switch (theme) {
      NebulaTheme.aves => context.l10n.nebulaThemeAvesDesc,
      NebulaTheme.nosferatuGlass => context.l10n.nebulaThemeNosferatuGlassDesc,
      NebulaTheme.obsidianGlass => context.l10n.nebulaThemeObsidianGlassDesc,
      NebulaTheme.aureateGlass => context.l10n.nebulaThemeAureateGlassDesc,
      NebulaTheme.forgeGlass => context.l10n.nebulaThemeForgeGlassDesc,
      NebulaTheme.hermeticGlass => context.l10n.nebulaThemeHermeticGlassDesc,
    };
