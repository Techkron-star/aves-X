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

/// Shared settings categories for phone and TV layouts.
/// Keep inherited gallery controls separate from Aves-X additions.
class SettingsSectionGroups {
  static final List<SettingsSection> general = [
    NavigationSection(),
    ThumbnailsSection(),
    ViewerSection(),
    VideoSection(),
    LanguageSection(),
    AccessibilitySection(),
    DisplaySection(),
  ];

  static final List<SettingsSection> avesX = [
    PrivacySection(),
    SecuritySection(),
    FailsafeSection(),
    NebulaSection(),
    AvesXSection(),
  ];

  static final List<SettingsSection> all = [...general, ...avesX];
}
