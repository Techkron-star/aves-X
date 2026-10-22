import 'package:aves/theme/nebula/nebula_palette.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

// A custom Nebula theme created by the user, persisted as a JSON file.
//
// Schema version 1:
// {
//   "schema": 1,
//   "id": "my_theme",
//   "name": "My Theme",
//   "description": "Optional description",
//   "treatment": "flat | nosferatuGlass | obsidianGlass | aureateGlass | forgeGlass | hermeticGlass | eclipseGlass | solarFlareGlass | voidGlass | crimsonGlass | neonGlass | emeraldGlass",
//   "seed": "#RRGGBB",
//   "accent": "#RRGGBB",
//   "surface": "#RRGGBB",
//   "surfaceContainerLowest": "#RRGGBB",
//   "surfaceContainerLow": "#RRGGBB",
//   "surfaceContainer": "#RRGGBB",
//   "surfaceContainerHigh": "#RRGGBB",
//   "surfaceContainerHighest": "#RRGGBB",
//   "outlineVariant": "#RRGGBB",
//   "glow": "#RRGGBB",
//   "crystalEdge": "#RRGGBB",
//   "crystalHighlight": "#RRGGBB",
//   "crystalBody": ["#RRGGBB", "#RRGGBB", "#RRGGBB", "#RRGGBB"],
//   "liquidIcons": true
// }
@immutable
class CustomNebulaTheme {
  final int schema;
  final String id;
  final String name;
  final String? description;
  final NebulaSurfaceTreatment treatment;
  final Color seed;
  final Color accent;
  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color outlineVariant;
  final Color glow;
  final Color crystalEdge;
  final Color crystalHighlight;
  final List<Color> crystalBody;
  final bool liquidIcons;

  const CustomNebulaTheme({
    required this.schema,
    required this.id,
    required this.name,
    this.description,
    required this.treatment,
    required this.seed,
    required this.accent,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.outlineVariant,
    required this.glow,
    required this.crystalEdge,
    required this.crystalHighlight,
    required this.crystalBody,
    required this.liquidIcons,
  });

  /// Parses a JSON map into a [CustomNebulaTheme], throwing [FormatException]
  /// with a readable message when the schema is invalid.
  factory CustomNebulaTheme.fromJson(Map<String, dynamic> json) {
    final errors = <String>[];

    // schema
    final schema = json['schema'] as int?;
    if (schema == null || schema != 1) {
      errors.add('schema: expected 1, got ${json['schema']}');
    }

    // id
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      errors.add('id: required non-empty string');
    } else if (!RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
      errors.add('id: must contain only lowercase letters, digits and underscores');
    }

