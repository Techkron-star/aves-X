import 'package:aves/model/settings/enums/nav_bar_style.dart';
import 'package:aves/widgets/common/basic/feature_sticker.dart';
import 'package:aves/widgets/settings/avesx/gargantuan_mode_page.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/common/tiles/sub_page.dart';
import 'package:aves/widgets/settings/common/tiles/switch_list.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';

/// Controls unique to the Aves-X fork live together instead of being scattered
/// across inherited Display and generic Experimental settings.
class AvesXSection extends SettingsSection {
  @override
  String get key => 'avesx';

  @override
  Widget icon(BuildContext context) => SettingsTileLeading(
    icon: AIcons.experimental,
    color: Theme.of(context).colorScheme.primary,
  );

  @override
  String title(BuildContext context) => 'Aves-X';

  @override
  Future<List<SettingsTile>> tiles(BuildContext context) => Future.value([
    SettingsTileGlassEverywhere(),
    if (!settings.useTvLayout) SettingsTileNavLens(),
    SettingsTileGargantuanMode(),
  ]);
}

/// Glass Everywhere 3.0 is the fork-wide opt-in for frosted surfaces.
class SettingsTileGlassEverywhere extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.glassEverywhereKey];

  @override
  String title(BuildContext context) => '${context.l10n.settingsGlassEverywhere} 3.0';

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.glassEverywhere,
    onChanged: (v) => settings.glassEverywhere = v,
    title: title,
    subtitle: (context) => context.l10n.settingsGlassEverywhereSubtitle,
    sticker: const FeatureSticker(kind: StickerKind.newFeature),
  );
}

/// The Nav Lens belongs to the Aves-X visual identity and inherits its finish
/// from Nebula, while any backdrop blur remains opt-in through Glass Everywhere.
class SettingsTileNavLens extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.navLensKey];

  @override
  String title(BuildContext context) => context.l10n.settingsNavLens;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.navLens,
    onChanged: (v) {
      if (v && settings.navBarStyle == NavBarStyle.classic) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(context.l10n.settingsNavLensClassicUnavailable)),
        );
        return;
      }
      settings.navLens = v;
    },
    title: title,
    subtitle: (context) => context.l10n.settingsNavLensSubtitle,
  );
}

/// The Black Hole root mode is part of Gargantuan, not Gargantua's data-exit
/// policy; the stored setting remains unchanged for compatibility.
class SettingsTileGargantuanMode extends SettingsTile {
  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => 'Gargantuan';

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    title: title,
    subtitle: (context) => Text(context.l10n.blackHoleRootOptionSubtitle),
    routeName: '/settings/gargantuan',
    builder: (context) => const GargantuanModePage(),
  );
}
