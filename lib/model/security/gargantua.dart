import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/item_locks.dart';
import 'package:aves/model/security/master_code.dart';
import 'package:aves/model/security/privacy_options.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/action_mixins/secret_lock.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

final Gargantua gargantua = Gargantua._private();

// Gargantua: files do not leave the app without permission.
// Exits are grouped in a few categories, behind a master switch and a Master Code rule,
// instead of one switch per action.
enum GargantuaCategory { share, open, clipboard, save, surfaces }

// Outcome of the policy for one exit, computed without any UI.
enum GargantuaDecision { allow, askItemLock, askMasterCode, deny }

// Pure policy, so that the truth table can be tested without a `BuildContext`.
class GargantuaPolicy {
  final bool masterEnabled;
  final Set<GargantuaCategory> enabledCategories;
  final bool requireMasterCode;
  final bool itemLocksEnabled;
  final bool storeError;

  const GargantuaPolicy({
    required this.masterEnabled,
    required this.enabledCategories,
    required this.requireMasterCode,
    required this.itemLocksEnabled,
    this.storeError = false,
  });

  bool isCategoryEnabled(GargantuaCategory category) => enabledCategories.contains(category);

  GargantuaDecision decide({
    required GargantuaCategory category,
    required bool hasMarkedItems,
  }) {
    // fail closed: if the secure store cannot be read, we do not let files out
    if (storeError) return GargantuaDecision.deny;
    // Gargantua does not apply at all until the master switch is turned on
    if (!masterEnabled) return GargantuaDecision.allow;
    if (!isCategoryEnabled(category)) return GargantuaDecision.allow;
    // a locked item is the strongest single factor:
    // its own lock is asked, without the Master Code on top of it
    if (itemLocksEnabled && hasMarkedItems) return GargantuaDecision.askItemLock;
    if (requireMasterCode) return GargantuaDecision.askMasterCode;
    return GargantuaDecision.allow;
  }
}

// Switches of the exit policy, kept in the secure store (not in the settings).
// Turning a protection off requires the Master Code; turning it on does not.
// The values are loaded once, lazily, and never cached credentials: every exit is asked again.
class Gargantua extends ChangeNotifier {
  static const masterKey = 'opt_gargantua';
  static const shareKey = 'opt_gargantua_share';
  static const openKey = 'opt_gargantua_open';
  static const clipboardKey = 'opt_gargantua_clipboard';
  static const saveKey = 'opt_gargantua_save';
  static const surfacesKey = 'opt_gargantua_surfaces';
  static const masterCodeKey = 'opt_gargantua_master_code';

  static const _categoryKeys = <GargantuaCategory, String>{
    GargantuaCategory.share: shareKey,
    GargantuaCategory.open: openKey,
    GargantuaCategory.clipboard: clipboardKey,
    GargantuaCategory.save: saveKey,
    GargantuaCategory.surfaces: surfacesKey,
  };

  static const _keys = [masterKey, shareKey, openKey, clipboardKey, saveKey, surfacesKey, masterCodeKey];

  Gargantua._private();

  // unset keys are absent, so that the defaults below apply
  final Map<String, bool> _values = {};

  Future<void>? _initFuture;

  // a prompt is already open: another exit must not stack another dialog on top of it
  bool _prompting = false;

  bool _storeError = false;

  Future<void> init() => _initFuture ??= _load();

  // retry after a secure-store failure, without restarting the app
  Future<void> reload() {
    _initFuture = null;
    return init();
  }

  Future<void> _load() async {
    _storeError = false;
    _values.clear();
    try {
      for (final key in _keys) {
        // strict read: an unreadable store must not look like "everything off"
        final raw = await securityService.readValueStrict<String>(key);
        if (raw != null) _values[key] = raw == '1';
      }
    } catch (e, stack) {
      // fail closed (see `GargantuaPolicy.storeError`)
      _storeError = true;
      await reportService.recordError(e, stack);
      await reportService.log('Gargantua: failed to read the secure store');
    }
    notifyListeners();
  }

  bool get masterEnabled => _values[masterKey] ?? false;

