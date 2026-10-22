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
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:aves_model/aves_model.dart';
import 'package:provider/provider.dart';

class SettingsTabbedPage extends StatefulWidget {
  const SettingsTabbedPage({super.key});

  @override
  State<SettingsTabbedPage> createState() => _SettingsTabbedPageState();
}

class _SettingsTabbedPageState extends State<SettingsTabbedPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ValueNotifier<String?> _expandedNotifier = ValueNotifier(null);

  static final List<SettingsSection> _generalSections = [
    NavigationSection(),
    ThumbnailsSection(),
    ViewerSection(),
    VideoSection(),
    LanguageSection(),
    PrivacySection(),
    SecuritySection(),
    FailsafeSection(),
    AccessibilitySection(),
    DisplaySection(),
    ExperimentalSection(),
  ];

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPageTitle)),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: const Icon(Icons.tune), text: l10n.settingsTabGeneral),
              Tab(icon: const Icon(Icons.settings_applications), text: l10n.settingsTabSpecial),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SettingsTabContent(sections: _generalSections, expandedNotifier: _expandedNotifier),
                _SettingsTabContent(sections: _specialSections, expandedNotifier: _expandedNotifier),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTabContent extends StatelessWidget {
  final List<SettingsSection> sections;
  final ValueNotifier<String?> expandedNotifier;

  const _SettingsTabContent({required this.sections, required this.expandedNotifier});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: sections.map((v) => v.build(context, expandedNotifier)).toList(),
    );
  }
}
