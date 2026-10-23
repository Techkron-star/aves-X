import 'package:aves/model/security/failsafe.dart';
import 'package:aves/model/security/failsafe_config.dart';
import 'package:aves/model/security/failsafe_voice.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/failsafe_badge.dart';
import 'package:aves/widgets/dialogs/aves_confirmation_dialog.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/security/security.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// System Failsafe options. The Failsafe itself (error diagnosis, safe mode) cannot be turned off.
class FailsafeSection extends SettingsSection {
  static const routeName = '/settings/failsafe';

  @override
  String get key => 'failsafe';

  @override
  Widget icon(BuildContext context) => SettingsTileLeading(
    icon: AIcons.security,
    color: context.select<AvesColorsData, Color>((v) => v.security),
  );

  @override
  String title(BuildContext context) => context.l10n.settingsFailsafeSectionTitle;

  @override
  Future<List<SettingsTile>> tiles(BuildContext context) => Future.value([SafeModeGuardTile(_FailsafeOptionsTile())]);

  static Future<void> open(BuildContext context) async {
    final section = FailsafeSection();
    await Navigator.maybeOf(context)?.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => AvesScaffold(
          appBar: AppBar(title: Text(section.title(context).toUpperCase())),
          body: SafeArea(
            child: ValueListenableBuilder<bool>(
              valueListenable: failsafe.safeMode,
              // security options cannot be lowered in safe mode
              builder: (context, safe, child) => AbsorbPointer(absorbing: safe, child: Opacity(opacity: safe ? .45 : 1, child: child)),
              child: const SingleChildScrollView(child: _FailsafeOptions()),
            ),
          ),
        ),
      ),
    );
  }
}

// all the Fail-Safe options, as the content of the (expandable) section
class _FailsafeOptionsTile extends SettingsTile {
  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => context.l10n.settingsFailsafeSectionTitle;

  @override
  Widget build(BuildContext context) => const _FailsafeOptions();
}

class _FailsafeOptions extends StatefulWidget {
  const _FailsafeOptions();

  @override
  State<_FailsafeOptions> createState() => _FailsafeOptionsState();
}

class _FailsafeOptionsState extends State<_FailsafeOptions> {
  bool _lockdown = true;
  bool _nuke = false;
  bool _voice = true;
  int _maxMinutes = FailsafeConfig.recommendedMaxMinutes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lockdown = await FailsafeConfig.lockdownEnabled;
    final nuke = await FailsafeConfig.nukeOnFailures;
    final max = await FailsafeConfig.maxMinutes;
    final voice = await FailsafeConfig.voiceEnabled;
    if (!mounted) return;
    setState(() {
      _lockdown = lockdown;
      _nuke = nuke;
      _maxMinutes = max;
      _voice = voice;
    });
  }

  String _format(BuildContext context, int minutes) {
    final l10n = context.l10n;
    if (minutes >= 60 && minutes % 60 == 0) return l10n.failsafeHours(minutes ~/ 60);
    return l10n.failsafeMinutes(minutes);
  }

  Future<void> _pickMax(BuildContext context) async {
    final l10n = context.l10n;
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.failsafeMaxCooldownTitle),
        children: [
          for (final m in FailsafeConfig.maxMinutesOptions)
            ListTile(
              title: Text(m == FailsafeConfig.recommendedMaxMinutes ? '${_format(context, m)} (${l10n.failsafeRecommended})' : _format(context, m)),
              trailing: m == _maxMinutes ? const Icon(Icons.check) : null,
              onTap: () => Navigator.maybeOf(context)?.pop(m),
            ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    if (picked > FailsafeConfig.warnAboveMinutes) {
      if (!await showConfirmationDialog(context: context, message: l10n.failsafeTooLongWarning)) return;
    }
    await FailsafeConfig.setMaxMinutes(picked);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FailsafeBadge(),
        const Divider(),
        SwitchListTile(
          title: Text(l10n.failsafeLockdownOption),
          subtitle: Text(l10n.failsafeLockdownOptionSubtitle),
          value: _lockdown,
          onChanged: (v) async {
            await FailsafeConfig.setLockdownEnabled(v);
            await _load();
          },
        ),
        ListTile(
          title: Text(l10n.failsafeMaxCooldownTitle),
          subtitle: Text('${_format(context, _maxMinutes)}. ${l10n.failsafeMaxCooldownSubtitle}'),
          onTap: () => _pickMax(context),
        ),
        SwitchListTile(
          title: Text(l10n.failsafeNukeOption),
          subtitle: Text(l10n.failsafeNukeOptionSubtitle),
          value: _nuke,
          onChanged: (v) async {
            if (v && !await showConfirmationDialog(context: context, message: l10n.failsafeNukeConfirm)) return;
            await FailsafeConfig.setNukeOnFailures(v);
            await _load();
          },
        ),
        SwitchListTile(
          title: Text(l10n.failsafeVoiceOption),
          subtitle: Text(l10n.failsafeVoiceOptionSubtitle),
          value: _voice,
          onChanged: (v) async {
            await FailsafeConfig.setVoiceEnabled(v);
            await _load();
          },
        ),
        ListTile(
          title: Text(l10n.failsafeVoiceTest),
          leading: const Icon(Icons.volume_up_outlined),
          onTap: () async {
            final status = await FailsafeVoice.say(l10n.failsafeBuddy1, force: true);
            if (FailsafeVoice.isFailure(status) && context.mounted) {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(FailsafeVoice.describe(l10n, status))));
            }
          },
        ),
        SwitchListTile(
          title: Text(l10n.failsafeComicDialogs),
          subtitle: Text(l10n.failsafeComicDialogsSubtitle),
          value: context.select<Settings, bool>((v) => v.failsafeComicDialogs),
          onChanged: (v) => settings.failsafeComicDialogs = v,
        ),

      ],
    );
  }
}
