import 'package:aves/widgets/common/basic/feature_sticker.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_confirmation_dialog.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/common/tiles/switch_list.dart';
import 'package:aves/widgets/settings/display/display.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// Options that may hurt performance or stability. Opening this section shows a warning first.
class ExperimentalSection extends SettingsSection {
  @override
  String get key => 'experimental';

  @override
  Widget icon(BuildContext context) => SettingsTileLeading(
    icon: AIcons.experimental,
    color: context.select<AvesColorsData, Color>((v) => v.experimental),
  );

  @override
  String title(BuildContext context) => context.l10n.settingsExperimentalSectionTitle;

  @override
  Future<List<SettingsTile>> tiles(BuildContext context) => Future.value([
    SettingsTileDisplayBatGlass(),
    SettingsTileExperimentalGlassEverywhere(),
  ]);

  // expandable like the other sections, but opening it shows a warning first (once per app session)
  @override
  Widget build(BuildContext sectionContext, ValueNotifier<String?> expandedNotifier) {
    return _ExperimentalGate(
      sectionKey: key,
      expandedNotifier: expandedNotifier,
      child: super.build(sectionContext, expandedNotifier),
    );
  }
}

class _ExperimentalGate extends StatefulWidget {
  final String sectionKey;
  final ValueNotifier<String?> expandedNotifier;
  final Widget child;

  const _ExperimentalGate({required this.sectionKey, required this.expandedNotifier, required this.child});

  @override
  State<_ExperimentalGate> createState() => _ExperimentalGateState();
}

class _ExperimentalGateState extends State<_ExperimentalGate> {
  static bool _accepted = false;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    widget.expandedNotifier.addListener(_onExpandedChanged);
  }

  @override
  void dispose() {
    widget.expandedNotifier.removeListener(_onExpandedChanged);
    super.dispose();
  }

  Future<void> _onExpandedChanged() async {
    if (widget.expandedNotifier.value != widget.sectionKey || _accepted || _asking) return;
    _asking = true;
    final accepted = await showConfirmationDialog(
      context: context,
      message: context.l10n.experimentalWarningMessage,
      ok: context.l10n.riskWarningContinue,
    );
    _asking = false;
    if (!mounted) return;
    if (accepted) {
      _accepted = true;
    } else if (widget.expandedNotifier.value == widget.sectionKey) {
      // declined: collapse the section again
      widget.expandedNotifier.value = null;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class SettingsTileExperimentalGlassEverywhere extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.glassEverywhereKey];

  @override
  String title(BuildContext context) => context.l10n.settingsGlassEverywhere;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.glassEverywhere,
    onChanged: (v) => settings.glassEverywhere = v,
    title: title,
    subtitle: (context) => context.l10n.settingsGlassEverywhereSubtitle,
    sticker: const FeatureSticker(kind: StickerKind.experimental),
  );
}
