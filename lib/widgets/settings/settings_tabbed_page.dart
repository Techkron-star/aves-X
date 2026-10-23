import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/accessibility/accessibility.dart';
import 'package:aves/widgets/settings/display/display.dart';
import 'package:aves/widgets/settings/language/language.dart';
import 'package:aves/widgets/settings/navigation/navigation.dart';
import 'package:aves/widgets/settings/nebula/nebula_section.dart';
import 'package:aves/widgets/settings/avesx/avesx_section.dart';
import 'package:aves/widgets/settings/privacy/privacy.dart';
import 'package:aves/widgets/settings/security/failsafe_section.dart';
import 'package:aves/widgets/settings/security/security.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves/widgets/settings/thumbnails/thumbnails.dart';
import 'package:aves/widgets/settings/video/video.dart';
import 'package:aves/widgets/settings/viewer/viewer.dart';
import 'package:material_ui/material_ui.dart';

// Settings split in two tabs.
//
// General: the inherited gallery settings from upstream Aves.
// The Aves-X tab groups fork-specific privacy, security, Fail-Safe and Nebula
// systems together instead of scattering them among standard gallery controls.
class SettingsTabbedPage extends StatelessWidget {
  const SettingsTabbedPage({super.key});

  static final List<SettingsSection> generalSections = [
    NavigationSection(),
    ThumbnailsSection(),
    ViewerSection(),
    VideoSection(),
    LanguageSection(),
    AccessibilitySection(),
    DisplaySection(),
  ];

  static final List<SettingsSection> specialSections = [
    PrivacySection(),
    SecuritySection(),
    FailsafeSection(),
    NebulaSection(),
    AvesXSection(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.tune), text: l10n.settingsTabGeneral),
              Tab(icon: const Icon(Icons.auto_awesome), text: l10n.settingsTabSpecial),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SettingsTabContent(sections: generalSections),
                _SettingsTabContent(sections: specialSections),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTabContent extends StatefulWidget {
  final List<SettingsSection> sections;

  const _SettingsTabContent({required this.sections});

  @override
  State<_SettingsTabContent> createState() => _SettingsTabContentState();
}

class _SettingsTabContentState extends State<_SettingsTabContent> {
  // Section currently expanded, shared by the tiles of this tab so that only
  // one section stays open at a time.
  final ValueNotifier<String?> _expandedNotifier = ValueNotifier(null);

  @override
  void dispose() {
    _expandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: widget.sections.map((v) => v.build(context, _expandedNotifier)).toList(),
    );
  }
}
