import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aves/theme/nebula/nebula_palette.dart';
import 'package:aves/theme/nebula/nebula_palettes.dart';
import 'package:aves/theme/nebula/nebula_material.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves/theme/nebula/nebula_signature_effects.dart';
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
      expect(NebulaTheme.obsidianGlass.phase, 2);
      expect(NebulaTheme.aureateGlass.phase, 2);
      expect(NebulaTheme.forgeGlass.phase, 2);
      expect(NebulaTheme.hermeticGlass.phase, 2);
    });

    test('isPhase1', () {
      expect(NebulaTheme.nosferatuGlass.isPhase1, isTrue);
      expect(NebulaTheme.obsidianGlass.isPhase1, isFalse);
      expect(NebulaTheme.aureateGlass.isPhase1, isFalse);
      expect(NebulaTheme.forgeGlass.isPhase1, isFalse);
      expect(NebulaTheme.hermeticGlass.isPhase1, isFalse);
    });
  });

  group('colors of each crystal theme', () {
    final cases = <(NebulaTheme, Color, Color, Color, Color)>{
      (NebulaTheme.nosferatuGlass, const Color(0xFF000000), const Color(0xFFE0183E), const Color(0xFF5A1626), const Color(0x80FF3B5C)),
      (NebulaTheme.obsidianGlass, const Color(0xFF0A050F), const Color(0xFF9B5DE5), const Color(0xFF3A1C52), const Color(0x806A1B9A)),
      (NebulaTheme.aureateGlass, const Color(0xFF120E06), const Color(0xFFE8C547), const Color(0xFF4A3A1C), const Color(0x80FFE08A)),
      (NebulaTheme.forgeGlass, const Color(0xFF070610), const Color(0xFFFF762B), const Color(0xFF44365F), const Color(0x80FF762B)),
      (NebulaTheme.hermeticGlass, const Color(0xFF030D09), const Color(0xFF35D8A0), const Color(0xFF2F5B47), const Color(0x80A58AFF)),
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
      (NebulaTheme.nosferatuGlass, const Color(0xFF24060E), const Color(0xFFFFFBF0), const Color(0xFF14121A), const Color(0xFF24060E)),
      (NebulaTheme.obsidianGlass, const Color(0xFF12001A), const Color(0xFF1A002A), const Color(0xFF9B5DE5), const Color(0xFF12001A)),
      (NebulaTheme.aureateGlass, const Color(0xFF1A1409), const Color(0xFFFFF4D6), const Color(0xFF8A6A1F), const Color(0xFF2C2312)),
      (NebulaTheme.forgeGlass, const Color(0xFF1F1735), const Color(0xFF0D0A1A), const Color(0xFF44365F), const Color(0xFF2B2045)),
      (NebulaTheme.hermeticGlass, const Color(0xFF143125), const Color(0xFF071610), const Color(0xFF2F5B47), const Color(0xFF1D4030)),
    };

    for (final (theme, surface, bubbleSurface, bubbleBorder, inputFieldBg) in cases) {
      test('${theme.id} security surface, bubble and input field', () {
        final tokens = _theme(theme, locale).nebula;
        expect(tokens.securitySurface, surface);
        expect(tokens.securityInputFieldBg, inputFieldBg);
        if (theme == NebulaTheme.nosferatuGlass) {
          expect(tokens.securityInputFieldBorder, nebulaPalettes[theme]!.accent);
        }
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

  group('phase-two palette targets', () {
    test('every enum value resolves to a palette', () {
      for (final theme in NebulaTheme.values) {
        expect(nebulaPaletteFor(theme), isNotNull, reason: theme.id);
      }
    });

    test('Pearl and Ivory are true light themes with readable text', () {
      for (final theme in [NebulaTheme.pearlGlass, NebulaTheme.ivoryGlass]) {
        final palette = nebulaPalettes[theme]!;
        final data = _theme(theme, locale);
        expect(palette.brightness, Brightness.light, reason: theme.id);
        expect(palette.darkOnly, isFalse, reason: theme.id);
        expect(palette.allowDynamicColor, isFalse, reason: theme.id);
        expect(data.colorScheme.brightness, Brightness.light, reason: theme.id);
        expect(_contrast(data.colorScheme.onSurface, data.colorScheme.surface), greaterThanOrEqualTo(4.5), reason: theme.id);
        expect(_contrast(data.colorScheme.onSurface, data.colorScheme.surfaceContainerHighest), greaterThanOrEqualTo(4.5), reason: theme.id);
      }
    });

    test('all non-default themes keep system dynamic colors disabled', () {
      for (final theme in NebulaTheme.values.where((t) => t != NebulaTheme.aves)) {
        expect(nebulaPalettes[theme]!.allowDynamicColor, isFalse, reason: theme.id);
      }
    });
  });

  group('Nebula material identities', () {
    test('every built-in glass theme has a distinct material recipe', () {
      final glassThemes = NebulaTheme.values.where((theme) => theme != NebulaTheme.aves).toList();
      expect(nebulaMaterials.keys, containsAll(glassThemes));
      final materials = glassThemes.map((theme) => nebulaMaterials[theme]!.material).toSet();
      expect(materials, hasLength(glassThemes.length));

      for (final theme in glassThemes) {
        final material = nebulaMaterials[theme]!;
        final palette = nebulaPalettes[theme]!;
        expect(nebulaMaterialStylesByMaterial[material.material], same(material), reason: '${theme.id} must resolve through the direct material registry');
        expect(material.accent, palette.accent, reason: '${theme.id} must use its canonical palette accent');
        expect(material.chain, hasLength(2), reason: '${theme.id} must define a chain treatment');
        expect(material.highlight, isA<LinearGradient>(), reason: '${theme.id} must define surface reflections');
      }
    });

    test('shared component surfaces inherit each active Nebula palette', () {
      for (final theme in NebulaTheme.values.where((theme) => theme != NebulaTheme.aves)) {
        final palette = nebulaPalettes[theme]!;
        final data = _theme(theme, locale);
        expect(data.cardTheme.color, palette.surfaceContainerLow, reason: theme.id);
        expect(data.appBarTheme.backgroundColor, palette.surfaceContainer, reason: theme.id);
        expect(data.progressIndicatorTheme.color, palette.accent, reason: theme.id);
      }
    });
  });

  group('custom Nebula palette integration', () {
    test('custom colors and surface treatment reach ThemeData and material recipes', () {
      final source = nebulaPalettes[NebulaTheme.forgeGlass]!;
      final custom = NebulaPalette(
        theme: NebulaTheme.aves,
        brightness: null,
        darkOnly: true,
        allowDynamicColor: false,
        seed: source.seed,
        accent: const Color(0xFFEB7C4E),
        surface: source.surface,
        surfaceContainerLowest: source.surfaceContainerLowest,
        surfaceContainerLow: source.surfaceContainerLow,
        surfaceContainer: source.surfaceContainer,
        surfaceContainerHigh: source.surfaceContainerHigh,
        surfaceContainerHighest: source.surfaceContainerHighest,
        outlineVariant: source.outlineVariant,
        treatment: NebulaSurfaceTreatment.nosferatuGlass,
        glow: source.glow,
        crystalEdge: source.crystalEdge,
        crystalHighlight: source.crystalHighlight,
        crystalBody: source.crystalBody,
        liquidIcons: source.liquidIcons,
      );

      final data = Themes.nebulaTheme(custom, false, locale);
      expect(data.colorScheme.primary, custom.accent);
      expect(data.colorScheme.surface, custom.surface);
      expect(data.cardTheme.color, custom.surfaceContainerLow);
      expect(data.appBarTheme.backgroundColor, custom.surfaceContainer);
      expect(nebulaMaterialStyleForPalette(custom)?.material, NebulaMaterial.crimson);
      expect(nebulaMaterialStyleForPalette(custom)?.accent, custom.accent);
      expect(data.nebula.securityAccent, custom.accent);
      expect(data.nebula.securitySurface, custom.surfaceContainerHigh);
      expect(data.nebula.securityBubbleSurface, custom.surfaceContainerLow);
    });
  });

  group('Nox Terroris moving material', () {
    test('retains its identity, liquid highlights and dark palette', () {
      final palette = nebulaPalettes[NebulaTheme.noxTerroris]!;
      expect(palette.darkOnly, isTrue);
      expect(palette.liquidIcons, isTrue);
      expect(palette.allowDynamicColor, isFalse);
      expect(nebulaMaterialStyleForPalette(palette)?.material, NebulaMaterial.noxTerroris);
      expect(nebulaThemeFromId('nox_terroris'), NebulaTheme.noxTerroris);
    });

    test('painter renders still and seam-adjacent frames without exceptions', () {
      const effect = NoxTerrorisEffect(animate: false);
      for (final phase in <double>[0, .1, .25, .5, .75, .999999, 1]) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        expect(() => effect.painter(phase).paint(canvas, const ui.Size(360, 240)),
            returnsNormally);
        recorder.endRecording().dispose();
      }
    });
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
