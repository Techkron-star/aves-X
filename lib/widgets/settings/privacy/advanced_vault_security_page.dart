import 'package:aves/model/security/master_code.dart';
import 'package:aves/model/advanced_privacy.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/vaults/details.dart';
import 'package:aves/model/vaults/vaults.dart';
import 'package:aves/view/view.dart';
import 'package:aves/widgets/common/action_mixins/secret_lock.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/single_selection.dart';
import 'package:aves_model/aves_model.dart';
import 'package:aves_utils/aves_utils.dart';
import 'package:material_ui/material_ui.dart';

// Extra vault protections:
// - option to hide vaults from the album list, until hidden items are revealed
// - per vault: a second lock, and a block on sharing items to other apps
class AdvancedVaultSecurityPage extends StatelessWidget {
  static const routeName = '/settings/advanced_vault_security';

  const AdvancedVaultSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !settings.useTvLayout,
        title: Text(l10n.settingsAdvancedVaultSecurity),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge({advancedPrivacy, vaults.lockStateChangeNotifier, vaults.contentChangeNotifier}),
          builder: (context, child) {
            final allVaults = vaults.all.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            return ListView(
              children: [
                SwitchListTile(
                  value: advancedPrivacy.hideVaults,
                  onChanged: advancedPrivacy.setHideVaults,
                  title: Text(l10n.advancedVaultsHideFromList),
                  subtitle: Text(l10n.advancedVaultsHideFromListSubtitle),
                ),
                const Divider(),
                if (allVaults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.advancedVaultsEmpty),
                  ),
                ...allVaults.map(
                  (details) => ListTile(
                    title: Text(details.name),
                    subtitle: Text(_summary(context, details)),
                    onTap: () => _configure(context, details),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _summary(BuildContext context, VaultDetails details) {
    final l10n = context.l10n;
    final secondLock = advancedPrivacy.secondLockType(details.name);
    final parts = [
      if (secondLock != null) '${l10n.advancedVaultsSecondLock}: ${secondLock.getText(context)}',
      if (advancedPrivacy.blocksSharing(details.name)) l10n.advancedVaultsSharingTitle,
    ];
    return parts.isEmpty ? l10n.advancedVaultsDefaultSummary : parts.join(' · ');
  }

  Future<void> _configure(BuildContext context, VaultDetails details) async {
    final l10n = context.l10n;
    final name = details.name;

    // changing these options requires the Master Code, then every lock of the vault
    if (!await MasterCode.require(context) || !context.mounted) return;
    final reason = l10n.authenticateToConfigureVault;
    final primaryPassKey = await SecretLock.resolvePassKey(details.passKey, details.lockType, legacyType: details.lockType);
    if (!await SecretLock.challenge(context, details.lockType, reason, primaryPassKey, resetOnSuccess: false)) return;
    final currentSecondLock = advancedPrivacy.secondLockType(name);
    if (currentSecondLock != null) {
      if (!context.mounted) return;
      final secondPassKey = await SecretLock.resolvePassKey(AdvancedPrivacy.secondPassKey(name), currentSecondLock, legacyType: currentSecondLock);
      if (!await SecretLock.challenge(context, currentSecondLock, reason, secondPassKey)) return;
    }
    if (!context.mounted) return;

    // second lock
    const none = 'none';
    final secondLockOptions = <String, String>{
      none: l10n.advancedVaultsSecondLockNone,
      // using the system authentication twice would not add any protection
      // (other lock types can be repeated, as the second secret is different from the first one)
      ...SecretLock.lockTypeOptions(context, exclude: details.lockType == VaultLockType.system ? const {VaultLockType.system} : const {}),
    };
    final secondLockChoice = await showAvesDialog<String>(
      context: context,
      builder: (context) => AvesSingleSelectionDialog<String>(
        initialValue: currentSecondLock?.name ?? none,
        options: secondLockOptions,
        title: l10n.advancedVaultsSecondLock,
      ),
      routeSettings: const RouteSettings(name: AvesSingleSelectionDialog.routeName),
    );
    if (secondLockChoice == null || !context.mounted) return;

    if (secondLockChoice == none) {
      await advancedPrivacy.setSecondLock(name, null);
    } else if (secondLockChoice != currentSecondLock?.name) {
      final type = VaultLockType.values.safeByName(secondLockChoice);
      if (type != null && await SecretLock.setPass(context, type, SecretLock.keyForType(AdvancedPrivacy.secondPassKey(name), type), l10n.authenticateToConfigureVault)) {
        await advancedPrivacy.setSecondLock(name, type);
      }
    }
    if (!context.mounted) return;

    // sharing block
    final blockSharing = await showAvesDialog<bool>(
      context: context,
      builder: (context) => AvesSingleSelectionDialog<bool>(
        initialValue: advancedPrivacy.blocksSharing(name),
        options: {
          true: l10n.advancedVaultsSharingBlocked,
          false: l10n.advancedVaultsSharingAllowed,
        },
        title: l10n.advancedVaultsSharingTitle,
      ),
      routeSettings: const RouteSettings(name: AvesSingleSelectionDialog.routeName),
    );
    if (blockSharing != null) {
      await advancedPrivacy.setSharingBlocked(name, blockSharing);
    }
  }
}
