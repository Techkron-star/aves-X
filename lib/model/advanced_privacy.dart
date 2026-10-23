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

  static String secondPassKeyFor(String name, VaultLockType type) => '${secondPassKey(name)}_${type.name}';

  bool _hideVaults = false;
  final Map<String, VaultLockType> _secondLocks = {};
  final Set<String> _sharingBlocked = {};

  AdvancedPrivacy._private();

  Future<void> init(Iterable<String> vaultNames) async {
    _hideVaults = await securityService.readValueStrict<String>(_hideVaultsKey) == '1';
    _secondLocks.clear();
    _sharingBlocked.clear();
    for (final name in vaultNames) {
      final rawType = await securityService.readValueStrict<String>(_secondLockKey(name));
      if (rawType != null) {
        final type = VaultLockType.values.safeByName(rawType);
        if (type == null) throw FormatException('Invalid second lock type for vault $name');
        _secondLocks[name] = type;
      }
      if (await securityService.readValueStrict<String>(_sharingBlockKey(name)) == '1') {
        _sharingBlocked.add(name);
      }
    }
    notifyListeners();
  }

  bool get hideVaults => _hideVaults;

  Future<void> setHideVaults(bool value) async {
    if (!await securityService.writeValue<String>(_hideVaultsKey, value ? '1' : null)) throw StateError('Could not persist hidden-vault setting');
    _hideVaults = value;
    notifyListeners();
  }

  VaultLockType? secondLockType(String name) => _secondLocks[name];

  // the secret of the second lock should be set before calling this
  Future<void> setSecondLock(String name, VaultLockType? type) async {
    if (!await securityService.writeValue<String>(_secondLockKey(name), type?.name)) {
      throw StateError('Could not persist second vault lock type');
    }
    if (type == null) {
      _secondLocks.remove(name);
      await _clearSecondPasses(name);
    } else {
      _secondLocks[name] = type;
      await _clearSecondPasses(name, except: type == VaultLockType.system ? null : type);
    }
    notifyListeners();
  }

  bool blocksSharing(String name) => _sharingBlocked.contains(name);

  Future<void> setSharingBlocked(String name, bool blocked) async {
    if (!await securityService.writeValue<String>(_sharingBlockKey(name), blocked ? '1' : null)) throw StateError('Could not persist vault sharing policy');
    if (blocked) {
      _sharingBlocked.add(name);
    } else {
      _sharingBlocked.remove(name);
    }
    notifyListeners();
  }

  Future<void> rename(String oldName, String newName) async {
    final secondLock = _secondLocks[oldName];
    if (secondLock != null) {
      final oldTypedKey = secondPassKeyFor(oldName, secondLock);
      final pass = await securityService.readValueStrict<String>(oldTypedKey) ?? await securityService.readValueStrict<String>(secondPassKey(oldName));
      if (secondLock != VaultLockType.system && pass == null) {
        throw StateError('Missing second-factor credential while renaming vault');
      }
      if (pass != null && !await securityService.writeValue<String>(secondPassKeyFor(newName, secondLock), pass)) {
        throw StateError('Could not migrate second-factor credential while renaming vault');
      }
      if (!await securityService.writeValue<String>(_secondLockKey(newName), secondLock.name)) {
        throw StateError('Could not migrate second lock type while renaming vault');
      }
      _secondLocks.remove(oldName);
      _secondLocks[newName] = secondLock;
    }
    if (_sharingBlocked.contains(oldName)) {
      if (!await securityService.writeValue<String>(_sharingBlockKey(newName), '1')) {
        throw StateError('Could not migrate vault sharing policy');
      }
      _sharingBlocked.remove(oldName);
      _sharingBlocked.add(newName);
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
    await _clearSecondPasses(name);
    await securityService.writeValue<String>(_sharingBlockKey(name), null);
  }

  Future<void> _clearSecondPasses(String name, {VaultLockType? except}) async {
    final writes = <Future<bool>>[
      securityService.writeValue<String>(secondPassKey(name), null),
      for (final type in VaultLockType.values)
        if (type != except) securityService.writeValue<String>(secondPassKeyFor(name, type), null),
    ];
    if ((await Future.wait(writes)).any((ok) => !ok)) {
      throw StateError('Could not clear stale second-factor credentials for vault $name');
    }
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
