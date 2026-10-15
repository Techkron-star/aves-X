import 'package:aves/model/device.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/view/view.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/password_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/pattern_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/pin_dialog.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/common.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/single_selection.dart';
import 'package:aves_model/aves_model.dart';
import 'package:aves_utils/aves_utils.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart';

// Optional lock for the recycle bin, with the same lock types as vaults.
// The lock type and its secret are kept in the secure store (like vault secrets),
// so that they are neither part of the regular settings nor of their export.
class BinLock {
  static const _lockTypeKey = 'bin_lock_type';
  static const _passKey = 'bin_lock_pass';
  static const _offOption = 'off';

  const BinLock._();

  // `null` when the bin is not locked
  static Future<VaultLockType?> getLockType() async {
    final name = await securityService.readValue<String>(_lockTypeKey);
    return VaultLockType.values.safeByName(name);
  }

  // returns `true` when the bin is not locked, or when the user passed the lock
  static Future<bool> authenticate(BuildContext context) async {
    final lockType = await getLockType();
    if (lockType == null) return true;
    if (!context.mounted) return false;

    return _challenge(context, lockType, context.l10n.authenticateToOpenBin);
  }

  // let the user choose the lock type, and set the secret if needed
  static Future<void> configure(BuildContext context) async {
    final l10n = context.l10n;
    final currentType = await getLockType();
    if (!context.mounted) return;

    // changing or removing an existing lock requires to pass it first
    if (currentType != null && !await _challenge(context, currentType, l10n.authenticateToConfigureBinLock)) return;
    if (!context.mounted) return;

    final options = <String, String>{
      _offOption: l10n.settingsBinLockOff,
      if (device.canAuthenticateUser) VaultLockType.system.name: VaultLockType.system.getText(context),
      VaultLockType.pattern.name: VaultLockType.pattern.getText(context),
      VaultLockType.pin.name: VaultLockType.pin.getText(context),
      VaultLockType.password.name: VaultLockType.password.getText(context),
    };
    await showSelectionDialog<String>(
      context: context,
      builder: (context) => AvesSingleSelectionDialog<String>(
        initialValue: currentType?.name ?? _offOption,
        options: options,
        title: l10n.settingsBinLock,
      ),
      onSelection: (choice) async {
        if (!context.mounted) return;

        if (choice == _offOption) {
          await securityService.writeValue<String>(_lockTypeKey, null);
          await securityService.writeValue<String>(_passKey, null);
          return;
        }

        final lockType = VaultLockType.values.safeByName(choice);
        if (lockType == null) return;

        if (!await _setPass(context, lockType)) return;
        await securityService.writeValue<String>(_lockTypeKey, lockType.name);
      },
    );
  }

  static Future<bool> _challenge(BuildContext context, VaultLockType lockType, String reason) async {
    switch (lockType) {
      case VaultLockType.system:
        try {
          return await LocalAuthentication().authenticate(localizedReason: reason);
        } on PlatformException catch (e, stack) {
          if (!{'auth_in_progress', 'NotAvailable'}.contains(e.code)) {
            // `auth_in_progress`: `Authentication in progress`
            // `NotAvailable`: `Required security features not enabled`
            await reportService.recordError(e, stack);
          }
          return false;
        }
      case VaultLockType.pattern:
        final pattern = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PatternDialog(needConfirmation: false),
          routeSettings: const RouteSettings(name: PatternDialog.routeName),
        );
        return pattern != null && pattern == await securityService.readValue<String>(_passKey);
      case VaultLockType.pin:
        final pin = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PinDialog(needConfirmation: false),
          routeSettings: const RouteSettings(name: PinDialog.routeName),
        );
        return pin != null && pin == await securityService.readValue<String>(_passKey);
      case VaultLockType.password:
        final password = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PasswordDialog(needConfirmation: false),
          routeSettings: const RouteSettings(name: PasswordDialog.routeName),
        );
        return password != null && password == await securityService.readValue<String>(_passKey);
    }
  }

  static Future<bool> _setPass(BuildContext context, VaultLockType lockType) async {
    switch (lockType) {
      case VaultLockType.system:
        final l10n = context.l10n;
        try {
          return await LocalAuthentication().authenticate(localizedReason: l10n.authenticateToConfigureBinLock);
        } on PlatformException catch (e, stack) {
          if (context.mounted) {
            await showWarningDialog(
              context: context,
              message: e.message ?? l10n.genericFailureFeedback,
            );
          }
          await reportService.recordError(e, stack);
          return false;
        }
      case VaultLockType.pattern:
        final pattern = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PatternDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PatternDialog.routeName),
        );
        return pattern != null && await securityService.writeValue<String>(_passKey, pattern);
      case VaultLockType.pin:
        final pin = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PinDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PinDialog.routeName),
        );
        return pin != null && await securityService.writeValue<String>(_passKey, pin);
      case VaultLockType.password:
        final password = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PasswordDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PasswordDialog.routeName),
        );
        return password != null && await securityService.writeValue<String>(_passKey, password);
    }
  }
}
