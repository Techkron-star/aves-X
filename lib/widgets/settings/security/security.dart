import 'package:aves/widgets/common/basic/feature_sticker.dart';
import 'package:aves/model/security/bat_curity.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/danger_confirmation.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/privacy/privacy.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// "Bat-curity": security options, separated from privacy ones.
class SecuritySection extends SettingsSection {
  static const routeName = '/settings/security';

  @override
  String get key => 'security';

  @override
  Widget icon(BuildContext context) => SettingsTileLeading(
    icon: AIcons.security,
    color: context.select<AvesColorsData, Color>((v) => v.security),
  );

  @override
  String title(BuildContext context) => context.l10n.settingsSecuritySectionTitle;

  @override
  Future<List<SettingsTile>> tiles(BuildContext context) => Future.value([
    SettingsTileSecurityHashing(),
    SettingsTileSecurityVaultEncryption(),
    SettingsTileSecurityForceDecrypt(),
    SettingsTilePrivacyGroup(PrivacyGroup.appLock),
    SettingsTilePrivacyGroup(PrivacyGroup.destruction),
  ]);

  // also used by the offer shown after the creation of the Master Code
  Future<void> open(BuildContext context) async {
    final items = await tiles(context);
    if (!context.mounted) return;
    await Navigator.maybeOf(context)?.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => AvesScaffold(
          appBar: AppBar(title: Text(title(context).toUpperCase())),
          body: SafeArea(
            child: ListView(children: items.map((tile) => tile.build(context)).toList()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext sectionContext, ValueNotifier<String?> expandedNotifier) {
    return Builder(
      builder: (context) => ListTile(
        key: const Key('section-security'),
        leading: icon(context),
        title: Text(title(context).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => open(context),
      ),
    );
  }
}

class SettingsTileSecurityHashing extends SettingsTile {
  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => context.l10n.batCurityHashingTitle;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: batCurity,
    builder: (context, _) {
      final l10n = context.l10n;
      final error = Theme.of(context).colorScheme.error;
      return SwitchListTile(
        title: Text(title(context)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.batCurityHashingSubtitle),
            const SizedBox(height: 4),
            Text(l10n.batCurityOnlyIfYouKnow, style: TextStyle(color: error, fontWeight: FontWeight.w600)),
          ],
        ),
        value: batCurity.hashingEnabled,
        onChanged: (value) async {
          if (value && !await showRiskWarning(context, l10n.batCurityHashingWarning)) return;
          if (!context.mounted) return;
          await batCurity.setHashing(context, value);
        },
      );
    },
  );
}

class SettingsTileSecurityVaultEncryption extends SettingsTile {
  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => context.l10n.batCurityVaultEncTitle;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: batCurity,
    builder: (context, _) {
      final l10n = context.l10n;
      final error = Theme.of(context).colorScheme.error;
      return SwitchListTile(
        title: Row(
          children: [
            Flexible(child: Text(title(context))),
            const SizedBox(width: 8),
            const FeatureSticker(kind: StickerKind.experimental),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.batCurityVaultEncSubtitle),
            const SizedBox(height: 4),
            Text(l10n.batCurityOnlyIfYouKnow, style: TextStyle(color: error, fontWeight: FontWeight.w600)),
          ],
        ),
        value: batCurity.vaultEncryption,
        onChanged: (value) async {
          if (value && !await showRiskWarning(context, l10n.batCurityVaultEncWarning)) return;
          if (!context.mounted) return;
          final ok = await batCurity.setVaultEncryption(context, value);
          if (!ok && !value && context.mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l10n.batCurityVaultEncDisableFailed)));
          }
        },
      );
    },
  );
}

class SettingsTileSecurityForceDecrypt extends SettingsTile {
  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => context.l10n.batCurityForceDecryptTitle;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title(context)),
    subtitle: Text(context.l10n.batCurityForceDecryptSubtitle),
    onTap: () => batCurity.forceDecryptAll(context),
  );
}
