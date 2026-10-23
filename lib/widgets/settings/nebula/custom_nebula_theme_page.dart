import 'dart:convert';

import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_custom_theme.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/nebula/custom_nebula_theme_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomNebulaThemePage extends StatefulWidget {
  static const routeName = '/settings/nebula/custom_themes';

  const CustomNebulaThemePage({super.key});

  @override
  State<CustomNebulaThemePage> createState() => _CustomNebulaThemePageState();
}

class _CustomNebulaThemePageState extends State<CustomNebulaThemePage> {
  List<CustomNebulaTheme> _themes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await settings.refreshCustomThemes();
    final themes = await settings.loadCustomThemes();
    if (mounted) {
      setState(() {
        _themes = themes;
        _loading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    await settings.deleteCustomTheme(id);
    await _reload();
  }

  Future<void> _import(String json) async {
    try {
      await settings.importCustomTheme(json);
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.settingsCustomNebulaThemeImported)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.settingsCustomNebulaThemeImportError}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsCustomNebulaTheme)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _themes.isEmpty
              ? _EmptyState(onImport: _import, onNew: () => _createNew(), showImportDialog: _showImportDialog)
              : ListView(
                  children: [
                    for (final theme in _themes)
                      _ThemeCard(
                        theme: theme,
                        isActive: settings.customNebulaTheme?.id == theme.id,
                        onTap: () async {
                          settings.customNebulaTheme = theme;
                          await _reload();
                        },
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text(l10n.settingsCustomNebulaThemeDeleteTitle),
                              content: Text('${l10n.settingsCustomNebulaThemeDeleteMessage} "${theme.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  child: Text(l10n.deleteButtonLabel, style: const TextStyle(color: Color(0xFFFF0000))),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await _delete(theme.id);
                          }
                        },
                        onExport: () {
                          final json = settings.exportCustomTheme(theme);
                          _copyToClipboard(context, json, l10n.settingsCustomNebulaThemeExported);
                        },
                      ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: Text(l10n.settingsCustomNebulaThemeNew),
                      subtitle: Text(l10n.settingsCustomNebulaThemeNewSubtitle),
                      onTap: () => _createNew(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.import_export),
                      title: Text(l10n.settingsCustomNebulaThemeImport),
                      subtitle: Text(l10n.settingsCustomNebulaThemeImportSubtitle),
                      onTap: () => _showImportDialog(context, l10n, _import),
                    ),
                  ],
                ),
    );
  }

  Future<void> _createNew() async {
    final theme = await showDialog<CustomNebulaTheme>(
      context: context,
      builder: (dialogContext) => CustomNebulaThemeEditor(
        template: settings.customNebulaThemeTemplate,
        onSave: (t) => Navigator.pop(dialogContext, t),
      ),
    );
    if (theme != null && mounted) {
      await settings.saveCustomTheme(theme);
      await _reload();
    }
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showImportDialog(BuildContext context, l10n, void Function(String) onImport) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsCustomNebulaThemeImport),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: l10n.settingsCustomNebulaThemeImportHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () {
              onImport(controller.text);
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.settingsCustomNebulaThemeImportButton),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function(String) onImport;
  final VoidCallback onNew;
  final void Function(BuildContext, AppLocalizations, Future<void> Function(String)) showImportDialog;

  const _EmptyState({
    required this.onImport,
    required this.onNew,
    required this.showImportDialog,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.palette_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(l10n.settingsCustomNebulaThemeEmptyTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.settingsCustomNebulaThemeEmptySubtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onNew,
                icon: const Icon(Icons.add),
                label: Text(l10n.settingsCustomNebulaThemeNew),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => showImportDialog(context, l10n, onImport),
                icon: const Icon(Icons.import_export),
                label: Text(l10n.settingsCustomNebulaThemeImport),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final CustomNebulaTheme theme;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  const _ThemeCard({
    required this.theme,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? scheme.primaryContainer.withValues(alpha: .3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? scheme.primary : scheme.outlineVariant.withValues(alpha: .3)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.seed,
            child: Text(theme.name.isNotEmpty ? theme.name[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(
            theme.name,
            style: TextStyle(fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? scheme.onPrimaryContainer : null),
          ),
          subtitle: theme.description?.isNotEmpty == true
              ? Text(theme.description!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
              : null,
          trailing: Wrap(
            spacing: 8,
            children: [
              IconButton(
                icon: const Icon(Icons.description),
                tooltip: context.l10n.settingsCustomNebulaThemeExport,
                onPressed: onExport,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: context.l10n.settingsCustomNebulaThemeDelete,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