    // name
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) {
      errors.add('name: required non-empty string');
    }

    // treatment
    final treatmentStr = json['treatment'] as String?;
    NebulaSurfaceTreatment? treatment;
    try {
      treatment = NebulaSurfaceTreatment.values
          .firstWhere((t) => t.name == treatmentStr);
    } catch (_) {
      errors.add('treatment: must be one of ${NebulaSurfaceTreatment.values.map((t) => t.name).join(', ')}');
    }

    // color helper
    Color? parseColor(String key, {required List<String> errors}) {
      final hex = json[key] as String?;
      if (hex == null) {
        errors.add('$key: required color string (#RRGGBB or #AARRGGBB)');
        return null;
      }
      try {
        return Color.parse(hex);
      } catch (_) {
        errors.add('$key: invalid color "$hex"');
        return null;
      }
    }

    final seed = parseColor('seed', errors: errors);
    final accent = parseColor('accent', errors: errors);
    final surface = parseColor('surface', errors: errors);
    final surfaceContainerLowest = parseColor('surfaceContainerLowest', errors: errors);
    final surfaceContainerLow = parseColor('surfaceContainerLow', errors: errors);
    final surfaceContainer = parseColor('surfaceContainer', errors: errors);
    final surfaceContainerHigh = parseColor('surfaceContainerHigh', errors: errors);
    final surfaceContainerHighest = parseColor('surfaceContainerHighest', errors: errors);
    final outlineVariant = parseColor('outlineVariant', errors: errors);
    final glow = parseColor('glow', errors: errors);
    final crystalEdge = parseColor('crystalEdge', errors: errors);
    final crystalHighlight = parseColor('crystalHighlight', errors: errors);

    // crystalBody: list of 4 colors
    final crystalBodyRaw = json['crystalBody'] as List?;
    List<Color> crystalBody = [];
    if (crystalBodyRaw == null) {
      errors.add('crystalBody: required array of 4 colors');
    } else if (crystalBodyRaw.length != 4) {
      errors.add('crystalBody: expected 4 colors, got ${crystalBodyRaw.length}');
    } else {
      crystalBody = crystalBodyRaw.mapIndexed((i, c) {
        final hex = c as String?;
        try {
          return Color.parse(hex ?? '');
        } catch (_) {
          errors.add('crystalBody[$i]: invalid color "$hex"');
          return Color(0xFF000000);
        }
      }).toList();
    }

    final liquidIcons = json['liquidIcons'] as bool? ?? true;

    if (errors.isNotEmpty) {
      throw FormatException('Invalid custom Nebula theme:\n${errors.join('\n')}');
    }

    return CustomNebulaTheme(
      schema: schema!,
      id: id!,
      name: name!,
      description: description,
      treatment: treatment!,
      seed: seed!,
      accent: accent!,
      surface: surface!,
      surfaceContainerLowest: surfaceContainerLowest!,
      surfaceContainerLow: surfaceContainerLow!,
      surfaceContainer: surfaceContainer!,
      surfaceContainerHigh: surfaceContainerHigh!,
      surfaceContainerHighest: surfaceContainerHighest!,
      outlineVariant: outlineVariant!,
      glow: glow!,
      crystalEdge: crystalEdge!,
      crystalHighlight: crystalHighlight!,
      crystalBody: crystalBody,
      liquidIcons: liquidIcons,
    );
  }

  /// Converts this theme to a JSON map suitable for persistence.
  Map<String, dynamic> toJson() => {
    'schema': schema,
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'treatment': treatment.name,
    'seed': '#${seed.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'accent': '#${accent.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'surface': '#${surface.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'surfaceContainerLowest': '#${surfaceContainerLowest.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'surfaceContainerLow': '#${surfaceContainerLow.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'surfaceContainer': '#${surfaceContainer.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'surfaceContainerHigh': '#${surfaceContainerHigh.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'surfaceContainerHighest': '#${surfaceContainerHighest.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'outlineVariant': '#${outlineVariant.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'glow': '#${glow.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'crystalEdge': '#${crystalEdge.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'crystalHighlight': '#${crystalHighlight.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'crystalBody': crystalBody.map((c) => '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}').toList(),
    'liquidIcons': liquidIcons,
  };

  /// Converts this theme into a [NebulaPalette] for rendering.
  NebulaPalette toPalette() => NebulaPalette(
    theme: NebulaTheme.aves, // custom themes reuse the `aves` enum value; the palette carries the colors
    brightness: null,
    darkOnly: true,
    allowDynamicColor: false,
    seed: seed,
    accent: accent,
    surface: surface,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    outlineVariant: outlineVariant,
    treatment: treatment,
    glow: glow,
    crystalEdge: crystalEdge,
    crystalHighlight: crystalHighlight,
    crystalBody: crystalBody,
    liquidIcons: liquidIcons,
  );

  @override
  bool operator ==(Object other) =>
      other is CustomNebulaTheme &&
      other.schema == schema &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.treatment == treatment &&
      other.seed == seed &&
      other.accent == accent &&
      other.surface == surface &&
      other.surfaceContainerLowest == surfaceContainerLowest &&
      other.surfaceContainerLow == surfaceContainerLow &&
      other.surfaceContainer == surfaceContainer &&
      other.surfaceContainerHigh == surfaceContainerHigh &&
      other.surfaceContainerHighest == surfaceContainerHighest &&
      other.outlineVariant == outlineVariant &&
      other.glow == glow &&
      other.crystalEdge == crystalEdge &&
      other.crystalHighlight == crystalHighlight &&
      listEquals(other.crystalBody, crystalBody) &&
      other.liquidIcons == liquidIcons;

  @override
  int get hashCode => Object.hashAll([
    schema,
    id,
    name,
    description,
    treatment,
    seed,
    accent,
    surface,
    surfaceContainerLowest,
    surfaceContainerLow,
    surfaceContainer,
    surfaceContainerHigh,
    surfaceContainerHighest,
    outlineVariant,
    glow,
    crystalEdge,
    crystalHighlight,
    Object.hashAll(crystalBody),
    liquidIcons,
  ]);
}

/// Base template for manual or AI-assisted editing of custom Nebula themes.
///
/// Copy this JSON, edit the colors and treatment, then import it from
/// Ajustes → Nebula Engine → Temas personalizados.
const kCustomNebulaThemeTemplate = '''{
  "schema": 1,
  "id": "my_custom_theme",
  "name": "Mi tema personalizado",
  "description": "Descripción opcional del tema",
  "treatment": "flat",
  "seed": "#FF0000",
  "accent": "#FF0000",
  "surface": "#FF000000",
  "surfaceContainerLowest": "#FF000000",
  "surfaceContainerLow": "#FF121212",
  "surfaceContainer": "#FF1A1A1A",
  "surfaceContainerHigh": "#FF222222",
  "surfaceContainerHighest": "#FF2A2A2A",
  "outlineVariant": "#FF3A3A3A",
  "glow": "#FF0000",
  "crystalEdge": "#FF0000",
  "crystalHighlight": "#FF0000",
  "crystalBody": [
    "#FF0000",
    "#FF330000",
    "#FF660000",
    "#FF990000"
  ],
  "liquidIcons": false
}''';
