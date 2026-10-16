import 'package:aves/widgets/settings/privacy/auto_delete_page.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:aves/model/item_locks.dart';
import 'package:aves/widgets/dialogs/danger_confirmation.dart';
import 'package:aves/l10n/l10n.dart';
import 'dart:async';

import 'package:aves/model/security/master_code.dart';
import 'package:aves/model/security/privacy_options.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
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
      if (!settings.useTvLayout) SettingsTilePrivacyGroup(PrivacyGroup.locks),
      if (!settings.useTvLayout) SettingsTilePrivacyGroup(PrivacyGroup.vaults),
      if (!settings.useTvLayout) SettingsTilePrivacyGroup(PrivacyGroup.appLock),
      if (!settings.useTvLayout) SettingsTilePrivacyGroup(PrivacyGroup.destruction),
      if (!settings.useTvLayout) SettingsTilePrivacyAutoDelete(),
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
    leading: SettingsTileLeading(icon: Symbols.shield_lock, color: context.select<AvesColorsData, Color>((v) => v.privacy)),
    title: title,
    routeName: AdvancedVaultSecurityPage.routeName,
    builder: (context) => const AdvancedVaultSecurityPage(),
  );
}

enum PrivacyGroup { locks, vaults, appLock, destruction }

// privacy features are grouped in sub pages, each feature having its own switch where it makes sense
class SettingsTilePrivacyGroup extends SettingsTile {
  final PrivacyGroup group;

  SettingsTilePrivacyGroup(this.group);

  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) {
    final l10n = context.l10n;
    switch (group) {
      case PrivacyGroup.locks:
        return l10n.privacyGroupLocks;
      case PrivacyGroup.vaults:
        return l10n.privacyGroupVaults;
      case PrivacyGroup.appLock:
        return l10n.settingsAppLock;
      case PrivacyGroup.destruction:
        return l10n.privacyGroupDestruction;
    }
  }

  List<SettingsTile> _tiles() {
    switch (group) {
      case PrivacyGroup.locks:
        return [
          _OptionSwitchTile(PrivacyOptions.itemLocksKey, (l10n) => l10n.privacyOptionItemLocks, (l10n) => l10n.privacyOptionItemLocksSubtitle, (o) => o.itemLocks),
          SettingsTilePrivacyItemsLock(),
          _FavouritesLockTile(),
          SettingsTilePrivacyBinLock(),
          _OptionSwitchTile(PrivacyOptions.revealGestureKey, (l10n) => l10n.privacyOptionRevealGesture, (l10n) => l10n.privacyOptionRevealGestureSubtitle, (o) => o.revealGesture),
          SettingsTilePrivacyRevealLock(),
        ];
      case PrivacyGroup.vaults:
        return [SettingsTilePrivacyAdvancedVaults()];
      case PrivacyGroup.appLock:
        return [SettingsTilePrivacyAppLock()];
      case PrivacyGroup.destruction:
        return [
          SettingsTilePrivacyMasterCode(),
          _OptionSwitchTile(PrivacyOptions.strictDeleteKey, (l10n) => l10n.privacyOptionStrictDelete, (l10n) => l10n.privacyOptionStrictDeleteSubtitle, (o) => o.strictDelete),
          SettingsTilePrivacyNukeVaults(),
        ];
    }
  }

  IconData get _icon {
    switch (group) {
      case PrivacyGroup.locks:
        return Symbols.lock;
      case PrivacyGroup.vaults:
        return Symbols.shield_lock;
      case PrivacyGroup.appLock:
        return Symbols.phonelink_lock;
      case PrivacyGroup.destruction:
        return Symbols.delete_forever;
    }
  }

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    leading: SettingsTileLeading(icon: _icon, color: context.select<AvesColorsData, Color>((v) => v.privacy)),
    title: title,
    routeName: '/settings/privacy/${group.name}',
    builder: (context) => _PrivacyGroupPage(title: title(context), tiles: _tiles()),
  );
}

class _PrivacyGroupPage extends StatelessWidget {
  final String title;
  final List<SettingsTile> tiles;

  const _PrivacyGroupPage({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return AvesScaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(children: tiles.map((tile) => tile.build(context)).toList()),
      ),
    );
  }
}

class _OptionSwitchTile extends SettingsTile {
  final String key;
  final String Function(AppLocalizations l10n) _title, _subtitle;
  final bool Function(PrivacyOptions options) _value;

  _OptionSwitchTile(this.key, this._title, this._subtitle, this._value);

  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => _title(context.l10n);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: privacyOptions,
    builder: (context, _) => SwitchListTile(
      value: _value(privacyOptions),
      onChanged: (v) => privacyOptions.change(context, key, v),
      title: Text(title(context)),
      subtitle: Text(_subtitle(context.l10n)),
    ),
  );
}

class _FavouritesLockTile extends SettingsTile {
  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => context.l10n.privacyOptionLockFavourites;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: itemLocks,
    builder: (context, _) => SwitchListTile(
      value: itemLocks.favouritesMarked,
      onChanged: (v) => itemLocks.setFavouritesLocked(context, v),
      title: Text(title(context)),
      subtitle: Text(context.l10n.privacyOptionLockFavouritesSubtitle),
    ),
  );
}

class SettingsTilePrivacyItemsLock extends SettingsTile {
  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => SecretLock.items.title(context);

  @override
  Widget build(BuildContext context) => _SecretLockListTile(lock: SecretLock.items);
}

class SettingsTilePrivacyAutoDelete extends SettingsTile {
  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => context.l10n.settingsAutoDelete;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    leading: SettingsTileLeading(icon: Symbols.auto_delete, color: context.select<AvesColorsData, Color>((v) => v.privacy)),
    title: title,
    routeName: AutoDeletePage.routeName,
    builder: (context) => const AutoDeletePage(),
  );
}

class SettingsTilePrivacyAppLock extends SettingsTile {
  @override
  List<String> get settingKeys => [];

  @override
  String title(BuildContext context) => context.l10n.settingsAppLock;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    leading: SettingsTileLeading(icon: Symbols.phonelink_lock, color: context.select<AvesColorsData, Color>((v) => v.privacy)),
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
      final source = context.read<CollectionSource>();
      // warning against mistakes; then the Master Code is the confirmation
      if (!await showRiskWarning(context, context.l10n.nukeVaultsWarning)) return;
      if (!context.mounted || !await MasterCode.require(context)) return;
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
