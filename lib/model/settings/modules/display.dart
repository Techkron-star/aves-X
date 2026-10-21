import 'package:aves/model/settings/enums/nav_bar_style.dart';
import 'package:aves/model/device.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/widgets.dart';

// Nebula theme selection (now a registered setting key)

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
  bool get batGlass => !performanceMode && nebulaTheme == NebulaTheme.batGlass;

  // kept for compatibility with the existing call sites of the Bat-Glass toggle
  set batGlass(bool newValue) => nebulaTheme = newValue ? NebulaTheme.batGlass : NebulaTheme.aves;

  // selected Nebula theme.
  // installs that predate the selector are migrated from the legacy `bat_glass` toggle
  NebulaTheme get nebulaTheme {
    final stored = nebulaThemeFromId(getString(SettingKeys.nebulaThemeKey));
    if (stored != null) return stored;
    final legacyBatGlass = getBool(SettingKeys.batGlassKey) ?? SettingsDefaults.batGlass;
    return legacyBatGlass ? NebulaTheme.batGlass : NebulaTheme.aves;
  }

  set nebulaTheme(NebulaTheme newValue) {
    set(SettingKeys.nebulaThemeKey, newValue.id);
    // mirror the legacy toggle too, so that a settings export/import keeps the Bat-Glass choice
    // working until `nebula_theme` is a registered setting key
    set(SettingKeys.batGlassKey, newValue == NebulaTheme.batGlass);
  }

  // selected theme actually applied.
  // performance mode disables effects, not the palette: keeping the palette preserves dark
  // surfaces and the user's theme choice while blur/animations are off
  NebulaTheme get effectiveNebulaTheme => nebulaTheme;

  bool get performanceMode => getBool(SettingKeys.performanceModeKey) ?? SettingsDefaults.performanceMode;

  set performanceMode(bool newValue) => set(SettingKeys.performanceModeKey, newValue);

  // performance mode replaces blur with solid colors
  bool get enableBlurEffect => !performanceMode && (getBool(SettingKeys.enableBlurEffectKey) ?? SettingsDefaults.enableBlurEffect);

  set enableBlurEffect(bool newValue) => set(SettingKeys.enableBlurEffectKey, newValue);

  MaxBrightness get maxBrightness => getEnumOrDefault(SettingKeys.maxBrightnessKey, SettingsDefaults.maxBrightness, MaxBrightness.values);

  set maxBrightness(MaxBrightness newValue) => set(SettingKeys.maxBrightnessKey, newValue.name);

  bool get forceTvLayout => getBool(SettingKeys.forceTvLayoutKey) ?? SettingsDefaults.forceTvLayout;

  set forceTvLayout(bool newValue) => set(SettingKeys.forceTvLayoutKey, newValue);

  // not persisted: follows the current screen as long as the user has not chosen the tablet mode explicitly
  bool _autoTabletMode = false;

  bool get tabletMode => !useTvLayout && (getBool(SettingKeys.tabletModeKey) ?? _autoTabletMode);

  set tabletMode(bool newValue) => set(SettingKeys.tabletModeKey, newValue);

  bool get failsafeComicDialogs => getBool(SettingKeys.failsafeComicDialogsKey) ?? SettingsDefaults.failsafeComicDialogs;

  set failsafeComicDialogs(bool newValue) => set(SettingKeys.failsafeComicDialogsKey, newValue);

  bool get tabletBubbleLeft => getBool(SettingKeys.tabletBubbleLeftKey) ?? SettingsDefaults.tabletBubbleLeft;

  set tabletBubbleLeft(bool newValue) => set(SettingKeys.tabletBubbleLeftKey, newValue);

  // on big screens (shortest side of 600 dp or more, like Android's `sw600dp`) the tablet mode is on,
  // as long as the user has not chosen anything. It is called at startup and whenever the window metrics change
  // (folding, external display, split screen...), so the interface adapts live. The user's choice always wins.
  void autoDetectTabletMode() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final view = views.first;
    final shortestSideDp = view.physicalSize.shortestSide / view.devicePixelRatio;
    final auto = shortestSideDp >= 600;
    if (auto == _autoTabletMode) return;
    _autoTabletMode = auto;
    if (getBool(SettingKeys.tabletModeKey) == null) notifyListeners();
  }

  bool get useTvLayout => device.isTelevision || forceTvLayout;

  bool get isReadOnly => useTvLayout;
}
