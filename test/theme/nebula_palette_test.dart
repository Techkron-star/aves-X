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

ThemeData _theme(NebulaTheme theme, KnownLocale locale) => Themes.nebulaTheme(
      nebulaPalettes[theme]!,
      false,
      locale,
    );

void main() {
  const locale = KnownLocale.english;

  group('Nosferatu Glass keeps its look through the Nebula Engine', () {
    final legacy = Themes.nosferatuGlassTheme(false, locale);
    final nebula = _theme(NebulaTheme.nosferatuGlass, locale);

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
    // theme: these constants are what actually pin the look
    test('legacy Nosferatu Glass constants', () {
      final colors = nebula.colorScheme;
      expect(colors.brightness, Brightness.dark);
      expect(colors.primary, Themes.nosferatuRuby);
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

  group('Nosferatu Glass tokens match the current ruby/black values', () {
    final theme = _theme(NebulaTheme.nosferatuGlass, locale);
    final tokens = theme.nebula;

    test('scrim, surface and on surface', () {
      expect(tokens.securityScrim, const Color(0xFF000000));
      expect(tokens.securitySurface, const Color(0xFF24060E));
      expect(tokens.securityOnSurface, const Color(0xFFFFFFFF));
    });

    test('accent and semantic colors', () {
      expect(tokens.securityAccent, Themes.nosferatuRuby);
      expect(tokens.securityAlert, const Color(0xFFFF3B3B));
      expect(tokens.securityOk, const Color(0xFF3DDC84));
      expect(tokens.securityWarning, const Color(0xFFFFC107));
      expect(tokens.securityInfo, const Color(0xFF64B5F6));
    });

    test('comic bubble', () {
      expect(tokens.securityBubbleSurface, const Color(0xFFFFFBF0));
      expect(tokens.securityBubbleBorder, const Color(0xFF14121A));
      expect(tokens.securityBubbleTail, const Color(0xFFFFFBF0));
      expect(tokens.securityBubbleInk, const Color(0xFF14121A));
    });

    test('crystal and input field', () {
      expect(tokens.securityCrystalEdge, const Color(0x80FF3B5C));
      expect(tokens.securityCrystalHighlight, const Color(0x55E0183E));
      expect(tokens.securityCrystalBody, NebulaTokens.fallback.securityCrystalBody);
      expect(tokens.securityInputFieldBg, const Color(0xFF24060E));
      expect(tokens.securityInputFieldBorder, Themes.nosferatuRuby);
      expect(tokens.securityScrimOverlay, const Color(0xFF000000).withValues(alpha: .8));
    });
  });

  group('contrast', () {
    test('Nosferatu Glass onSurface over surface', () {
      final theme = _theme(NebulaTheme.nosferatuGlass, locale);
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

  // Every crystal theme: dark only, no dynamic color, its own treatment, and the phase declared in the enum.
  group('palette contract of the crystal themes', () {
    final cases = <NebulaTheme>{
      NebulaTheme.nosferatuGlass,
      NebulaTheme.obsidianGlass,
      NebulaTheme.aureateGlass,
      NebulaTheme.forgeGlass,
      NebulaTheme.hermeticGlass,
    };

    test('darkOnly and allowDynamicColor', () {
      for (final theme in cases) {
        final palette = nebulaPalettes[theme]!;
        expect(palette.darkOnly, isTrue, reason: '${theme.id} must be dark-only');
        expect(palette.allowDynamicColor, isFalse, reason: '${theme.id} must not use dynamic color');
        expect(nebulaPaletteFor(theme), palette);
      }
    });

    test('treatment matches the theme', () {
      expect(nebulaPalettes[NebulaTheme.nosferatuGlass]!.treatment, NebulaSurfaceTreatment.nosferatuGlass);
      expect(nebulaPalettes[NebulaTheme.obsidianGlass]!.treatment, NebulaSurfaceTreatment.obsidianGlass);
      expect(nebulaPalettes[NebulaTheme.aureateGlass]!.treatment, NebulaSurfaceTreatment.aureateGlass);
      expect(nebulaPalettes[NebulaTheme.forgeGlass]!.treatment, NebulaSurfaceTreatment.forgeGlass);
      expect(nebulaPalettes[NebulaTheme.hermeticGlass]!.treatment, NebulaSurfaceTreatment.hermeticGlass);
    });

    test('phase', () {
      expect(NebulaTheme.aves.phase, 1);
      expect(NebulaTheme.nosferatuGlass.phase, 1);
      expect(NebulaTheme.obsidianGlass.phase, 1);
      expect(NebulaTheme.aureateGlass.phase, 1);
      expect(NebulaTheme.forgeGlass.phase, 2);
      expect(NebulaTheme.hermeticGlass.phase, 2);
    });

    test('isPhase1', () {
      expect(NebulaTheme.nosferatuGlass.isPhase1, isTrue);
      expect(NebulaTheme.obsidianGlass.isPhase1, isTrue);
      expect(NebulaTheme.aureateGlass.isPhase1, isTrue);
      expect(NebulaTheme.forgeGlass.isPhase1, isFalse);
      expect(NebulaTheme.hermeticGlass.isPhase1, isFalse);
    });
  });

  group('colors of each crystal theme', () {
    final cases = <(NebulaTheme, Color, Color, Color, Color)>{
      (NebulaTheme.nosferatuGlass, const Color(0xFF000000), const Color(0xFFE0183E), const Color(0xFF5A1626), const Color(0x80FF3B5C)),
      (NebulaTheme.obsidianGlass, const Color(0xFF0A0000), const Color(0xFFE0183E), const Color(0xFF4A0000), const Color(0x80FF3B5C)),
      (NebulaTheme.aureateGlass, const Color(0xFF120E06), const Color(0xFFE8C547), const Color(0xFF4A3A1C), const Color(0x80FFE08A)),
      (NebulaTheme.forgeGlass, const Color(0xFF080611), const Color(0xFFFF7A18), const Color(0xFF3A2C63), const Color(0x80B07CFF)),
      (NebulaTheme.hermeticGlass, const Color(0xFF04100C), const Color(0xFF35E0A1), const Color(0xFF2A4F3F), const Color(0x809B7BFF)),
    };

    for (final (theme, surface, accent, outlineVariant, crystalEdge) in cases) {
      test('${theme.id} surfaces and accents', () {
        final colors = _theme(theme, locale).colorScheme;
        expect(colors.surface, surface);
        expect(colors.primary, accent);
        expect(colors.outlineVariant, outlineVariant);
      });

      test('${theme.id} contrast', () {
        final colors = _theme(theme, locale).colorScheme;
        expect(_contrast(colors.onSurface, colors.surface), greaterThanOrEqualTo(4.5));
      });

      test('${theme.id} crystal edge', () {
        expect(nebulaPalettes[theme]!.crystalEdge, crystalEdge);
      });
    }
  });

  group('Fail-Safe tokens of each crystal theme', () {
    final cases = <(NebulaTheme, Color, Color, Color, Color)>{
      (NebulaTheme.nosferatuGlass, const Color(0xFF24060E), const Color(0xFFFFFBF0), const Color(0xFF14121A), const Color(0xFFE0183E)),
      (NebulaTheme.obsidianGlass, const Color(0xFF1A0000), const Color(0xFF2A0000), const Color(0xFFFF3B30), const Color(0xFF1A0000)),
      (NebulaTheme.aureateGlass, const Color(0xFF1A1409), const Color(0xFFFFF4D6), const Color(0xFF8A6A1F), const Color(0xFF2C2312)),
      (NebulaTheme.forgeGlass, const Color(0xFF1B1533), const Color(0xFF241B44), const Color(0xFFB07CFF), const Color(0xFF1B1533)),
      (NebulaTheme.hermeticGlass, const Color(0xFF112B21), const Color(0xFF17382B), const Color(0x809B7BFF), const Color(0xFF112B21)),
    };

    for (final (theme, surface, bubbleSurface, bubbleBorder, inputFieldBg) in cases) {
      test('${theme.id} security surface, bubble and input field', () {
        final tokens = _theme(theme, locale).nebula;
        expect(tokens.securitySurface, surface);
        expect(tokens.securityInputFieldBg, inputFieldBg);
        expect(tokens.securityBubbleSurface, bubbleSurface);
        expect(tokens.securityBubbleBorder, bubbleBorder);
        // the accent is readable on the theme surface
        expect(_contrast(tokens.securityOnSurface, tokens.securitySurface), greaterThanOrEqualTo(4.5));
      });

      test('${theme.id} crystal body comes from the palette', () {
        final tokens = _theme(theme, locale).nebula;
        expect(tokens.securityCrystalBody, nebulaPalettes[theme]!.crystalBody);
        expect(tokens.securityCrystalBody, hasLength(4));
      });
    }
  });

  group('Nebula theme ids', () {
    test('ids are stable and parse back', () {
      expect(NebulaTheme.aves.id, 'aves');
      expect(NebulaTheme.nosferatuGlass.id, 'nosferatu_glass');
      expect(NebulaTheme.obsidianGlass.id, 'obsidian_glass');
      expect(NebulaTheme.aureateGlass.id, 'aureate_glass');
      expect(NebulaTheme.forgeGlass.id, 'forge_glass');
      expect(NebulaTheme.hermeticGlass.id, 'hermetic_glass');
      expect(nebulaThemeFromId('nosferatu_glass'), NebulaTheme.nosferatuGlass);
      expect(nebulaThemeFromId('obsidian_glass'), NebulaTheme.obsidianGlass);
      expect(nebulaThemeFromId('aureate_glass'), NebulaTheme.aureateGlass);
      expect(nebulaThemeFromId('forge_glass'), NebulaTheme.forgeGlass);
      expect(nebulaThemeFromId('hermetic_glass'), NebulaTheme.hermeticGlass);
      // legacy ids from before the Nosferatu Glass rename still resolve
      expect(nebulaThemeFromId('bat_glass'), NebulaTheme.nosferatuGlass);
      expect(nebulaThemeFromId('night_demon'), NebulaTheme.obsidianGlass);
      expect(nebulaThemeFromId('godly'), NebulaTheme.aureateGlass);
      expect(nebulaThemeFromId('cosmic_forge'), NebulaTheme.forgeGlass);
      expect(nebulaThemeFromId('hermetisc'), NebulaTheme.hermeticGlass);
      expect(nebulaThemeFromId('unknown'), isNull);
      expect(nebulaThemeFromId(null), isNull);
    });

    test('themes without a palette fall back to the default one', () {
      expect(nebulaPaletteFor(NebulaTheme.aves), nebulaPalettes[NebulaTheme.aves]);
    });

    test('tokens interpolate with the theme', () {
      final nosferatu = _theme(NebulaTheme.nosferatuGlass, locale).nebula;
      final obsidian = _theme(NebulaTheme.obsidianGlass, locale).nebula;
      final mid = nosferatu.lerp(obsidian, .5);
      expect(mid.securityCrystalBody, hasLength(nosferatu.securityCrystalBody.length));
      expect(mid.securityAccent, isNot(nosferatu.securityAccent));
      expect(mid.securityAccent, isNot(obsidian.securityAccent));
    });
  });
}
