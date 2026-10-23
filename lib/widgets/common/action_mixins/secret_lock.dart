import 'package:aves/model/security/master_guard.dart';
import 'package:aves/model/device.dart';
import 'package:aves/model/security/attempt_guard.dart';
import 'package:aves/model/security/master_code.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/view/view.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/password_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/pattern_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/pin_dialog.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/single_selection.dart';
import 'package:aves_model/aves_model.dart';
import 'package:aves_utils/aves_utils.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart';

// Optional lock with the same lock types as vaults (system, pattern, PIN, password).
// The lock type and its secret are kept in the secure store (like vault secrets),
// so that they are neither part of the regular settings nor of their export.
class SecretLock {
  static final Set<String> _activeChallenges = {};
  // locks the recycle bin
  static final bin = SecretLock._(
    id: 'bin_lock',
    authReason: (context) => context.l10n.authenticateToOpenBin,
    configReason: (context) => context.l10n.authenticateToConfigureBinLock,
    title: (context) => context.l10n.settingsBinLock,
  );

  // protects the reveal of hidden items
  static final reveal = SecretLock._(
    id: 'reveal_lock',
    authReason: (context) => context.l10n.authenticateToRevealHidden,
    configReason: (context) => context.l10n.authenticateToConfigureRevealLock,
    title: (context) => context.l10n.settingsRevealLock,
  );

  // locks albums and items (not vaults)
  static final items = SecretLock._(
    id: 'items_lock',
    authReason: (context) => context.l10n.authenticateToOpenLockedItem,
    configReason: (context) => context.l10n.authenticateToConfigureItemLock,
    title: (context) => context.l10n.settingsItemLock,
  );

  static const _offOption = 'off';

  final String id;
  final String Function(BuildContext context) authReason, configReason, title;

  SecretLock._({
    required this.id,
    required this.authReason,
    required this.configReason,
    required this.title,
  });

  String get _typeKey => '${id}_type';

  String get _passKey => '${id}_pass';

  // `null` when there is no lock
  Future<VaultLockType?> getLockType() async {
    final name = await securityService.readValueStrict<String>(_typeKey);
    return VaultLockType.values.safeByName(name);
  }

  // returns `true` when there is no lock, or when the user passed the lock
  Future<bool> authenticate(BuildContext context) async {
    final lockType = await getLockType();
    if (lockType == null) return true;
    if (!context.mounted) return false;

    // wrong attempts are counted, with a cooldown that grows with each failure
    return challenge(context, lockType, authReason(context), _passKey, guard: AttemptGuard.named(id));
  }

  // let the user choose the lock type, and set the secret if needed
  Future<void> configure(BuildContext context) async {
    final l10n = context.l10n;
    final currentType = await getLockType();
    if (!context.mounted) return;

    // changing, removing or creating a lock requires the Master Code (created at the first use)
    if (!await MasterCode.require(context)) return;
    if (!context.mounted) return;

    final options = <String, String>{
      _offOption: l10n.settingsBinLockOff,
      ...lockTypeOptions(context),
    };
    final choice = await showAvesDialog<String>(
      context: context,
      builder: (context) => AvesSingleSelectionDialog<String>(
        initialValue: currentType?.name ?? _offOption,
        options: options,
        title: title(context),
      ),
      routeSettings: const RouteSettings(name: AvesSingleSelectionDialog.routeName),
    );
    if (choice == null || !context.mounted) return;

    if (choice == _offOption) {
      await securityService.writeValue<String>(_typeKey, null);
      await securityService.writeValue<String>(_passKey, null);
      return;
    }

    final lockType = VaultLockType.values.safeByName(choice);
    if (lockType == null) return;

    if (!await setPass(context, lockType, _passKey, configReason(context))) return;
    await securityService.writeValue<String>(_typeKey, lockType.name);
  }

  // lock types available on this device, by name
  static Map<String, String> lockTypeOptions(BuildContext context, {Set<VaultLockType> exclude = const {}}) {
    return {
      for (final type in VaultLockType.values)
        if (!exclude.contains(type) && (type != VaultLockType.system || device.canAuthenticateUser)) type.name: type.getText(context),
    };
  }

