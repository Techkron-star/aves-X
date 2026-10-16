import 'dart:async';

import 'package:aves/model/security/master_code.dart';
import 'package:aves/model/security/nuke.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/settings/privacy/app_lock_page.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/vaults/vaults.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/view/view.dart';
import 'package:aves/widgets/collection/entry_set_action_delegate.dart';
import 'package:aves/widgets/common/action_mixins/secret_lock.dart';
import 'package:aves/widgets/common/action_mixins/permission_aware.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_list_subtitle.dart';
import 'package:aves/widgets/dialogs/aves_confirmation_dialog.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/common/tiles/sub_page.dart';
import 'package:aves/widgets/settings/common/tiles/switch_list.dart';
import 'package:aves/widgets/settings/privacy/access_grants_page.dart';
import 'package:aves/widgets/settings/privacy/advanced_vault_security_page.dart';
import 'package:aves/widgets/settings/privacy/hidden_items_page.dart';
import 'package:aves/widgets/settings/privacy/permissions/permissions_tile.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class PrivacySection extends SettingsSection {
  @override
  String get key => 'privacy';

  @override
  Widget icon(BuildContext context) => SettingsTileLeading(
    icon: AIcons.privacy,
    color: context.select<AvesColorsData, Color>((v) => v.privacy),
  );

  @override
  String title(BuildContext context) => context.l10n.settingsPrivacySectionTitle;

  @override
  Future<List<SettingsTile>> tiles(BuildContext context) async {
    return [
      SettingsTilePermissions(),
      SettingsTilePrivacyHiddenItems(),
      if (!settings.useTvLayout) SettingsTilePrivacyStorageAccess(),
      if (!settings.useTvLayout) SettingsTilePrivacyEnableBin(),
      if (!settings.useTvLayout) SettingsTilePrivacyBinLock(),
      if (!settings.useTvLayout) SettingsTilePrivacyRevealLock(),
      if (!settings.useTvLayout) SettingsTilePrivacyAdvancedVaults(),
      if (!settings.useTvLayout) SettingsTilePrivacyAppLock(),
      if (!settings.useTvLayout) SettingsTilePrivacyMasterCode(),
      if (!settings.useTvLayout) SettingsTilePrivacyNukeVaults(),
      SettingsTilePrivacySaveSearchHistory(),
      if (!settings.useTvLayout) SettingsTilePrivacyAutoExportSettings(),
    ];
  }
}

class SettingsTilePrivacyAutoExportSettings extends SettingsTile with PermissionAwareMixin {
  @override
  List<String> get settingKeys => [SettingKeys.autoExportPathKey];

  @override
  String title(BuildContext context) => context.l10n.settingsAutoExportSettings;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.autoExportPath != null,
    onChanged: (v) async {
      if (v) {
        if (!await checkSystemFilePickerEnabled(context)) return;

        final dirPath = await storagePermissionService.requestSafAnyDirectoryAccess();
        if (dirPath == null) return;

        settings.autoExportPath = dirPath;
      } else {
        settings.autoExportPath = null;
      }
    },
    title: title,
    subtitle: (_) => settings.autoExportPath,
  );
}

class SettingsTilePrivacySaveSearchHistory extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.saveSearchHistoryKey];

  @override
  String title(BuildContext context) => context.l10n.settingsSaveSearchHistory;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.saveSearchHistory,
    onChanged: (v) {
      settings.saveSearchHistory = v;
      if (!v) {
        settings.searchHistory = [];
      }
    },
    title: title,
  );
}

class SettingsTilePrivacyEnableBin extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.enableBinKey];

  @override
  String title(BuildContext context) => context.l10n.settingsEnableBin;

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.enableBin,
    onChanged: (v) => setBinUsage(context, v),
    title: title,
    subtitle: (context) => context.l10n.settingsEnableBinSubtitle,
  );

  static Future<bool> setBinUsage(BuildContext context, bool enabled) async {
    final l10n = context.l10n;
    if (!enabled) {
      if (vaults.all.any((v) => v.useBin)) {
        await showWarningDialog(
          context: context,
          message: l10n.vaultBinUsageDialogMessage,
        );
        return false;
      }

      final source = context.read<CollectionSource>();
      final trashedEntries = source.trashedEntries;
      if (trashedEntries.isNotEmpty) {
        if (!await showConfirmationDialog(
          context: context,
          message: l10n.settingsDisablingBinWarningDialogMessage,
          ok: l10n.applyButtonLabel,
        )) {
          return false;
        }

        // delete forever trashed items
        await EntrySetActionDelegate().doDelete(
          context: context,
          entries: trashedEntries,
          enableBin: false,
        );

        // in case of failure or cancellation
        if (source.trashedEntries.isNotEmpty) return false;
      }

      settings.searchHistory = [];
    }

    settings.enableBin = enabled;
    return true;
  }
}

