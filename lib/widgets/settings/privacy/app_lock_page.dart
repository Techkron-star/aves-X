import 'package:aves/l10n/l10n.dart';
import 'package:aves/widgets/dialogs/danger_confirmation.dart';
import 'package:aves/model/device.dart';
import 'package:aves/model/security/app_lock.dart';
import 'package:aves/model/security/master_code.dart';
import 'package:aves/widgets/common/action_mixins/secret_lock.dart';
import 'package:aves_model/aves_model.dart';
import 'package:aves_utils/aves_utils.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/code_dialog.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/single_selection.dart';
import 'package:material_ui/material_ui.dart';

// Startup lock: App PIN, biometrics and panic PIN. Any change requires the Master Code.
class AppLockPage extends StatelessWidget {
  static const routeName = '/settings/app_lock';

  const AppLockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !settings.useTvLayout,
        title: Text(l10n.settingsAppLock),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appLock,
          builder: (context, child) {
            return ListView(
              children: [
                SwitchListTile(
                  value: appLock.enabled,
                  onChanged: (v) => v ? _configureLock(context) : _disable(context),
                  title: Text(l10n.settingsAppLock),
                  subtitle: Text(l10n.settingsAppLockSubtitle),
                ),
                if (appLock.enabled) ...[
                  ListTile(
                    title: Text(l10n.vaultDialogLockTypeLabel),
                    subtitle: Text(_lockTypeLabel(context, appLock.lockTypeName)),
                    onTap: () => _configureLock(context),
                  ),
                  if (device.canAuthenticateUser)
                    SwitchListTile(
                      value: appLock.biometricEnabled,
                      onChanged: (v) async {
                        if (await MasterCode.require(context)) await appLock.setBiometric(v);
                      },
                      title: Text(l10n.appLockUseBiometric),
                    ),
                  ListTile(
                    title: Text(l10n.appLockRelockDelay),
                    subtitle: Text(_delayLabel(l10n, appLock.relockDelay)),
                    onTap: () => _pickRelockDelay(context),
                  ),
                  if (appLock.lockTypeName == 'code') SwitchListTile(
                    value: appLock.hasPanicPin,
                    onChanged: (v) => v ? _setPanic(context) : _removePanic(context),
                    title: Text(l10n.appLockPanicPin),
                    subtitle: Text(l10n.appLockPanicPinSubtitle),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _lockTypeLabel(BuildContext context, String type) {
    if (type == 'code') return context.l10n.appLockChangePin;
    return VaultLockType.values.safeByName(type)?.getText(context) ?? context.l10n.genericFailureFeedback;
  }

  String _delayLabel(AppLocalizations l10n, Duration delay) {
    if (delay == Duration.zero) return l10n.appLockRelockImmediately;
    if (delay.inSeconds < 60) return l10n.timeSeconds(delay.inSeconds);
    return l10n.timeMinutes(delay.inMinutes);
  }

  // a longer delay lowers the protection, so any change requires the Master Code
  Future<void> _pickRelockDelay(BuildContext context) async {
    final l10n = context.l10n;
    final delay = await showAvesDialog<Duration>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.appLockRelockDelay),
        children: AppLock.relockDelayOptions
            .map(
              (v) => SimpleDialogOption(
                onPressed: () => Navigator.maybeOf(context)?.pop(v),
                child: Text(_delayLabel(l10n, v)),
              ),
            )
            .toList(),
      ),
    );
    if (delay == null || delay == appLock.relockDelay || !context.mounted) return;
    if (await MasterCode.require(context)) await appLock.setRelockDelay(delay);
  }

  Future<String?> _newCode(BuildContext context) {
    return showAvesDialog<String>(
      context: context,
      builder: (context) => const CodeDialog(needConfirmation: true),
      routeSettings: const RouteSettings(name: CodeDialog.routeName),
    );
  }

  Future<void> _configureLock(BuildContext context) async {
    if (!appLock.enabled && !await showRiskWarning(context, context.l10n.appLockEnableWarning)) return;
    if (!context.mounted || !await MasterCode.require(context) || !context.mounted) return;

    final options = <String, String>{
      'code': context.l10n.appLockChangePin,
      ...SecretLock.lockTypeOptions(context),
    };
    final choice = await showAvesDialog<String>(
      context: context,
      builder: (context) => AvesSingleSelectionDialog<String>(
        initialValue: appLock.lockTypeName,
        options: options,
        title: context.l10n.vaultDialogLockTypeLabel,
      ),
      routeSettings: const RouteSettings(name: AvesSingleSelectionDialog.routeName),
    );
    if (choice == null || !context.mounted) return;

    if (choice == 'code') {
      final code = await _newCode(context);
      if (code != null) await appLock.setPin(code);
      return;
    }

    final type = VaultLockType.values.safeByName(choice);
    if (type == null) return;
    if (!await SecretLock.setPass(context, type, AppLock.alternativeSecretKey, context.l10n.authenticateToConfigureVault)) return;
    await appLock.setLockType(type.name);
  }

  Future<void> _disable(BuildContext context) async {
    if (await MasterCode.require(context)) await appLock.disable();
  }

  Future<void> _setPanic(BuildContext context) async {
    if (!await showRiskWarning(context, context.l10n.appLockPanicWarning) || !context.mounted) return;
    if (!await MasterCode.require(context) || !context.mounted) return;
    final code = await _newCode(context);
    if (code == null) return;
    if (await appLock.isSameAsPin(code)) {
      if (context.mounted) await showWarningDialog(context: context, message: context.l10n.appLockPanicSameAsPin);
      return;
    }
    await appLock.setPanicPin(code);
  }

  Future<void> _removePanic(BuildContext context) async {
    if (await MasterCode.require(context)) await appLock.setPanicPin(null);
  }
}
