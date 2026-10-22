import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/accessibility/accessibility.dart';
import 'package:aves/widgets/settings/display/display.dart';
import 'package:aves/widgets/settings/language/language.dart';
import 'package:aves/widgets/settings/navigation/navigation.dart';
import 'package:aves/widgets/settings/nebula/custom_nebula_theme_tile.dart';
import 'package:aves/widgets/settings/nebula/nebula_section.dart';
import 'package:aves/widgets/settings/privacy/privacy.dart';
import 'package:aves/widgets/settings/security/failsafe_section.dart';
import 'package:aves/widgets/settings/security/security.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves/widgets/settings/thumbnails/thumbnails.dart';
import 'package:aves/widgets/settings/video/video.dart';
import 'package:aves/widgets/settings/viewer/viewer.dart';
import 'package:aves/widgets/settings/experimental/experimental.dart';
import 'package:flutter/material.dart' hide AppBar, Tab, TabBar, TabBarView, Icon, IconButton, PopupMenuButton, PopupMenuItem, MaterialLocalizations, Theme, Divider, ListTile, InkWell, Wrap, CircleAvatar, TextStyle, FontWeight, OutlineInputBorder, TextField, CircularProgressIndicator, TextFormField, InputDecoration, DropdownButtonFormField, DropdownMenuItem, Colors;
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:aves_model/aves_model.dart';
import 'package:provider/provider.dart';

// Página de ajustes con pestañas "General" y "Especiales".
//
// - General: ajustes base de la app (navegación, miniaturas, visor, vídeo, idioma)
// - Especiales: ajustes avanzados (Nebula, privacidad, seguridad, Fail-Safe, accesibilidad, experimental)
class SettingsTabbedPage extends StatefulWidget {
  const SettingsTabbedPage({super.key});

  @override
  State<SettingsTabbedPage> createState() => _SettingsTabbedPageState();
}

class _SettingsTabbedPageState extends State<SettingsTabbedPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ValueNotifier<String?> _expandedNotifier = ValueNotifier(null);

  // Secciones "General" (ajustes base, siempre visibles)
  static final List<SettingsSection> _generalSections = [
    NavigationSection(),
    ThumbnailsSection(),
    ViewerSection(),
    VideoSection(),
    LanguageSection(),
  ];

  // Secciones "Especiales" (ajustes únicos de Aves-X: Nebula Engine y temas personalizados)
  static final List<SettingsSection> _specialSections = [
    NebulaSection(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _expandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final animations = context.select<Settings, AccessibilityAnimations>((v) => v.accessibilityAnimations);

    return AvesScaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsPageTitle),
      ),
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            icon: const Icon(Icons.tune),
            text: l10n.settingsTabGeneral,
          ),
          Tab(
            icon: const Icon(Icons.settings_applications),
            text: l10n.settingsTabSpecial,
          ),
        ],
      ),
      body: GestureAreaProtectorStack(
        child: SafeArea(
          bottom: false,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Pestaña General
              _SettingsTabContent(
                sections: _generalSections,
                expandedNotifier: _expandedNotifier,
              ),
              // Pestaña Especiales
              _SettingsTabContent(
                sections: _specialSections,
                expandedNotifier: _expandedNotifier,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contenido de una pestaña de ajustes (General o Especiales).
class _SettingsTabContent extends StatelessWidget {
  final List<SettingsSection> sections;
  final ValueNotifier<String?> expandedNotifier;

  const _SettingsTabContent({
    required this.sections,
    required this.expandedNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final durations = context.watch<DurationsData>();

    return AnimationLimiter(
      child: SettingsListView(
        children: sections.map((v) => v.build(context, expandedNotifier)).toList(),
      ),
    );
  }
}
