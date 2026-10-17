import 'package:aves/widgets/common/basic/feature_sticker.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_confirmation_dialog.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/common/tiles/switch_list.dart';
import 'package:aves/widgets/settings/display/display.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// Options that may hurt performance or stability. Opening this section shows a warning first.
class ExperimentalSection extends SettingsSection {
  @override
  String get key => 'experimental';

  @override
  Widget icon(BuildContext context) => SettingsTileLeading(
    icon: AIcons.experimental,
    color: context.select<AvesColorsData, Color>((v) => v.experimental),
  );

  @override
  String title(BuildContext context) => context.l10n.settingsExperimentalSectionTitle;

  @override
  Future<List<SettingsTile>> tiles(BuildContext context) => Future.value([
    SettingsTileDisplayBatGlass(),
    SettingsTileExperimentalGlassEverywhere(),
  ]);

  @override
  Widget build(BuildContext sectionContext, ValueNotifier<String?> expandedNotifier) {
    return Builder(
      builder: (context) => ListTile(
        key: const Key('section-experimental'),
        leading: icon(context),
        title: Text(title(context).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final accepted = await showConfirmationDialog(
            context: context,
            message: context.l10n.experimentalWarningMessage,
            ok: context.l10n.riskWarningContinue,
          );
          if (!accepted || !context.mounted) return;

          final items = await tiles(context);
          if (!context.mounted) return;
          await Navigator.maybeOf(context)?.push(
            MaterialPageRoute(
              settings: const RouteSettings(name: '/settings/experimental'),
              builder: (context) => AvesScaffold(
                appBar: AppBar(title: Text(title(context).toUpperCase())),
                body: SafeArea(
                  child: ListView(children: items.map((tile) => tile.build(context)).toList()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsTileExperimentalGlassEverywhere extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.glassEverywhereKey];

  @override
  String title(BuildContext context) => context.l10n.settingsGlassEverywhere;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.glassEverywhere,
    onChanged: (v) => settings.glassEverywhere = v,
    title: title,
    subtitle: (context) => context.l10n.settingsGlassEverywhereSubtitle,
    sticker: const FeatureSticker(kind: StickerKind.experimental),
  );
}
