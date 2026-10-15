import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/vaults/details.dart';
import 'package:aves/model/vaults/vaults.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves_model/aves_model.dart';
import 'package:aves_utils/aves_utils.dart';
import 'package:flutter/foundation.dart';

final AdvancedPrivacy advancedPrivacy = AdvancedPrivacy._private();

// Extra vault protections, kept in the secure store (keyed by vault name) rather than in the vault database:
// - a second lock, to be passed after the regular vault lock to unlock the vault
// - a sharing block, to prevent items of the vault from being sent to other apps
// - an option to hide vaults from the album list, until hidden items are revealed
class AdvancedPrivacy extends ChangeNotifier {
  static const _hideVaultsKey = 'adv_hide_vaults';

  static String _secondLockKey(String name) => 'adv_vault2_$name';

  static String _sharingBlockKey(String name) => 'adv_vault_noshare_$name';

  static String secondPassKey(String name) => 'adv_vault2pass_$name';

  bool _hideVaults = false;
  final Map<String, VaultLockType> _secondLocks = {};
  final Set<String> _sharingBlocked = {};

  AdvancedPrivacy._private();

  Future<void> init(Iterable<String> vaultNames) async {
    _hideVaults = await securityService.readValue<String>(_hideVaultsKey) == '1';
    _secondLocks.clear();
    _sharingBlocked.clear();
    for (final name in vaultNames) {
      final type = VaultLockType.values.safeByName(await securityService.readValue<String>(_secondLockKey(name)));
      if (type != null) {
        _secondLocks[name] = type;
      }
      if (await securityService.readValue<String>(_sharingBlockKey(name)) == '1') {
        _sharingBlocked.add(name);
      }
    }
    notifyListeners();
  }

  bool get hideVaults => _hideVaults;

  Future<void> setHideVaults(bool value) async {
    await securityService.writeValue<String>(_hideVaultsKey, value ? '1' : null);
    _hideVaults = value;
    notifyListeners();
  }

  VaultLockType? secondLockType(String name) => _secondLocks[name];

  // the secret of the second lock should be set before calling this
  Future<void> setSecondLock(String name, VaultLockType? type) async {
    await securityService.writeValue<String>(_secondLockKey(name), type?.name);
    if (type == null) {
      _secondLocks.remove(name);
      await securityService.writeValue<String>(secondPassKey(name), null);
    } else {
      _secondLocks[name] = type;
    }
    notifyListeners();
  }

  bool blocksSharing(String name) => _sharingBlocked.contains(name);

  Future<void> setSharingBlocked(String name, bool blocked) async {
    await securityService.writeValue<String>(_sharingBlockKey(name), blocked ? '1' : null);
    if (blocked) {
      _sharingBlocked.add(name);
    } else {
      _sharingBlocked.remove(name);
    }
    notifyListeners();
  }

  Future<void> rename(String oldName, String newName) async {
    final secondLock = _secondLocks.remove(oldName);
    if (secondLock != null) {
      _secondLocks[newName] = secondLock;
      await securityService.writeValue<String>(_secondLockKey(newName), secondLock.name);
      final pass = await securityService.readValue<String>(secondPassKey(oldName));
      if (pass != null) {
        await securityService.writeValue<String>(secondPassKey(newName), pass);
      }
    }
    if (_sharingBlocked.remove(oldName)) {
      _sharingBlocked.add(newName);
      await securityService.writeValue<String>(_sharingBlockKey(newName), '1');
    }
    await _clear(oldName);
    notifyListeners();
  }

  Future<void> remove(String name) async {
    _secondLocks.remove(name);
    _sharingBlocked.remove(name);
    await _clear(name);
    notifyListeners();
  }

  Future<void> _clear(String name) async {
    await securityService.writeValue<String>(_secondLockKey(name), null);
    await securityService.writeValue<String>(secondPassKey(name), null);
    await securityService.writeValue<String>(_sharingBlockKey(name), null);
  }
}

extension ExtraAvesEntryAdvancedPrivacy on AvesEntry {
  // whether this entry is in a vault that does not allow sharing its items to other apps
  bool get isInSharingBlockedVault {
    final dir = directory;
    if (dir == null || !vaults.isVault(dir)) return false;

    final name = VaultDetails.nameFromPath(dir);
    return name != null && advancedPrivacy.blocksSharing(name);
  }
}