class SettingsTilePrivacyBinLock extends SettingsTile {
  @override
  List<String> get settingKeys => []; // kept in the secure store, not in the settings

  @override
  String title(BuildContext context) => SecretLock.bin.title(context);

  @override
  Widget build(BuildContext context) => _SecretLockListTile(lock: SecretLock.bin);
}

class SettingsTilePrivacyRevealLock extends SettingsTile {
  @override
  List<String> get settingKeys => []; // kept in the secure store, not in the settings

  @override
  String title(BuildContext context) => SecretLock.reveal.title(context);

  @override
  Widget build(BuildContext context) => _SecretLockListTile(lock: SecretLock.reveal);
}

class SettingsTilePrivacyAdvancedVaults extends SettingsTile {
  @override
  List<String> get settingKeys => []; // kept in the secure store, not in the settings

  @override
  String title(BuildContext context) => context.l10n.settingsAdvancedVaultSecurity;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    title: title,
    routeName: AdvancedVaultSecurityPage.routeName,
    builder: (context) => const AdvancedVaultSecurityPage(),
  );
}

class SettingsTilePrivacyAppLock extends SettingsTile {
  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => context.l10n.settingsAppLock;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    title: title,
    routeName: AppLockPage.routeName,
    builder: (context) => const AppLockPage(),
  );
}

class SettingsTilePrivacyMasterCode extends SettingsTile {
  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => context.l10n.settingsMasterCode;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title(context)),
    subtitle: Text(context.l10n.settingsMasterCodeSubtitle),
    onTap: () async {
      if (await MasterCode.isSet) {
        if (context.mounted) await MasterCode.change(context);
      } else {
        await MasterCode.ensure(context);
      }
    },
  );
}

class SettingsTilePrivacyNukeVaults extends SettingsTile {
  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => context.l10n.settingsNukeVaults;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title(context), style: TextStyle(color: Theme.of(context).colorScheme.error)),
    subtitle: Text(context.l10n.settingsNukeVaultsSubtitle),
    onTap: () async {
      // the Master Code is the confirmation: no extra step once it is correct
      final source = context.read<CollectionSource>();
      if (!await MasterCode.require(context)) return;
      await Nuke.nukeAllVaults(source: source);
    },
  );
}

class _SecretLockListTile extends StatefulWidget {
  final SecretLock lock;

  const _SecretLockListTile({required this.lock});

  @override
  State<_SecretLockListTile> createState() => _SecretLockListTileState();
}

class _SecretLockListTileState extends State<_SecretLockListTile> {
  late Future<VaultLockType?> _lockTypeLoader;

  @override
  void initState() {
    super.initState();
    _lockTypeLoader = widget.lock.getLockType();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VaultLockType?>(
      future: _lockTypeLoader,
      builder: (context, snapshot) {
        final lockType = snapshot.data;
        return ListTile(
          title: Text(widget.lock.title(context)),
          subtitle: AvesListSubtitle(lockType?.getText(context) ?? context.l10n.settingsBinLockOff),
          onTap: () async {
            await widget.lock.configure(context);
            if (!mounted) return;

            setState(() => _lockTypeLoader = widget.lock.getLockType());
          },
        );
      },
    );
  }
}

class SettingsTilePrivacyHiddenItems extends SettingsTile {
  @override
  List<String> get settingKeys => HiddenItemsPage.settingKeys;

  @override
  String title(BuildContext context) => context.l10n.settingsHiddenItemsTile;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    title: title,
    routeName: HiddenItemsPage.routeName,
    builder: (context) => const HiddenItemsPage(),
  );
}

class SettingsTilePrivacyStorageAccess extends SettingsTile {
  @override
  List<String> get settingKeys => []; // no editable settings

  @override
  String title(BuildContext context) => context.l10n.settingsStorageAccessTile;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    title: title,
    routeName: StorageAccessPage.routeName,
    builder: (context) => const StorageAccessPage(),
  );
}
