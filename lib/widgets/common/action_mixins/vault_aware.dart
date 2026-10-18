import 'package:aves/model/security/failsafe.dart';
import 'package:aves/model/security/bat_curity.dart';
import 'package:aves/model/filters/favourite.dart';
import 'package:aves/model/item_locks.dart';
import 'package:aves/model/advanced_privacy.dart';
import 'package:aves/model/filters/covered/stored_album.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/filters/trash.dart';
import 'package:aves/model/security/attempt_guard.dart';
import 'package:aves/model/security/nuke.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/vaults/details.dart';
import 'package:aves/model/vaults/vaults.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/action_mixins/secret_lock.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/password_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/pattern_dialog.dart';
import 'package:aves/widgets/dialogs/filter_editors/pin_dialog.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

mixin VaultAwareMixin on FeedbackMixin {
  Future<bool> _tryUnlock(BuildContext context, String dirPath) async {
    if (failsafe.blocked(context)) return false;
    if (!vaults.isVault(dirPath)) return itemLocks.unlockAlbum(context, dirPath);
    if (!vaults.isLocked(dirPath)) return true;

    final details = vaults.detailsForPath(dirPath);
    if (details == null) return false;

    final guard = AttemptGuard.vault(details.name);
    final secondLockType = advancedPrivacy.secondLockType(details.name);
    final source = context.read<CollectionSource>();
    Future<void> onNuke() async {
      await Nuke.markVault(details.name);
      await Nuke.nukeVaultContent(details.name, source: source);
    }

    final confirmed = await SecretLock.challenge(
      context,
      details.lockType,
      context.l10n.authenticateToUnlockVault,
      details.passKey,
      guard: guard,
      onNuke: onNuke,
      resetOnSuccess: secondLockType == null,
    );
    if (!confirmed) return false;

    // optional second lock, from the advanced vault security
    if (secondLockType != null) {
      if (!context.mounted) return false;
      final secondConfirmed = await SecretLock.challenge(
        context,
        secondLockType,
        context.l10n.authenticateToUnlockVault,
        AdvancedPrivacy.secondPassKey(details.name),
        guard: guard,
        onNuke: onNuke,
      );
      if (!secondConfirmed) return false;
    }

    await vaults.unlock(context, dirPath);
    return true;
  }

  Future<bool> unlockAlbum(BuildContext context, String dirPath) async {
    final success = await _tryUnlock(context, dirPath);
    if (!success) {
      showFeedback(context, FeedbackType.warn, context.l10n.genericFailureFeedback);
    }
    return success;
  }

  Future<bool> unlockBin(BuildContext context) async {
    final success = await SecretLock.bin.authenticate(context);
    if (!success && context.mounted) {
      showFeedback(context, FeedbackType.warn, context.l10n.genericFailureFeedback);
    }
    return success;
  }

  Future<bool> unlockFilter(BuildContext context, CollectionFilter filter) {
    // the recycle bin may have its own lock
    if (filter is TrashFilter) return unlockBin(context);
    if (filter is FavouriteFilter) return itemLocks.unlockFavourites(context);

    return filter is StoredAlbumFilter ? unlockAlbum(context, filter.album) : Future.value(true);
  }

  Future<bool> unlockFilters(BuildContext context, Set<CollectionFilter> filters) async {
    var unlocked = true;
    await Future.forEach(filters, (filter) async {
      if (unlocked) {
        unlocked = await unlockFilter(context, filter);
      }
    });
    return unlocked;
  }

  void lockFilters(Set<CollectionFilter> filters) => vaults.lock(filters.whereType<StoredAlbumFilter>().map((v) => v.album).toSet());

  Future<bool> setVaultPass(BuildContext context, VaultDetails details) async {
    switch (details.lockType) {
      case .system:
        final l10n = context.l10n;
        try {
          return await LocalAuthentication().authenticate(
            localizedReason: l10n.authenticateToConfigureVault,
          );
        } on PlatformException catch (e, stack) {
          await showWarningDialog(
            context: context,
            message: e.message ?? l10n.genericFailureFeedback,
          );
          await reportService.recordError(e, stack);
        }
      case .pattern:
        final pattern = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PatternDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PatternDialog.routeName),
        );
        if (pattern != null) {
          return await batCurity.store(details.passKey, pattern);
        }
      case .pin:
        final pin = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PinDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PinDialog.routeName),
        );
        if (pin != null) {
          return await batCurity.store(details.passKey, pin);
        }
      case .password:
        final password = await showAvesDialog<String>(
          context: context,
          builder: (context) => const PasswordDialog(needConfirmation: true),
          routeSettings: const RouteSettings(name: PasswordDialog.routeName),
        );
        if (password != null) {
          return await batCurity.store(details.passKey, password);
        }
    }
    return false;
  }
}
