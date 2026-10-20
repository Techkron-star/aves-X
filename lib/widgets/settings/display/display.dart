import 'package:aves/widgets/common/basic/feature_sticker.dart';
import 'package:aves/model/settings/enums/nav_bar_style.dart';
import 'dart:async';

import 'package:aves/model/device.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/view/view.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_confirmation_dialog.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/common/tiles/single_selection.dart';
import 'package:aves/widgets/settings/common/tiles/switch_list.dart';
import 'package:aves/widgets/settings/privacy/privacy.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class DisplaySection extends SettingsSection {
  @override
  String get key => 'display';

  @override
  Widget icon(BuildContext context) => SettingsTileLeading(
    icon: AIcons.display,
    color: context.select<AvesColorsData, Color>((v) => v.display),
  );

  @override
  String title(BuildContext context) => context.l10n.settingsDisplaySectionTitle;

  @override
  Future<List<SettingsTile>> tiles(BuildContext context) => Future.value([
    if (!settings.useTvLayout) SettingsTileDisplayThemeBrightness(),
    SettingsTileDisplayThemeColorMode(),
    if (device.isDynamicColorAvailable) SettingsTileDisplayEnableDynamicColor(),
    SettingsTileDisplayPerformanceMode(),
    SettingsTileDisplayEnableBlurEffect(),
    if (!settings.useTvLayout) SettingsTileDisplayNavBarStyle(),
    if (!settings.useTvLayout) SettingsTileDisplayNavLens(),
    if (!settings.useTvLayout) SettingsTileDisplaySwipeTabs(),
    if (!settings.useTvLayout) SettingsTileDisplayMaxBrightness(),
    if (!settings.useTvLayout) SettingsTileDisplayRefreshRateMode(),
    if (!device.isTelevision) SettingsTileDisplayForceTvLayout(),
    if (!settings.useTvLayout) SettingsTileDisplayTabletMode(),
  ]);
}

class SettingsTileDisplayThemeBrightness extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.themeBrightnessKey];

  @override
  String title(BuildContext context) => context.l10n.settingsThemeBrightnessTile;

  @override
  Widget build(BuildContext context) => SettingsSelectionListTile<AvesThemeBrightness>(
    values: AvesThemeBrightness.values,
    getName: (context, v) => v.getName(context),
    selector: (context, s) => s.themeBrightness,
    onSelection: (v) => settings.themeBrightness = v,
    tileTitle: title,
    dialogTitle: context.l10n.settingsThemeBrightnessDialogTitle,
  );
}

class SettingsTileDisplayThemeColorMode extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.themeColorModeKey];

  @override
  String title(BuildContext context) => context.l10n.settingsThemeColorHighlights;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.themeColorMode == AvesThemeColorMode.polychrome,
    onChanged: (v) => settings.themeColorMode = v ? AvesThemeColorMode.polychrome : AvesThemeColorMode.monochrome,
    title: title,
  );
}

class SettingsTileDisplayEnableDynamicColor extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.enableDynamicColorKey];

  @override
  String title(BuildContext context) => context.l10n.settingsThemeEnableDynamicColor;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.enableDynamicColor,
    onChanged: (v) => settings.enableDynamicColor = v,
    title: title,
  );
}

class SettingsTileDisplayEnableBlurEffect extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.enableBlurEffectKey];

  @override
  String title(BuildContext context) => context.l10n.settingsViewerEnableOverlayBlurEffect;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.enableBlurEffect,
    onChanged: (v) => settings.enableBlurEffect = v,
    title: title,
  );
}

class SettingsTileDisplayMaxBrightness extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.maxBrightnessKey];

  @override
  String title(BuildContext context) => context.l10n.settingsViewerMaximumBrightness;

  @override
  Widget build(BuildContext context) => SettingsSelectionListTile<MaxBrightness>(
    values: MaxBrightness.values,
    getName: (context, v) => v.getName(context),
    selector: (context, s) => s.maxBrightness,
    onSelection: (v) => settings.maxBrightness = v,
    tileTitle: title,
  );
}

