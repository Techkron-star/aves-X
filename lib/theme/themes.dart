import 'package:aves/theme/nebula/nebula_palette.dart';
import 'package:aves/theme/nebula/nebula_palettes.dart';
import 'package:aves/theme/nebula/nebula_material.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/theme/styles.dart';
import 'package:aves/widgets/aves_app.dart';
import 'package:aves/widgets/settings/language/locales.dart';
import 'package:aves_model/aves_model.dart';
import 'package:aves_utils/aves_utils.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class Themes {
  static String asButtonLabel(String s) => s.toUpperCase();

  static TextStyle searchFieldStyle(BuildContext context) => Theme.of(context).textTheme.bodyLarge!;

  static Color overlayBackgroundColor({
    required Brightness brightness,
    required bool blurred,
  }) {
    switch (brightness) {
      case .dark:
        return blurred ? const Color(0x14000000) : Colors.black45;
      case .light:
        return blurred ? const Color(0x2EFFFFFF) : const Color(0xCCFFFFFF);
    }
  }

  static bool _isDarkTheme(ColorScheme colors) => colors.brightness == Brightness.dark && colors.surface != Colors.black;

  static Color firstLayerColor(BuildContext context) => _schemeFirstLayer(Theme.of(context).colorScheme);

  static Color _schemeFirstLayer(ColorScheme colors) => _isDarkTheme(colors) ? colors.surfaceContainer : colors.surface;

  static Color _schemeCardLayer(ColorScheme colors) => _isDarkTheme(colors) ? _schemeSecondLayer(colors) : colors.surfaceContainerLow;

  static Color secondLayerColor(BuildContext context) => _schemeSecondLayer(Theme.of(context).colorScheme);

  static Color _schemeSecondLayer(ColorScheme colors) => _isDarkTheme(colors) ? colors.surfaceContainerHigh : colors.surfaceContainer;

  static Color thirdLayerColor(BuildContext context) => _schemeThirdLayer(Theme.of(context).colorScheme);

  static Color _schemeThirdLayer(ColorScheme colors) => _isDarkTheme(colors) ? colors.surfaceContainerHighest : colors.surfaceContainerHigh;

  static Color _unselectedWidgetColor(ColorScheme colors) => colors.onSurface.withValues(alpha: .6);

  static Color backgroundTextColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Color.alphaBlend(colors.surfaceTint, colors.onSurface).withValues(alpha: .5);
  }

  static final _typography = Typography.material2021(platform: TargetPlatform.android);

  static ThemeData _baseTheme(ColorScheme colors, bool deviceInitialized) {
    return ThemeData(
      // COLOR
      brightness: colors.brightness,
      canvasColor: _schemeSecondLayer(colors),
      cardColor: _schemeCardLayer(colors),
      colorScheme: colors,
      dividerColor: colors.outlineVariant,
      scaffoldBackgroundColor: _schemeFirstLayer(colors),
      // TYPOGRAPHY & ICONOGRAPHY
      iconTheme: _iconTheme(colors),
      typography: _typography,
      // COMPONENT THEMES
      bottomNavigationBarTheme: _bottomNavigationBarTheme(colors),
      checkboxTheme: _checkboxTheme(colors),
      drawerTheme: _drawerTheme(colors),
      floatingActionButtonTheme: _floatingActionButtonTheme(colors),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _schemeFirstLayer(colors),
        selectedIconTheme: IconThemeData(color: colors.primary),
        unselectedIconTheme: IconThemeData(color: _unselectedWidgetColor(colors)),
        selectedLabelTextStyle: TextStyle(color: colors.primary),
        unselectedLabelTextStyle: TextStyle(color: _unselectedWidgetColor(colors)),
      ),
      radioTheme: _radioTheme(colors),
      sliderTheme: _sliderTheme(colors),
      tabBarTheme: TabBarThemeData(indicatorColor: colors.primary),
      tooltipTheme: _tooltipTheme,
    );
  }

  static BottomNavigationBarThemeData _bottomNavigationBarTheme(ColorScheme colors) {
    final iconTheme = _iconTheme(colors);
    return BottomNavigationBarThemeData(
      elevation: 0,
      selectedIconTheme: iconTheme.copyWith(color: colors.primary),
      unselectedIconTheme: iconTheme.copyWith(color: _unselectedWidgetColor(colors)),
    );
  }

  static CheckboxThemeData _checkboxTheme(ColorScheme colors) => CheckboxThemeData(
    side: BorderSide(width: 2.0, color: _unselectedWidgetColor(colors)),
  );

  static DrawerThemeData _drawerTheme(ColorScheme colors) => DrawerThemeData(
    backgroundColor: _schemeSecondLayer(colors),
  );

  static IconThemeData _iconTheme(ColorScheme colors) => IconThemeData(
    // increased weight (from default 400 to 600)
    // applied to variable fonts from `material_symbols_icons`,
    // to match the fixed-weight icons from `flutter_material_design_icons`
    weight: 600,
    grade: 0,
    opticalSize: 48,
    color: colors.onSurface,
  );

  static const _listTileTheme = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
  );

  static PopupMenuThemeData _popupMenuTheme(ColorScheme colors, TextTheme textTheme) {
    return PopupMenuThemeData(
      color: _schemeSecondLayer(colors),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        // adapted from M3 defaults
        final TextStyle style = textTheme.labelLarge!;
        if (states.contains(WidgetState.disabled)) {
          return style.apply(color: colors.onSurface.withValues(alpha: .38));
        }
        return style.apply(color: colors.onSurface);
      }),
      iconColor: colors.onSurface,
    );
  }

  static FloatingActionButtonThemeData _floatingActionButtonTheme(ColorScheme colors) {
    return FloatingActionButtonThemeData(
      foregroundColor: colors.onPrimary,
      backgroundColor: colors.primary,
    );
  }

  // adapted from M3 defaults
  static RadioThemeData _radioTheme(ColorScheme colors) => RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurface.withValues(alpha: .38);
        }
        return colors.primary;
      }
      if (states.contains(WidgetState.disabled)) {
        return colors.onSurface.withValues(alpha: .38);
      }
      if (states.contains(WidgetState.pressed)) {
        return colors.onSurface;
      }
      if (states.contains(WidgetState.hovered)) {
        return colors.onSurface;
      }
      if (states.contains(WidgetState.focused)) {
        return colors.onSurface;
      }
      return _unselectedWidgetColor(colors);
    }),
  );

  static SliderThemeData _sliderTheme(ColorScheme colors) => SliderThemeData(
    inactiveTrackColor: colors.primary.withValues(alpha: .24),
  );

  static SnackBarThemeData _snackBarTheme(ColorScheme colors) => SnackBarThemeData(
    actionTextColor: colors.primary,
    behavior: SnackBarBehavior.floating,
  );

  static const _tooltipTheme = TooltipThemeData(
    verticalOffset: 32,
  );

  // light

  static final _lightThemeTypo = _typography.black;
  static final _lightTitleColor = _lightThemeTypo.titleMedium!.color!;
  static final _lightLabelColor = _lightThemeTypo.labelMedium!.color!;
  static const _lightActionIconColor = Color(0xAA000000);
  static const _lightOnSurface = Colors.black;

  static ThemeData lightTheme(Color accentColor, bool deviceInitialized, KnownLocale locale) {
    final onAccent = ColorUtils.textColorOn(accentColor);
    final colors = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.light,
      primary: accentColor,
      onPrimary: onAccent,
      secondary: accentColor,
      onSecondary: onAccent,
      onSurface: _lightOnSurface,
    );
    return _baseLightTheme(colors, deviceInitialized, locale);
  }

  // light component themes on top of the plain base, shared with the Nebula light palettes
  static ThemeData _baseLightTheme(ColorScheme colors, bool deviceInitialized, KnownLocale locale) {
    final textTheme = _lightThemeTypo;
    return _baseTheme(colors, deviceInitialized).copyWith(
      // TYPOGRAPHY & ICONOGRAPHY
      textTheme: textTheme,
      // COMPONENT THEMES
      appBarTheme: AppBarTheme(
        backgroundColor: _schemeFirstLayer(colors),
        // `foregroundColor` is used by icons
        foregroundColor: _lightActionIconColor,
        // `titleTextStyle.color` is used by text
        titleTextStyle: AStyles.pageTitleTextStyle(locale).copyWith(color: _lightTitleColor),
        // `systemOverlayStyle` is assumed by the app to never be null
        systemOverlayStyle: deviceInitialized ? AvesApp.systemUIStyleForBrightness(colors.brightness, _schemeFirstLayer(colors)) : const SystemUiOverlayStyle(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _schemeSecondLayer(colors),
        titleTextStyle: AStyles.pageTitleTextStyle(locale).copyWith(color: _lightTitleColor),
      ),
      listTileTheme: _listTileTheme.copyWith(
        iconColor: _lightActionIconColor,
      ),
      popupMenuTheme: _popupMenuTheme(colors, textTheme),
      snackBarTheme: _snackBarTheme(colors),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightLabelColor,
        ),
      ),
    );
  }

  // dark

  static final _darkThemeTypo = _typography.white;
  static final _darkTitleColor = _darkThemeTypo.titleMedium!.color!;
  static final _darkBodyColor = _darkThemeTypo.bodyMedium!.color!;
  static final _darkLabelColor = _darkThemeTypo.labelMedium!.color!;
  static const _darkOnSurface = Colors.white;

  static ColorScheme _darkColorScheme(Color accentColor) {
    final onAccent = ColorUtils.textColorOn(accentColor);
    final colors = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
      primary: accentColor,
      onPrimary: onAccent,
      secondary: accentColor,
      onSecondary: onAccent,
      onSurface: _darkOnSurface,
    );
    return colors;
  }

  static ThemeData _baseDarkTheme(ColorScheme colors, bool deviceInitialized, KnownLocale locale) {
    final textTheme = _darkThemeTypo;
    return _baseTheme(colors, deviceInitialized).copyWith(
      // TYPOGRAPHY & ICONOGRAPHY
      textTheme: textTheme,
      // COMPONENT THEMES
      appBarTheme: AppBarTheme(
        backgroundColor: _schemeFirstLayer(colors),
        // `foregroundColor` is used by icons
        foregroundColor: _darkTitleColor,
        // `titleTextStyle.color` is used by text
        titleTextStyle: AStyles.pageTitleTextStyle(locale).copyWith(color: _darkTitleColor),
        // `systemOverlayStyle` is assumed by the app to never be null
        systemOverlayStyle: deviceInitialized ? AvesApp.systemUIStyleForBrightness(colors.brightness, _schemeFirstLayer(colors)) : const SystemUiOverlayStyle(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _schemeSecondLayer(colors),
        titleTextStyle: AStyles.pageTitleTextStyle(locale).copyWith(color: _darkTitleColor),
      ),
      listTileTheme: _listTileTheme,
      popupMenuTheme: _popupMenuTheme(colors, textTheme),
      snackBarTheme: _snackBarTheme(colors).copyWith(
        backgroundColor: _schemeSecondLayer(colors),
        contentTextStyle: TextStyle(
          color: _darkBodyColor,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkLabelColor,
        ),
      ),
    );
  }

  static ThemeData darkTheme(Color accentColor, bool deviceInitialized, KnownLocale locale) {
    final colors = _darkColorScheme(accentColor);
    return _baseDarkTheme(colors, deviceInitialized, locale);
  }

  // black

  // experimental glass theme: black backgrounds with ruby red translucent glass.
  // Kept under the legacy name for existing call sites; the theme itself is Nosferatu Glass.
  static const nosferatuRuby = Color(0xFFE0183E);
  static const batGlassRuby = nosferatuRuby;

  // Nebula Engine

  // Builds the theme of a Nebula palette.
  //
  // The default Aves theme delegates to the legacy light/dark/black themes, so it keeps its current look.
  // Palette themes reuse the Nosferatu Glass base, and only change colors and surface treatment.
  static ThemeData nebulaTheme(
    NebulaPalette palette,
    bool deviceInitialized,
    KnownLocale locale, {
    Color? dynamicAccent,
    AvesThemeBrightness themeBrightness = AvesThemeBrightness.system,
  }) {
    final accent = palette.allowDynamicColor ? (dynamicAccent ?? palette.accent) : palette.accent;
    final ThemeData base;
    if (palette.theme == NebulaTheme.aves && palette.allowDynamicColor) {
      // the legacy themes stay the single source of truth for the default look
      base = switch (themeBrightness) {
        AvesThemeBrightness.light => lightTheme(accent, deviceInitialized, locale),
        AvesThemeBrightness.black => blackTheme(accent, deviceInitialized, locale),
        AvesThemeBrightness.dark || AvesThemeBrightness.system => darkTheme(accent, deviceInitialized, locale),
      };
    } else {
      final colors = _paletteColorScheme(palette, accent);
      // phase 1 palettes are dark: a light palette would also need its own light component themes
      base = colors.brightness == Brightness.dark
          ? _baseDarkTheme(colors, deviceInitialized, locale)
          : _baseLightTheme(colors, deviceInitialized, locale);
    }
    return _applyPalette(base, palette);
  }

  static ColorScheme _paletteColorScheme(NebulaPalette palette, Color accent) {
    final brightness = palette.brightness ?? Brightness.dark;
    final onAccent = ColorUtils.textColorOn(accent);
    final onSurface = brightness == Brightness.dark ? _darkOnSurface : _lightOnSurface;
    return ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      secondary: accent,
      onSecondary: onAccent,
      onSurface: onSurface,
    ).copyWith(
      surface: palette.surface,
      surfaceContainerLowest: palette.surfaceContainerLowest,
      surfaceContainerLow: palette.surfaceContainerLow,
      surfaceContainer: palette.surfaceContainer,
      surfaceContainerHigh: palette.surfaceContainerHigh,
      surfaceContainerHighest: palette.surfaceContainerHighest,
      outlineVariant: palette.outlineVariant,
    );
  }

  static ThemeData _applyPalette(ThemeData theme, NebulaPalette palette) {
    var result = theme;
    final buttonBackground = palette.filledButtonBackground;
    if (buttonBackground != null) {
      final buttonBorder = palette.filledButtonBorder;
      // translucent "crystal" instead of solid fills
      result = result.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: buttonBackground,
            foregroundColor: palette.brightness == Brightness.light ? const Color(0xFF29251D) : Colors.white,
            side: buttonBorder != null ? BorderSide(color: buttonBorder) : null,
          ),
        ),
      );
    }

    // The legacy Aves palette keeps its original light/dark/black component themes.
    // All glass palettes flow through a shared recipe so every screen inherits its identity.
    final isLegacyAves = palette.theme == NebulaTheme.aves && palette.allowDynamicColor;
    if (!isLegacyAves) {
      final colors = result.colorScheme;
      final outline = BorderSide(color: palette.outlineVariant.withValues(alpha: .86), width: .8);
      final material = nebulaMaterialStyleForPalette(palette);
      final ShapeBorder sharedShape = material?.shape(14, outline) ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: outline);
      final fieldBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: outline);
      final focusedFieldBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.accent, width: 1.8),
      );

      result = result.copyWith(
        iconTheme: result.iconTheme.copyWith(color: colors.onSurfaceVariant),
        appBarTheme: result.appBarTheme.copyWith(
          backgroundColor: palette.surfaceContainer,
          foregroundColor: colors.onSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: result.cardTheme.copyWith(
          color: palette.surfaceContainerLow,
          surfaceTintColor: Colors.transparent,
          shape: sharedShape,
        ),
        dialogTheme: result.dialogTheme.copyWith(
          backgroundColor: palette.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          shape: sharedShape,
        ),
        bottomSheetTheme: result.bottomSheetTheme.copyWith(
          backgroundColor: palette.surfaceContainer,
          modalBackgroundColor: palette.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          shape: sharedShape,
        ),
        popupMenuTheme: result.popupMenuTheme.copyWith(
          color: palette.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          shape: sharedShape,
        ),
        bottomNavigationBarTheme: result.bottomNavigationBarTheme.copyWith(
          backgroundColor: palette.surfaceContainerLowest,
          selectedItemColor: colors.primary,
          unselectedItemColor: colors.onSurfaceVariant,
          elevation: 0,
        ),
        navigationRailTheme: result.navigationRailTheme.copyWith(
          backgroundColor: palette.surfaceContainerLowest,
          selectedIconTheme: IconThemeData(color: colors.primary),
          unselectedIconTheme: IconThemeData(color: colors.onSurfaceVariant),
          selectedLabelTextStyle: result.textTheme.labelMedium?.copyWith(color: colors.primary),
          unselectedLabelTextStyle: result.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        navigationBarTheme: result.navigationBarTheme.copyWith(
          backgroundColor: palette.surfaceContainerLow,
          indicatorColor: palette.accent.withValues(alpha: .16),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        tabBarTheme: result.tabBarTheme.copyWith(
          indicatorColor: palette.accent,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurfaceVariant,
        ),
        dividerTheme: result.dividerTheme.copyWith(
          color: palette.outlineVariant,
          thickness: .7,
          space: 1,
        ),
        progressIndicatorTheme: result.progressIndicatorTheme.copyWith(
          color: palette.accent,
          linearTrackColor: palette.outlineVariant.withValues(alpha: .34),
          circularTrackColor: palette.outlineVariant.withValues(alpha: .34),
        ),
        chipTheme: result.chipTheme.copyWith(
          backgroundColor: palette.surfaceContainerLow,
          selectedColor: palette.accent.withValues(alpha: .18),
          side: BorderSide(color: palette.outlineVariant.withValues(alpha: .8)),
        ),
        inputDecorationTheme: result.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: palette.surfaceContainerLow,
          border: fieldBorder,
          enabledBorder: fieldBorder,
          focusedBorder: focusedFieldBorder,
        ),
        snackBarTheme: result.snackBarTheme.copyWith(
          backgroundColor: palette.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return result.copyWith(
      extensions: [
        ...result.extensions.values.where((e) => e is! NebulaTokens),
        NebulaTokens.fromPalette(palette, result.colorScheme),
      ],
    );
  }

  static ThemeData nosferatuGlassTheme(bool deviceInitialized, KnownLocale locale) => nebulaTheme(
    nebulaPalettes[NebulaTheme.nosferatuGlass]!,
    deviceInitialized,
    locale,
  );

  // legacy entry point, kept so that installs and call sites that predate the rename keep working
  static ThemeData batGlassTheme(bool deviceInitialized, KnownLocale locale) => nosferatuGlassTheme(deviceInitialized, locale);

  static ThemeData blackTheme(Color accentColor, bool deviceInitialized, KnownLocale locale) {
    final colors = _darkColorScheme(accentColor).copyWith(
      surface: Colors.black,
    );
    return _baseDarkTheme(colors, deviceInitialized, locale);
  }
}
