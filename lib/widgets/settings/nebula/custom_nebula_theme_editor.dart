import 'dart:convert';

import 'package:aves/theme/nebula/nebula_custom_theme.dart';
import 'package:aves/theme/nebula/nebula_palette.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart';

// Editor de temas Nebula personalizados.
// Permite crear un tema nuevo a partir de la plantilla base o editar uno existente.
class CustomNebulaThemeEditor extends StatefulWidget {
  final String template;
  final void Function(CustomNebulaTheme) onSave;

  const CustomNebulaThemeEditor({
    super.key,
    required this.template,
    required this.onSave,
  });

  @override
  State<CustomNebulaThemeEditor> createState() => _CustomNebulaThemeEditorState();
}

class _CustomNebulaThemeEditorState extends State<CustomNebulaThemeEditor> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _seedController = TextEditingController();
  final _accentController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _glowController = TextEditingController();
  NebulaSurfaceTreatment _treatment = NebulaSurfaceTreatment.flat;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    // Try to parse the template as a starting point
    try {
      final json = jsonDecode(widget.template) as Map<String, dynamic>;
      final theme = CustomNebulaTheme.fromJson(json);
      if (mounted) setState(() {
        _idController.text = theme.id;
        _nameController.text = theme.name;
        _descController.text = theme.description ?? '';
        _seedController.text = '#${theme.seed.value.toRadixString(16).padLeft(8, '0').substring(2)}';
        _accentController.text = '#${theme.accent.value.toRadixString(16).padLeft(8, '0').substring(2)}';
        _surfaceController.text = '#${theme.surface.value.toRadixString(16).padLeft(8, '0').substring(2)}';
        _glowController.text = '#${theme.glow.value.toRadixString(16).padLeft(8, '0').substring(2)}';
        _treatment = theme.treatment;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _seedController.dispose();
    _accentController.dispose();
    _surfaceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color _parseColor(String? text, Color fallback) {
    if (text == null || text.isEmpty) return fallback;
    try {
      return Color.parse(text);
    } catch (_) {
      return fallback;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final seed = _parseColor(_seedController.text, const Color(0xFF000000));
    final accent = _parseColor(_accentController.text, const Color(0xFF000000));
    final surface = _parseColor(_surfaceController.text, const Color(0xFF000000));
    final glow = _parseColor(_glowController.text, const Color(0xFF000000));

    final theme = CustomNebulaTheme(
      schema: 1,
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      treatment: _treatment,
      seed: seed,
      accent: accent,
      surface: surface,
      surfaceContainerLowest: surface.withValues(alpha: .95),
      surfaceContainerLow: surface.withValues(alpha: .9),
      surfaceContainer: surface.withValues(alpha: .85),
      surfaceContainerHigh: surface.withValues(alpha: .8),
      surfaceContainerHighest: surface.withValues(alpha: .75),
      outlineVariant: surface.withValues(alpha: .6),
      glow: glow,
      crystalEdge: glow.withValues(alpha: .8),
      crystalHighlight: glow.withValues(alpha: .5),
      crystalBody: [
        glow.withValues(alpha: .9),
        glow.withValues(alpha: .7),
        glow.withValues(alpha: .5),
        glow.withValues(alpha: .3),
      ],
      liquidIcons: true,
    );

    widget.onSave(theme);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        title: Text('Cargando plantilla...'),
        content: CircularProgressIndicator(),
      );
    }

    return AlertDialog(
      title: const Text('Nuevo tema Nebula'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'ID (tema)',
                    hintText: 'mi_tema',
                    helperText: 'Solo letras minúsculas, dígitos y guiones bajos',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'ID requerido';
                    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v)) {
                      return 'Solo letras minúsculas, dígitos y guiones bajos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Mi tema personalizado',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Nombre requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Descripción del tema',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Colores', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _ColorField(
                  label: 'Semilla (seed)',
                  controller: _seedController,
                ),
                const SizedBox(height: 8),
                _ColorField(
                  label: 'Acento',
                  controller: _accentController,
                ),
                const SizedBox(height: 8),
                _ColorField(
                  label: 'Superficie',
                  controller: _surfaceController,
                ),
                const SizedBox(height: 8),
                _ColorField(
                  label: 'Brillo (glow)',
                  controller: _glowController,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<NebulaSurfaceTreatment>(
                  value: _treatment,
                  decoration: const InputDecoration(labelText: 'Tratamiento'),
                  items: NebulaSurfaceTreatment.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _treatment = v!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Campo de entrada de color hexadecimal.
class _ColorField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _ColorField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: '#RRGGBB',
        prefixIcon: const Icon(Icons.color_lens),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Color requerido';
        try {
          Color.parse(v);
        } catch (_) {
          return 'Color inválido (#RRGGBB)';
        }
        return null;
      },
    );
  }
}
