import 'dart:math' as math;

import 'package:aves/theme/nebula/nebula_palettes.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/widgets/settings/language/locales.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// WCAG 2 relative contrast ratio between two opaque colors
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + .05) / (darker + .05);
}

void main() {
  const locale = KnownLocale.english;

  group('Bat-Glass keeps its look through the Nebula Engine', () {
    final legacy = Themes.batGlassTheme(false, locale);
    final nebula = Themes.nebulaTheme(nebulaPalettes[NebulaTheme.batGlass]!, false, locale);

    test('same color scheme', () {
      final expected = legacy.colorScheme;
      final actual = nebula.colorScheme;
      expect(actual.brightness, expected.brightness);
      expect(actual.primary, expected.primary);
      expect(actual.onPrimary, expected.onPrimary);
      expect(actual.secondary, expected.secondary);
      expect(actual.onSecondary, expected.onSecondary);
      expect(actual.onSurface, expected.onSurface);
      expect(actual.surface, expected.surface);
      expect(actual.surfaceContainerLowest, expected.surfaceContainerLowest);
      expect(actual.surfaceContainerLow, expected.surfaceContainerLow);
      expect(actual.surfaceContainer, expected.surfaceContainer);
      expect(actual.surfaceContainerHigh, expected.surfaceContainerHigh);
      expect(actual.surfaceContainerHighest, expected.surfaceContainerHighest);
      expect(actual.outlineVariant, expected.outlineVariant);
    });

    // the values above are compared against the legacy entry point, which now delegates to the Nebula
    // theme: these constants are what actually pins the look
    test('legacy Bat-Glass constants', () {
      final colors = nebula.colorScheme;
      expect(colors.brightness, Brightness.dark);
      expect(colors.primary, Themes.batGlassRuby);
      expect(colors.surface, Colors.black);
      expect(colors.surfaceContainerLowest, Colors.black);
      expect(colors.surfaceContainerLow, const Color(0xFF0E0407));
      expect(colors.surfaceContainer, const Color(0xFF16060B));
      expect(colors.surfaceContainerHigh, const Color(0xFF1F0910));
      expect(colors.surfaceContainerHighest, const Color(0xFF2A0D16));
      expect(colors.outlineVariant, const Color(0xFF5A1626));
    });

    test('same first layer and outline', () {
      expect(nebula.scaffoldBackgroundColor, legacy.scaffoldBackgroundColor);
      expect(nebula.scaffoldBackgroundColor, Colors.black);
      expect(nebula.colorScheme.outlineVariant, const Color(0xFF5A1626));
    });

    test('same translucent filled button', () {
      final expected = legacy.filledButtonTheme.style!.backgroundColor!.resolve({});
      final actual = nebula.filledButtonTheme.style!.backgroundColor!.resolve({});
      expect(actual, expected);
      expect(actual, const Color(0xB3C4122F));
    });
  });

  group('contrast', () {
    test('Bat-Glass onSurface over surface', () {
      final theme = Themes.nebulaTheme(nebulaPalettes[NebulaTheme.batGlass]!, false, locale);
      expect(_contrast(theme.colorScheme.onSurface, theme.colorScheme.surface), greaterThanOrEqualTo(4.5));
    });

    test('default Aves theme onSurface over surface', () {
      final palette = nebulaPalettes[NebulaTheme.aves]!;
      const accent = Color(0xFFC62828);
      final light = Themes.nebulaTheme(palette, false, locale, dynamicAccent: accent, themeBrightness: AvesThemeBrightness.light);
      final dark = Themes.nebulaTheme(palette, false, locale, dynamicAccent: accent, themeBrightness: AvesThemeBrightness.dark);
      expect(_contrast(light.colorScheme.onSurface, light.colorScheme.surface), greaterThanOrEqualTo(4.5));
      expect(_contrast(dark.colorScheme.onSurface, dark.colorScheme.surface), greaterThanOrEqualTo(4.5));
    });
  });

  group('Fail-Safe tokens', () {
    test('Bat-Glass tokens match the current ruby/black values', () {
      final theme = Themes.nebulaTheme(nebulaPalettes[NebulaTheme.batGlass]!, false, locale);
      final tokens = theme.nebula;
      expect(tokens.securityScrim, const Color(0xFF000000));
      expect(tokens.securitySurface, const Color(0xFF24060E));
      expect(tokens.securityOnSurface, const Color(0xFFFFFFFF));
      expect(tokens.securityAccent, Themes.batGlassRuby);
      expect(tokens.securityBubbleSurface, const Color(0xFFFFFBF0));
      expect(tokens.securityBubbleBorder, const Color(0xFF14121A));
      expect(tokens.securityCrystalEdge, const Color(0x80FF3B5C));
      expect(tokens.securityCrystalHighlight, const Color(0x55E0183E));
      expect(tokens.securityCrystalBody, NebulaTokens.fallback.securityCrystalBody);
    });

    test('a theme without tokens falls back to the legacy values', () {
      expect(ThemeData().nebula, NebulaTokens.fallback);
    });

    test('tokens interpolate with the theme', () {
      final batGlass = Themes.nebulaTheme(nebulaPalettes[NebulaTheme.batGlass]!, false, locale).nebula;
      final aves = Themes.nebulaTheme(nebulaPalettes[NebulaTheme.aves]!, false, locale, dynamicAccent: const Color(0xFFC62828)).nebula;
      final mid = batGlass.lerp(aves, .5);
      expect(mid.securityCrystalBody, hasLength(batGlass.securityCrystalBody.length));
      expect(mid.securityAccent, isNot(batGlass.securityAccent));
      expect(mid.securityAccent, isNot(aves.securityAccent));
    });
  });

  group('Nebula theme ids', () {
    test('ids are stable and parse back', () {
      expect(NebulaTheme.aves.id, 'aves');
      expect(NebulaTheme.batGlass.id, 'bat_glass');
      expect(NebulaTheme.nightDemon.id, 'night_demon');
      expect(NebulaTheme.godly.id, 'godly');
      expect(NebulaTheme.cosmicForge.id, 'cosmic_forge');
      expect(NebulaTheme.hermetisc.id, 'hermetisc');
      expect(nebulaThemeFromId('bat_glass'), NebulaTheme.batGlass);
      expect(nebulaThemeFromId('unknown'), isNull);
      expect(nebulaThemeFromId(null), isNull);
    });

    test('phases', () {
      expect(NebulaTheme.aves.phase, 1);
      expect(NebulaTheme.batGlass.phase, 1);
      expect(NebulaTheme.nightDemon.phase, 1);
      expect(NebulaTheme.godly.phase, 1);
      expect(NebulaTheme.cosmicForge.phase, 2);
      expect(NebulaTheme.hermetisc.phase, 2);
    });

    test('themes without a palette fall back to the default one', () {
      expect(nebulaPaletteFor(NebulaTheme.nightDemon), nebulaPalettes[NebulaTheme.aves]);
      expect(nebulaPaletteFor(NebulaTheme.cosmicForge), nebulaPalettes[NebulaTheme.aves]);
    });
  });
}
