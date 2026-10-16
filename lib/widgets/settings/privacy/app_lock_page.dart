import 'package:aves/widgets/dialogs/danger_confirmation.dart';
import 'package:aves/model/device.dart';
import 'package:aves/model/security/app_lock.dart';
import 'package:aves/model/security/master_code.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/code_dialog.dart';
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
                  onChanged: (v) => v ? _setPin(context) : _disable(context),
                  title: Text(l10n.settingsAppLock),
                  subtitle: Text(l10n.settingsAppLockSubtitle),
                ),
                if (appLock.enabled) ...[
                  ListTile(
                    title: Text(l10n.appLockChangePin),
                    onTap: () => _setPin(context),
                  ),
                  if (device.canAuthenticateUser)
                    SwitchListTile(
                      value: appLock.biometricEnabled,
                      onChanged: (v) async {
                        if (await MasterCode.require(context)) await appLock.setBiometric(v);
                      },
                      title: Text(l10n.appLockUseBiometric),
                    ),
                  SwitchListTile(
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

  Future<String?> _newCode(BuildContext context) {
    return showAvesDialog<String>(
      context: context,
      builder: (context) => const CodeDialog(needConfirmation: true),
      routeSettings: const RouteSettings(name: CodeDialog.routeName),
    );
  }

  Future<void> _setPin(BuildContext context) async {
    // the Master Code is created first if needed, and required to change an existing PIN
    if (!appLock.enabled && !await showRiskWarning(context, context.l10n.appLockEnableWarning)) return;
    if (!context.mounted || !await MasterCode.require(context) || !context.mounted) return;
    final code = await _newCode(context);
    if (code != null) await appLock.setPin(code);
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
