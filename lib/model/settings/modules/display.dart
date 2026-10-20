import 'package:aves/model/settings/enums/nav_bar_style.dart';
import 'package:aves/model/device.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/widgets.dart';

mixin DisplaySettings on SettingsAccess {
  DisplayRefreshRateMode get displayRefreshRateMode => getEnumOrDefault(SettingKeys.displayRefreshRateModeKey, SettingsDefaults.displayRefreshRateMode, DisplayRefreshRateMode.values);

  set displayRefreshRateMode(DisplayRefreshRateMode newValue) => set(SettingKeys.displayRefreshRateModeKey, newValue.name);

  AvesThemeBrightness get themeBrightness => getEnumOrDefault(SettingKeys.themeBrightnessKey, SettingsDefaults.themeBrightness, AvesThemeBrightness.values);

  set themeBrightness(AvesThemeBrightness newValue) => set(SettingKeys.themeBrightnessKey, newValue.name);

  AvesThemeColorMode get themeColorMode => getEnumOrDefault(SettingKeys.themeColorModeKey, SettingsDefaults.themeColorMode, AvesThemeColorMode.values);

  set themeColorMode(AvesThemeColorMode newValue) => set(SettingKeys.themeColorModeKey, newValue.name);

  bool get enableDynamicColor => getBool(SettingKeys.enableDynamicColorKey) ?? SettingsDefaults.enableDynamicColor;

  set enableDynamicColor(bool newValue) => set(SettingKeys.enableDynamicColorKey, newValue);

  bool get glassEverywhere => !performanceMode && (getBool(SettingKeys.glassEverywhereKey) ?? SettingsDefaults.glassEverywhere);

  set glassEverywhere(bool newValue) => set(SettingKeys.glassEverywhereKey, newValue);

  bool get explorerShowAllFolders => getBool(SettingKeys.explorerShowAllFoldersKey) ?? SettingsDefaults.explorerShowAllFolders;

  set explorerShowAllFolders(bool newValue) => set(SettingKeys.explorerShowAllFoldersKey, newValue);

  bool get swipeTabs => getBool(SettingKeys.swipeTabsKey) ?? SettingsDefaults.swipeTabs;

  set swipeTabs(bool newValue) => set(SettingKeys.swipeTabsKey, newValue);

  bool get navLens => !performanceMode && (getBool(SettingKeys.navLensKey) ?? SettingsDefaults.navLens);

  set navLens(bool newValue) => set(SettingKeys.navLensKey, newValue);

  NavBarStyle get navBarStyle => getEnumOrDefault(SettingKeys.navBarStyleKey, SettingsDefaults.navBarStyle, NavBarStyle.values);

  set navBarStyle(NavBarStyle newValue) => set(SettingKeys.navBarStyleKey, newValue.name);

  // performance mode always wins over the visual effects
  bool get batGlass => !performanceMode && (getBool(SettingKeys.batGlassKey) ?? SettingsDefaults.batGlass);

  set batGlass(bool newValue) => set(SettingKeys.batGlassKey, newValue);

  bool get performanceMode => getBool(SettingKeys.performanceModeKey) ?? SettingsDefaults.performanceMode;

  set performanceMode(bool newValue) => set(SettingKeys.performanceModeKey, newValue);

  // performance mode replaces blur with solid colors
  bool get enableBlurEffect => !performanceMode && (getBool(SettingKeys.enableBlurEffectKey) ?? SettingsDefaults.enableBlurEffect);

  set enableBlurEffect(bool newValue) => set(SettingKeys.enableBlurEffectKey, newValue);

  MaxBrightness get maxBrightness => getEnumOrDefault(SettingKeys.maxBrightnessKey, SettingsDefaults.maxBrightness, MaxBrightness.values);

  set maxBrightness(MaxBrightness newValue) => set(SettingKeys.maxBrightnessKey, newValue.name);

  bool get forceTvLayout => getBool(SettingKeys.forceTvLayoutKey) ?? SettingsDefaults.forceTvLayout;

  set forceTvLayout(bool newValue) => set(SettingKeys.forceTvLayoutKey, newValue);

  bool get tabletMode => !useTvLayout && (getBool(SettingKeys.tabletModeKey) ?? SettingsDefaults.tabletMode);

  set tabletMode(bool newValue) => set(SettingKeys.tabletModeKey, newValue);

  // on big screens (shortest side of 600 dp or more, like Android's `sw600dp`) the tablet mode is turned on
  // the first time, as long as the user has not chosen anything yet. Afterwards, the setting is the user's call.
  void autoDetectTabletMode() {
    if (getBool(SettingKeys.tabletModeKey) != null) return;
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final view = views.first;
    final shortestSideDp = view.physicalSize.shortestSide / view.devicePixelRatio;
    if (shortestSideDp >= 600) tabletMode = true;
  }

  bool get useTvLayout => device.isTelevision || forceTvLayout;

  bool get isReadOnly => useTvLayout;
}
