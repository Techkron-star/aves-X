import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_logo_art.dart';
import 'package:aves/widgets/settings/nebula/nebula_tab.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

// Entrada principal del Nebula Engine en Ajustes.
//
// Es una seccion propia (no un tile secundario dentro de Display) con una
// tarjeta visual especial al estilo del modo Black Hole: borde brillante,
// gradiente oscurecido y el logo de Aves-X. Al tocarla se abre la pestaña
// Nebula, que es el escaparate completo del motor (fondo galaxia, selector
// de temas y efectos galaticos).
class NebulaSection extends SettingsSection {
  @override
  String get key => 'nebula';

  @override
  Widget icon(BuildContext context) => SettingsTileLeading(
    icon: Icons.auto_awesome,
    color: const Color(0xFFB388FF),
  );

  @override
  String title(BuildContext context) => context.l10n.nebulaEngineSectionTitle;

  @override
  Future<List<SettingsTile>> tiles(BuildContext context) => Future.value([
    const SettingsTileNebulaEngine(),
  ]);
}

/// Tarjeta especial del Nebula Engine. Abre la pestaña Nebula al tocar.
class SettingsTileNebulaEngine extends SettingsTile {
  const SettingsTileNebulaEngine();

  @override
  List<String> get settingKeys => [SettingKeys.nebulaThemeKey];

  @override
  String title(BuildContext context) => context.l10n.nebulaEngineTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.maybeOf(context)?.push(
          MaterialPageRoute(
            settings: const RouteSettings(name: NebulaTab.routeName),
            builder: (_) => const NebulaTab(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const RadialGradient(
            center: Alignment(-0.85, 0),
            radius: 1.5,
            colors: [Color(0xFF2A103F), Color(0xFF05030A)],
          ),
          border: Border.all(color: const Color(0x55B388FF)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(color: const Color(0xFFB388FF).withValues(alpha: 0.35)),
                ),
                padding: const EdgeInsets.all(8),
                child: const AvesLogoArt(size: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.nebulaEngineTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.nebulaEngineSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xB3FFFFFF),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0x80FFFFFF)),
            ],
          ),
        ),
      ),
    );
  }
}