class SettingsTileDisplayRefreshRateMode extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.displayRefreshRateModeKey];

  @override
  String title(BuildContext context) => context.l10n.settingsDisplayRefreshRateModeTile;

  @override
  Widget build(BuildContext context) => SettingsSelectionListTile<DisplayRefreshRateMode>(
    values: DisplayRefreshRateMode.values,
    getName: (context, v) => v.getName(context),
    selector: (context, s) => s.displayRefreshRateMode,
    onSelection: (v) => settings.displayRefreshRateMode = v,
    tileTitle: title,
    dialogTitle: context.l10n.settingsDisplayRefreshRateModeDialogTitle,
  );
}

class SettingsTileDisplayTabletMode extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.tabletModeKey];

  @override
  String title(BuildContext context) => context.l10n.settingsTabletMode;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.tabletMode,
    onChanged: (v) => settings.tabletMode = v,
    title: title,
    subtitle: (context) => context.l10n.settingsTabletModeSubtitle,
    sticker: const FeatureSticker(kind: StickerKind.experimental),
  );
}

class SettingsTileDisplayForceTvLayout extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.forceTvLayoutKey];

  @override
  String title(BuildContext context) => context.l10n.settingsDisplayUseTvInterface;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.forceTvLayout,
    onChanged: (v) async {
      if (v) {
        final l10n = context.l10n;
        if (!await showConfirmationDialog(
          context: context,
          message: [
            l10n.settingsModificationWarningDialogMessage,
            l10n.genericDangerWarningDialogMessage,
          ].join('\n\n'),
          ok: l10n.applyButtonLabel,
        )) {
          return;
        }
      }

      if (v && !(await SettingsTilePrivacyEnableBin.setBinUsage(context, false))) return;

      settings.forceTvLayout = v;
    },
    title: title,
  );
}

class SettingsTileDisplayBatGlass extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.batGlassKey];

  @override
  String title(BuildContext context) => context.l10n.settingsBatGlass;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.batGlass,
    onChanged: (v) => settings.batGlass = v,
    title: title,
    subtitle: (context) => context.l10n.settingsBatGlassSubtitle,
    sticker: const FeatureSticker(kind: StickerKind.experimental),
    trailing: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE0183E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.l10n.experimentalLabel,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class SettingsTileDisplayNavBarStyle extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.navBarStyleKey];

  @override
  String title(BuildContext context) => context.l10n.settingsNavBarStyle;

  @override
  Widget build(BuildContext context) => SettingsSelectionListTile<NavBarStyle>(
    values: NavBarStyle.values,
    getName: (context, v) => v.getName(context),
    selector: (context, s) => s.navBarStyle,
    onSelection: (v) => settings.navBarStyle = v,
    tileTitle: title,
    dialogTitle: context.l10n.settingsNavBarStyle,
  );
}

class SettingsTileDisplayPerformanceMode extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.performanceModeKey];

  @override
  String title(BuildContext context) => context.l10n.settingsPerformanceMode;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.performanceMode,
    onChanged: (v) => settings.performanceMode = v,
    title: title,
    subtitle: (context) => context.l10n.settingsPerformanceModeSubtitle,
    sticker: const FeatureSticker(kind: StickerKind.newFeature),
  );
}

class SettingsTileDisplayNavLens extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.navLensKey];

  @override
  String title(BuildContext context) => context.l10n.settingsNavLens;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.navLens,
    onChanged: (v) {
      // the lens is drawn over the rounded, floating and rectangular bars only
      if (v && settings.navBarStyle == NavBarStyle.classic) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(context.l10n.settingsNavLensClassicUnavailable)));
        return;
      }
      settings.navLens = v;
    },
    title: title,
    subtitle: (context) => context.l10n.settingsNavLensSubtitle,
    sticker: const FeatureSticker(kind: StickerKind.newFeature),
  );
}

class SettingsTileDisplaySwipeTabs extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.swipeTabsKey];

  @override
  String title(BuildContext context) => context.l10n.settingsSwipeTabs;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.swipeTabs,
    onChanged: (v) => settings.swipeTabs = v,
    title: title,
    subtitle: (context) => context.l10n.settingsSwipeTabsSubtitle,
    sticker: const FeatureSticker(kind: StickerKind.newFeature),
  );
}