  // `guard` counts the failed attempts (and handles cooldown and nuke);
  // `resetOnSuccess` should be `false` when another factor has to be passed afterwards
  static Future<bool> challenge(
    BuildContext context,
    VaultLockType lockType,
    String reason,
    String passKey, {
    AttemptGuard? guard,
    Future<void> Function()? onNuke,
    bool resetOnSuccess = true,
  }) async {
    final challengeKey = guard?.id;
    if (challengeKey != null && !_activeChallenges.add(challengeKey)) {
      // A second widget/callback must not verify or count the same protected flow concurrently.
      return false;
    }
    try {
      if (guard != null) {
        final remaining = await guard.remainingCooldown();
        if (remaining != null) {
          if (context.mounted) await MasterCode.showCooldownMessage(context, remaining);
          return false;
        }
        if (!context.mounted) return false;
      }

      bool? result;
      try {
        result = await _attempt(context, lockType, reason, passKey);
      } catch (error, stack) {
        // A storage/hash/system error is not proof of a wrong secret. Fail closed without
        // incrementing counters or reaching any configured destructive action.
        await reportService.recordError(error, stack);
        if (context.mounted) {
          await showWarningDialog(context: context, message: context.l10n.genericFailureFeedback);
        }
        return false;
      }
      // Cancellation, unavailable authentication and verifier errors are not failed attempts.
      if (result == null) return false;

      if (result) {
        if (guard != null && resetOnSuccess) await guard.reset();
        return true;
      }
      if (guard != null && context.mounted) {
        await MasterCode.handleFailure(context, guard, onNuke ?? () async {});
      }
      return false;
    } catch (error, stack) {
      // Lockout-state storage failures are also fail-closed and never count as a bad secret.
      await reportService.recordError(error, stack);
      if (context.mounted) {
        await showWarningDialog(context: context, message: context.l10n.genericFailureFeedback);
      }
      return false;
    } finally {
      if (challengeKey != null) _activeChallenges.remove(challengeKey);
    }
  }

  // `null` when cancelled or unavailable (not counted as a failure)
  static Future<bool?> _attempt(BuildContext context, VaultLockType lockType, String reason, String passKey) async {
    switch (lockType) {
      case VaultLockType.system:
        try {
          // Platform biometric cancellation and rejection are indistinguishable here; do not
          // count either as a secret mismatch or let it contribute toward a destructive action.
          final authenticated = await LocalAuthentication().authenticate(localizedReason: reason);
          return authenticated ? true : null;
        } on PlatformException catch (e, stack) {
          if (!{'auth_in_progress', 'NotAvailable'}.contains(e.code)) {
            await reportService.recordError(e, stack);
          }
          return null;
        }
      case VaultLockType.pattern:
        final pattern = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PatternDialog(needConfirmation: false),
          routeSettings: const RouteSettings(name: PatternDialog.routeName),
        );
        return pattern == null ? null : await masterGuard.matchesRequired(passKey, pattern);
      case VaultLockType.pin:
        final pin = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PinDialog(needConfirmation: false),
          routeSettings: const RouteSettings(name: PinDialog.routeName),
        );
        return pin == null ? null : await masterGuard.matchesRequired(passKey, pin);
      case VaultLockType.password:
        final password = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PasswordDialog(needConfirmation: false),
          routeSettings: const RouteSettings(name: PasswordDialog.routeName),
        );
        return password == null ? null : await masterGuard.matchesRequired(passKey, password);
    }
  }

  static Future<bool> setPass(BuildContext context, VaultLockType lockType, String passKey, String reason) async {
    switch (lockType) {
      case VaultLockType.system:
        try {
          return await LocalAuthentication().authenticate(localizedReason: reason);
        } on PlatformException catch (e, stack) {
          if (context.mounted) {
            await showWarningDialog(
              context: context,
              message: e.message ?? context.l10n.genericFailureFeedback,
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
        return pattern != null && await masterGuard.store(passKey, pattern);
      case VaultLockType.pin:
        final pin = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PinDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PinDialog.routeName),
        );
        return pin != null && await masterGuard.store(passKey, pin);
      case VaultLockType.password:
        final password = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PasswordDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PasswordDialog.routeName),
        );
        return password != null && await masterGuard.store(passKey, password);
    }
  }
}
