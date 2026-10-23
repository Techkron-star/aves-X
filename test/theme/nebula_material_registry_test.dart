import 'package:aves/theme/nebula/nebula_material.dart';
import 'package:aves/theme/nebula/nebula_palettes.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nebula material registry', () {
    test('every built-in glass theme resolves to a material', () {
      final glassThemes = nebulaPalettes.keys.where((theme) => theme != NebulaTheme.aves).toSet();

      expect(glassThemes, isNotEmpty);
      expect(nebulaMaterials.keys.toSet(), containsAll(glassThemes));

      for (final theme in glassThemes) {
        final style = nebulaMaterials[theme];
        expect(style, isNotNull, reason: '${theme.id} must have a material style');
        expect(style!.material, isNotNull);
      }
    });

    test('material reverse lookup stays one-to-one', () {
      final styles = nebulaMaterials.values.toList(growable: false);
      final materials = styles.map((style) => style.material).toSet();

      expect(materials.length, styles.length,
          reason: 'two themes must not silently share a material identity');

      for (final style in styles) {
        expect(nebulaMaterialStylesByMaterial[style.material], same(style));
      }
    });

    test('Nosferatu Glass keeps the established ruby identity', () {
      final style = nebulaMaterials[NebulaTheme.nosferatuGlass];

      expect(style, isNotNull);
      expect(style!.material, NebulaMaterial.ruby);
      expect(style.accent.value, 0xFFE0183E);
      expect(style.edge.value, 0x80FF3B5C);
      expect(style.surface.value, 0xFF2A0710);
      expect(style.lensBorder.value, 0x99FF6A80);
      expect(style.liquidHighlight.value, 0xFFFF8A9B);
      expect(style.liquidDeep.value, 0xFFE0183E);
    });
  });
}