  // the secure store could not be read: exits are denied (fail closed)
  bool get storeError => _storeError;

  bool categoryEnabled(GargantuaCategory category) => _values[_categoryKeys[category]] ?? false;

  // the Master Code rule is on by default, so that turning the master switch on actually protects exits
  bool get requireMasterCode => _values[masterCodeKey] ?? true;

  GargantuaPolicy get policy => GargantuaPolicy(
    masterEnabled: masterEnabled,
    enabledCategories: GargantuaCategory.values.where(categoryEnabled).toSet(),
    requireMasterCode: requireMasterCode,
    itemLocksEnabled: privacyOptions.itemLocks,
    storeError: _storeError,
  );

  // `true` if the exit is allowed, possibly after an authentication
  Future<bool> authorizeExit(BuildContext context, Iterable<AvesEntry> entries, GargantuaCategory category) async {
    await init();

    final policy = this.policy;
    // only marked items need their own lock: `isEntryMarked` does not depend on the item locks being enabled
    final hasMarkedItems = policy.itemLocksEnabled && entries.any(itemLocks.isEntryMarked);
    final decision = policy.decide(category: category, hasMarkedItems: hasMarkedItems);

    switch (decision) {
      case GargantuaDecision.allow:
        return true;
      case GargantuaDecision.deny:
        // fail closed, but do not leave the user with a silent no-op
        if (policy.storeError && context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(context.l10n.gargantuaWarningStoreError)));
        }
        return false;
      case GargantuaDecision.askItemLock:
      case GargantuaDecision.askMasterCode:
        break;
    }

    if (_prompting) {
      await reportService.log('Gargantua: an exit prompt is already open, denying $category');
      return false;
    }
    _prompting = true;
    try {
      if (decision == GargantuaDecision.askItemLock) {
        // a marked item without a configured lock type has no factor: fall back to the Master Code
        try {
          if (await SecretLock.items.getLockType() == null) return await _requireMasterCode(context);
          return await itemLocks.authorizeExit(context, entries);
        } catch (_) {
          // an unreadable lock must not turn into an allow
          return false;
        }
      }
      return await _requireMasterCode(context);
    } finally {
      _prompting = false;
    }
  }

  Future<bool> _requireMasterCode(BuildContext context) async {
    if (!context.mounted) return false;
    // no `ensure` shortcut here: `MasterCode.require` creates the code or denies, it never lets the exit through silently
    return MasterCode.require(
      context,
      message: context.l10n.masterCodeEnterForExitMessage,
      proposeExtraSecurity: false,
    );
  }

  Future<bool> _write(String key, bool value) async {
    final written = await securityService.writeValue<String>(key, value ? '1' : null);
    if (!written) return false;
    _values[key] = value;
    return true;
  }

  // returns whether the change was applied (it is cancelled if the Master Code is refused)
  Future<bool> setMaster(BuildContext context, bool value) async {
    await init();
    if (!value && !await MasterCode.require(context)) return false;

    if (value) {
      // write the categories and the rule first, so a partial failure cannot leave the master on with no protection
      for (final entry in _categoryKeys.entries) {
        if (!await _write(entry.value, entry.key == GargantuaCategory.share)) return false;
      }
      // turning the master switch on always restores the Master Code rule
      if (!await _write(masterCodeKey, true)) return false;
    }
    if (!await _write(masterKey, value)) return false;
    notifyListeners();
    return true;
  }

  // returns whether the change was applied (turning a category off requires the Master Code)
  Future<bool> setCategory(BuildContext context, GargantuaCategory category, bool value) async {
    await init();
    if (!value && !await MasterCode.require(context)) return false;

    if (!await _write(_categoryKeys[category]!, value)) return false;
    notifyListeners();
    return true;
  }

  // returns whether the change was applied (waiving the Master Code rule requires the Master Code)
  Future<bool> setRequireMasterCode(BuildContext context, bool value) async {
    await init();
    if (!value && !await MasterCode.require(context)) return false;

    if (!await _write(masterCodeKey, value)) return false;
    notifyListeners();
    return true;
  }
}
