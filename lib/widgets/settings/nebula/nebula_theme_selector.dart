import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves/widgets/common/basic/feature_sticker.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// Selector del tema Nebula.
//
// Muestra una "pill" por tema: las de Fase 1 (Aves, Nosferatu Glass, Obsidian Glass, Aureate Glass)
// están habilitadas, las de Fase 2 (Forge Glass, Hermetic Glass) están deshabilitadas con un tooltip
// "Próximamente: Fase 2".
// Cada pill lleva su pegatina de función (newFeature para Fase 1, experimental para Fase 2),
// el nombre y una descripción corta.
//
// Escribe `SettingKeys.nebulaThemeKey` vía `DisplaySettings.nebulaTheme`; el `Selector` reconstruye
// el selector cuando cambia la selección.
// Vive aquí (y no en el tile) porque lo usan tanto la entrada de Ajustes como la pestaña Nebula.

class NebulaThemeSelector extends StatelessWidget {
  const NebulaThemeSelector({super.key});

  @override
  Widget build(BuildContext context) => Selector<Settings, NebulaTheme>(
    selector: (context, s) => s.nebulaTheme,
    builder: (context, theme, _) => Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final t in NebulaTheme.values)
          NebulaThemePill(
            theme: t,
            selected: theme == t,
            enabled: t.isPhase1,
            onSelected: t.isPhase1 ? () => settings.nebulaTheme = t : null,
          ),
      ],
    ),
  );
}

/// Una opción de tema: nombre, descripción corta, pegatina de función y estado (habilitado / Fase 2).
class NebulaThemePill extends StatelessWidget {
  final NebulaTheme theme;
  final bool selected;
  final bool enabled;
  final VoidCallback? onSelected;

  const NebulaThemePill({
    super.key,
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

    final content = InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.surfaceContainerHighest.withValues(alpha: .9) : scheme.surfaceContainerLow.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: .6),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: .35),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FeatureSticker(kind: kind),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nebulaThemeName(context, theme),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: enabled ? scheme.onSurface : scheme.onSurface.withValues(alpha: .5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nebulaThemeDescription(context, theme),
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
    );

    // Never build a `Tooltip` without a message: `TooltipState` evaluates `richMessage!`
    // when `message` is null, which throws in release and renders a gray `ErrorWidget`.
    // Only Phase 2 pills need a tooltip, so enabled pills skip it entirely.
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: enabled ? content : Tooltip(message: l10n.nebulaComingSoonPhase2, child: content),
    );
  }
}

String nebulaThemeName(BuildContext context, NebulaTheme theme) => switch (theme) {
  NebulaTheme.aves => context.l10n.nebulaThemeAves,
  NebulaTheme.nosferatuGlass => context.l10n.nebulaThemeNosferatuGlass,
  NebulaTheme.obsidianGlass => context.l10n.nebulaThemeObsidianGlass,
  NebulaTheme.aureateGlass => context.l10n.nebulaThemeAureateGlass,
  NebulaTheme.forgeGlass => context.l10n.nebulaThemeForgeGlass,
  NebulaTheme.hermeticGlass => context.l10n.nebulaThemeHermeticGlass,
  NebulaTheme.eclipseGlass => context.l10n.nebulaThemeEclipseGlass,
  NebulaTheme.solarFlareGlass => context.l10n.nebulaThemeSolarFlareGlass,
  NebulaTheme.voidGlass => context.l10n.nebulaThemeVoidGlass,
  NebulaTheme.crimsonGlass => context.l10n.nebulaThemeCrimsonGlass,
  NebulaTheme.neonGlass => context.l10n.nebulaThemeNeonGlass,
  NebulaTheme.emeraldGlass => context.l10n.nebulaThemeEmeraldGlass,
};

String nebulaThemeDescription(BuildContext context, NebulaTheme theme) => switch (theme) {
  NebulaTheme.aves => context.l10n.nebulaThemeAvesDesc,
  NebulaTheme.nosferatuGlass => context.l10n.nebulaThemeNosferatuGlassDesc,
  NebulaTheme.obsidianGlass => context.l10n.nebulaThemeObsidianGlassDesc,
  NebulaTheme.aureateGlass => context.l10n.nebulaThemeAureateGlassDesc,
  NebulaTheme.forgeGlass => context.l10n.nebulaThemeForgeGlassDesc,
  NebulaTheme.hermeticGlass => context.l10n.nebulaThemeHermeticGlassDesc,
  NebulaTheme.eclipseGlass => context.l10n.nebulaThemeEclipseGlassDesc,
  NebulaTheme.solarFlareGlass => context.l10n.nebulaThemeSolarFlareGlassDesc,
  NebulaTheme.voidGlass => context.l10n.nebulaThemeVoidGlassDesc,
  NebulaTheme.crimsonGlass => context.l10n.nebulaThemeCrimsonGlassDesc,
  NebulaTheme.neonGlass => context.l10n.nebulaThemeNeonGlassDesc,
  NebulaTheme.emeraldGlass => context.l10n.nebulaThemeEmeraldGlassDesc,
};
