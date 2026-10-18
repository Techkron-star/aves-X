import 'package:aves/widgets/dialogs/aves_confirmation_dialog.dart';
import 'package:aves/widgets/settings/security/security.dart';
import 'package:aves/model/security/bat_curity.dart';
import 'package:aves/model/security/attempt_guard.dart';
import 'package:aves/model/security/nuke.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/code_dialog.dart';
import 'package:flutter/widgets.dart';

// 6-digit code, created before the first PIN/password, and required to change or remove any of them.
// There is no recovery: the only way out is wiping everything.
class MasterCode {
  static const _key = 'master_code';

  static Future<bool> get isSet async => await securityService.readValue<String>(_key) != null;

  // creates the code if none exists yet; `true` if a code exists afterwards
  static Future<bool> ensure(BuildContext context) async {
    if (await isSet) return true;
    if (!context.mounted) return false;

    final code = await showAvesDialog<String>(
      context: context,
      builder: (context) => CodeDialog(needConfirmation: true, message: context.l10n.masterCodeCreateMessage),
      routeSettings: const RouteSettings(name: CodeDialog.routeName),
    );
    if (code == null || !await batCurity.store(_key, code)) return false;

    // extra security is only offered: the user has to enable it by hand in the Security section
    if (context.mounted && await showConfirmationDialog(context: context, message: context.l10n.batCurityOfferMessage, ok: context.l10n.batCurityOfferGo) && context.mounted) {
      await SecuritySection().open(context);
    }
    return true;
  }

  // asks for the code (creating it first if needed); `true` if the user can proceed
  static Future<bool> require(BuildContext context) async {
    if (!await isSet) return ensure(context);
    if (!context.mounted) return false;

    final guard = AttemptGuard.master;
    final remaining = await guard.remainingCooldown();
    if (remaining != null) {
      if (context.mounted) await showCooldownMessage(context, remaining);
      return false;
    }
    if (!context.mounted) return false;

    final code = await showAvesDialog<String>(
      context: context,
      builder: (context) => CodeDialog(needConfirmation: false, message: context.l10n.masterCodeEnterMessage),
      routeSettings: const RouteSettings(name: CodeDialog.routeName),
    );
    if (code == null) return false;

    if (await batCurity.matches(_key, code)) {
      await guard.reset();
      return true;
    }
    await handleFailure(context, guard, Nuke.nukeEverything);
    return false;
  }

  // asks for the current code, then for the new one
  static Future<void> change(BuildContext context) async {
    if (!await require(context) || !context.mounted) return;

    final code = await showAvesDialog<String>(
      context: context,
      builder: (context) => const CodeDialog(needConfirmation: true),
      routeSettings: const RouteSettings(name: CodeDialog.routeName),
    );
    if (code != null) {
      await batCurity.store(_key, code);
    }
  }

  static Future<void> showCooldownMessage(BuildContext context, Duration remaining) {
    if (remaining.inSeconds < 60) {
      return showWarningDialog(context: context, message: context.l10n.attemptsCooldownSecondsMessage(remaining.inSeconds + 1));
    }
    final minutes = (remaining.inSeconds / 60).ceil();
    return showWarningDialog(context: context, message: context.l10n.attemptsCooldownMessage(minutes));
  }

  // registers a failed attempt, and reacts to the outcome
  static Future<void> handleFailure(BuildContext context, AttemptGuard guard, Future<void> Function() onNuke) async {
    final outcome = await guard.registerFailure();
    switch (outcome) {
      case AttemptOutcome.nuke:
        await onNuke();
      case AttemptOutcome.cooldown:
        if (context.mounted) await showCooldownMessage(context, await guard.remainingCooldown() ?? AttemptGuard.cooldownDuration);
      case AttemptOutcome.failed:
        if (context.mounted) await showWarningDialog(context: context, message: context.l10n.genericFailureFeedback);
    }
  }
}
