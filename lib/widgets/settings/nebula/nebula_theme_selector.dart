import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_custom_theme.dart';
import 'package:aves/theme/nebula/nebula_palettes.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves/widgets/common/basic/feature_sticker.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// Selector del tema Nebula.
//
// Muestra una "pill" por tema. Las 19 opciones están disponibles; las de Fase 2
// conservan la pegatina experimental, pero ya no están bloqueadas en el selector.
// Cada pill lleva su pegatina de función (newFeature para Fase 1, experimental para Fase 2),
// el nombre y una descripción corta.
//
// Escribe `SettingKeys.nebulaThemeKey` vía `DisplaySettings.nebulaTheme`; el `Selector` reconstruye
// el selector cuando cambia la selección.
// Vive aquí (y no en el tile) porque lo usan tanto la entrada de Ajustes como la pestaña Nebula.

class NebulaThemeSelector extends StatelessWidget {
  const NebulaThemeSelector({super.key});

  @override
  Widget build(BuildContext context) => Selector<Settings, (NebulaTheme, CustomNebulaTheme?)>(
    selector: (context, s) => (s.nebulaTheme, s.customNebulaTheme),
    builder: (context, selection, _) {
      final (theme, customTheme) = selection;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final t in NebulaTheme.values)
            NebulaThemePill(
              theme: t,
              selected: customTheme == null && theme == t,
              enabled: true,
              onSelected: () {
                settings.customNebulaTheme = null;
                settings.nebulaTheme = t;
              },
            ),
        ],
      );
    },
  );
}

/// Una opción de tema: nombre, descripción corta y pegatina de función.
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
    final palette = nebulaPaletteFor(theme);
    // Aves also gets a true miniature; only the three established glass identities
    // keep their original, hand-authored selector treatment.
    final preview = theme != NebulaTheme.nosferatuGlass &&
        theme != NebulaTheme.obsidianGlass &&
        theme != NebulaTheme.aureateGlass;
    final previewOnSurface = theme == NebulaTheme.aves ? const Color(0xFF211A22) : scheme.onSurface;
    final previewOnSurfaceVariant = theme == NebulaTheme.aves ? const Color(0xFF625563) : scheme.onSurfaceVariant;
    final kind = theme.isPhase1 ? StickerKind.newFeature : StickerKind.experimental;
    final rimColor = selected ? (preview ? palette.accent : scheme.primary) : (preview ? palette.outlineVariant : scheme.outlineVariant);
    final surfaceDecoration = preview
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.surfaceContainerHighest.withValues(alpha: selected ? .98 : .82),
                palette.surfaceContainerLow.withValues(alpha: .96),
                palette.surfaceContainerLowest.withValues(alpha: .98),
              ],
              stops: const [0, .48, 1],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: rimColor.withValues(alpha: selected ? 1 : .76), width: selected ? 2 : 1),
            boxShadow: selected
                ? [BoxShadow(color: palette.glow.withValues(alpha: .32), blurRadius: 22, spreadRadius: -3)]
                : [BoxShadow(color: palette.glow.withValues(alpha: .08), blurRadius: 9, spreadRadius: -5)],
          )
        : BoxDecoration(
            color: selected ? scheme.surfaceContainerHighest.withValues(alpha: .9) : scheme.surfaceContainerLow.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: .6),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: scheme.primary.withValues(alpha: .35), blurRadius: 18, spreadRadius: 1)]
                : null,
          );

    final content = InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: surfaceDecoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (preview)
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-.38, -.48),
                    colors: [
                      palette.crystalBody.first,
                      palette.accent,
                      palette.surfaceContainerLowest,
                    ],
                    stops: const [0, .42, 1],
                  ),
                  border: Border.all(color: palette.crystalEdge, width: 1),
                  boxShadow: [
                    BoxShadow(color: palette.glow.withValues(alpha: selected ? .42 : .24), blurRadius: selected ? 12 : 7, spreadRadius: -2),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.auto_awesome, size: 14, color: palette.crystalBody.first),
                ),
              ),
            if (preview) const SizedBox(width: 10),
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
                    color: enabled ? (preview ? previewOnSurface : scheme.onSurface) : scheme.onSurface.withValues(alpha: .5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nebulaThemeDescription(context, theme),
                  style: TextStyle(
                    fontSize: 11,
                    color: enabled ? (preview ? previewOnSurfaceVariant : scheme.onSurfaceVariant) : scheme.onSurface.withValues(alpha: .5),
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
    // The tooltip remains available if a theme is deliberately disabled in a future release.
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
  NebulaTheme.auroraGlass => context.l10n.nebulaThemeAuroraGlass,
  NebulaTheme.sapphireGlass => context.l10n.nebulaThemeSapphireGlass,
  NebulaTheme.amberGlass => context.l10n.nebulaThemeAmberGlass,
  NebulaTheme.onyxGlass => context.l10n.nebulaThemeOnyxGlass,
  NebulaTheme.pearlGlass => context.l10n.nebulaThemePearlGlass,
  NebulaTheme.ivoryGlass => context.l10n.nebulaThemeIvoryGlass,
  NebulaTheme.imperialGlass => context.l10n.nebulaThemeImperialGlass,
  NebulaTheme.abyssalGlass => context.l10n.nebulaThemeAbyssalGlass,
  NebulaTheme.sakuraGlass => context.l10n.nebulaThemeSakuraGlass,
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
  NebulaTheme.auroraGlass => context.l10n.nebulaThemeAuroraGlassDesc,
  NebulaTheme.sapphireGlass => context.l10n.nebulaThemeSapphireGlassDesc,
  NebulaTheme.amberGlass => context.l10n.nebulaThemeAmberGlassDesc,
  NebulaTheme.onyxGlass => context.l10n.nebulaThemeOnyxGlassDesc,
  NebulaTheme.pearlGlass => context.l10n.nebulaThemePearlGlassDesc,
  NebulaTheme.ivoryGlass => context.l10n.nebulaThemeIvoryGlassDesc,
  NebulaTheme.imperialGlass => context.l10n.nebulaThemeImperialGlassDesc,
  NebulaTheme.abyssalGlass => context.l10n.nebulaThemeAbyssalGlassDesc,
  NebulaTheme.sakuraGlass => context.l10n.nebulaThemeSakuraGlassDesc,
};
