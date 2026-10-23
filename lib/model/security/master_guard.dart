import 'package:aves/services/security_service.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:aves/model/security/master_code.dart';
import 'package:aves/model/security/failsafe.dart';
import 'package:aves/model/vaults/vaults.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pointycastle/export.dart';

// Master Guard: optional extra protection layer.
// For now: Argon2id (+ random salt) hashing of every credential (Master Code, PINs, patterns, passwords).
// It is opt-in, and only the Master Code can turn it off.
final MasterGuard masterGuard = MasterGuard._();

class MasterGuard extends ChangeNotifier {
  static const _enabledKey = 'batcurity_hash';
  static const _vaultEncKey = 'batcurity_vault_enc';
  static const _prefix = 'a2id';

  // Argon2id parameters: 16 MiB, 3 passes, 1 lane
  static const _memoryPowerOf2 = 14;
  static const _iterations = 3;
  static const _lanes = 1;

  MasterGuard._();

  bool _enabled = false;

  bool get hashingEnabled => _enabled;

  bool _vaultEncryption = false;

  // vault files are encrypted at rest while the vaults are locked
  bool get vaultEncryption => _vaultEncryption;

  // operations on files are queued, as each one replaces files
  Future<void> _chain = Future.value();

  Future<T> _enqueue<T>(Future<T> Function() op) {
    final completer = Completer<T>();
    _chain = _chain.then((_) async {
      try {
        completer.complete(await op());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  // `null` when nothing had to be done, otherwise the report (with the errors, if any)
  Future<VaultCryptoReport?> decryptVault(String name) async {
    if (!_vaultEncryption) return null;
    return _enqueue(() => securityService.cryptVault(name, encrypt: false));
  }

  Future<bool> encryptVault(String name) async {
    if (!_vaultEncryption) return true;
    // never touch the files if the key does not work
    if (await securityService.cryptSelfTest() != null) return false;
    final report = await _enqueue(() => securityService.cryptVault(name, encrypt: true));
    return report != null && report.success;
  }

  // nothing is open when the app starts, so everything has to be encrypted
  Future<void> encryptAllAtStartup() async {
    // May run before init. If the setting cannot be read, assume encryption was enabled and lock down.
    final bool enabled;
    try {
      enabled = await securityService.readValueStrict<String>(_vaultEncKey) == '1';
    } catch (error, stack) {
      _vaultEncryption = true;
      await reportService.recordError(error, stack);
      await failsafe.engageLockdown();
      return;
    }
    if (!enabled) return;
    _vaultEncryption = true;
    try {
      if (await securityService.cryptSelfTest() != null) {
        await failsafe.engageLockdown();
        return;
      }
      final report = await _enqueue(() => securityService.cryptAllVaults(encrypt: true));
      if (report == null || !report.success) {
        // A vault must not be treated as protected when encryption did not complete.
        await failsafe.engageLockdown();
      }
    } catch (error, stack) {
      await reportService.recordError(error, stack);
      await failsafe.engageLockdown();
    }
  }

  // emergency tool (needs the Master Code): decrypts every vault file it can, and reports what could not be
  Future<void> forceDecryptAll(BuildContext context) async {
    if (!await MasterCode.require(context) || !context.mounted) return;

    final report = await _enqueue(() => securityService.cryptAllVaults(encrypt: false));
    if (!context.mounted) return;
    final l10n = context.l10n;
    final message = report == null
        ? l10n.batCurityForceDecryptError
        : [
            l10n.batCurityForceDecryptResult(report.done, report.skipped, report.failed),
            if (report.errors.isNotEmpty) report.errors.take(5).join('\n'),
          ].join('\n\n');
    await showWarningDialog(context: context, message: message);
  }

  // enabling encrypts the locked vaults now (the others when they lock);
  // disabling decrypts everything first, and stays enabled if any file could not be decrypted
  Future<bool> setVaultEncryption(BuildContext context, bool value) async {
    if (value == _vaultEncryption) return true;
    if (!await MasterCode.require(context)) return false;

    if (value) {
      try {
        // The key must work before anything is encrypted.
        final error = await securityService.cryptSelfTest();
        if (error != null) {
          if (context.mounted) await showWarningDialog(context: context, message: context.l10n.batCurityVaultEncSelfTestFailed(error));
          return false;
        }
        if (!await securityService.writeValue<String>(_vaultEncKey, '1')) return false;
        _vaultEncryption = true;
        var allEncrypted = true;
        for (final details in vaults.all.where((v) => vaults.isLocked(v.path))) {
          if (!await encryptVault(details.name)) allEncrypted = false;
        }
        if (!allEncrypted) {
          await failsafe.engageLockdown();
          notifyListeners();
          return false;
        }
      } catch (error, stack) {
        await reportService.recordError(error, stack);
        _vaultEncryption = true;
        await failsafe.engageLockdown();
        notifyListeners();
        return false;
      }
    } else {
      try {
        final report = await _enqueue(() => securityService.cryptAllVaults(encrypt: false));
        if (report == null || !report.success) {
          // Roll back partial decryption so the enabled setting continues to match the files on disk.
          final restored = await _enqueue(() => securityService.cryptAllVaults(encrypt: true));
          if (restored == null || !restored.success) await failsafe.engageLockdown();
          notifyListeners();
          return false;
        }
        if (!await securityService.writeValue<String>(_vaultEncKey, null)) {
          final restored = await _enqueue(() => securityService.cryptAllVaults(encrypt: true));
          if (restored == null || !restored.success) await failsafe.engageLockdown();
          return false;
        }
        _vaultEncryption = false;
      } catch (error, stack) {
        await reportService.recordError(error, stack);
        await failsafe.engageLockdown();
        notifyListeners();
        return false;
      }
    }
    notifyListeners();
    return true;
  }

  Future<void> init() async {
    try {
      _enabled = await securityService.readValueStrict<String>(_enabledKey) == '1';
      _vaultEncryption = await securityService.readValueStrict<String>(_vaultEncKey) == '1';
    } catch (error, stack) {
      // Do not silently turn off hashing or at-rest encryption when encrypted preferences fail to load.
      _enabled = true;
      _vaultEncryption = true;
      await reportService.recordError(error, stack);
      await failsafe.engageLockdown();
    }
    notifyListeners();
  }

  // enabling hashes the existing credentials; disabling needs the Master Code
  Future<bool> setHashing(BuildContext context, bool value) async {
    if (value == _enabled) return true;
    if (!await MasterCode.require(context)) return false;

    if (value) {
      await _migrateSecrets();
    }
    if (!await securityService.writeValue<String>(_enabledKey, value ? '1' : null)) {
      throw StateError('Could not persist Bat-Curity credential hashing setting');
    }
    _enabled = value;
    notifyListeners();
    return true;
  }

  // credentials already hashed stay valid after disabling (verification handles both forms),
  // new ones are then stored as before
  Future<void> _migrateSecrets() async {
    final keys = <String>{
      'master_code',
      'app_lock_pin',
      'app_lock_alt_secret',
      for (final type in ['system', 'pattern', 'pin', 'password']) 'app_lock_secret_$type',
      'app_lock_panic',
      'bin_lock_pass',
      'reveal_lock_pass',
      'items_lock_pass',
      for (final lock in ['bin_lock', 'reveal_lock', 'items_lock'])
        for (final type in ['system', 'pattern', 'pin', 'password']) '${lock}_pass_${type}',
      for (final v in vaults.all) v.passKey,
      for (final v in vaults.all)
        for (final type in ['system', 'pattern', 'pin', 'password']) '${v.passKey}_${type}',
      for (final v in vaults.all) 'adv_vault2pass_${v.name}',
      for (final v in vaults.all)
        for (final type in ['system', 'pattern', 'pin', 'password']) 'adv_vault2pass_${v.name}_${type}',
    };
    for (final key in keys) {
      final stored = await securityService.readValueStrict<String>(key);
      if (stored == null || isHashed(stored)) continue;
      if (!await securityService.writeValue<String>(key, await _hash(stored))) {
        throw StateError('Could not migrate protected credential: $key');
      }
    }
  }

  static bool isHashed(String stored) => stored.startsWith('$_prefix:');

  // value to store for a new secret
  Future<String> prepare(String secret) => _enabled ? _hash(secret) : Future.value(secret);

  // stores a secret, hashed when Bat-curity hashing is on
  Future<bool> store(String key, String secret) async {
    return securityService.writeValue<String>(key, await prepare(secret));
  }

  // Checks an optional secret. A missing value is a normal mismatch.
  Future<bool> matches(String key, String input) async {
    final stored = await securityService.readValueStrict<String>(key);
    if (stored == null) return false;
    return matchesStored(stored, input);
  }

  // Checks a credential that must exist for the requested operation. Missing/unreadable storage
  // is an integrity error, not a wrong password; callers must fail closed without counting it.
  Future<bool> matchesRequired(String key, String input) async {
    final stored = await securityService.readValueStrict<String>(key);
    if (stored == null) throw StateError('Required credential is missing: $key');
    return matchesStored(stored, input);
  }

  Future<bool> matchesStored(String stored, String input) async {
    if (!isHashed(stored)) return _constantTimeEquals(utf8.encode(stored), utf8.encode(input));

    final parts = stored.split(':');
    if (parts.length != 7 || parts[0] != _prefix) {
      throw const FormatException('Malformed Argon2id credential record');
    }
    final memoryPower = int.tryParse(parts[1]);
    final iterations = int.tryParse(parts[2]);
    final lanes = int.tryParse(parts[3]);
    final version = int.tryParse(parts[4]);
    if (memoryPower == null || memoryPower < 10 || memoryPower > 18 ||
        iterations == null || iterations < 1 || iterations > 6 ||
        lanes == null || lanes < 1 || lanes > 4 || version != 19) {
      throw const FormatException('Unsupported Argon2id credential parameters');
    }
    final salt = base64.decode(parts[5]);
    final expected = base64.decode(parts[6]);
    if (salt.length < 16 || expected.length < 16 || expected.length > 64) {
      throw const FormatException('Invalid Argon2id credential lengths');
    }
    final actual = await compute(
      _derive,
      _Job(input, salt, memoryPower, iterations, lanes, expected.length),
    );
    return _constantTimeEquals(actual, expected);
  }

  Future<String> _hash(String secret) async {
    final rng = Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => rng.nextInt(256)));
    final hash = await compute(_derive, _Job(secret, salt, _memoryPowerOf2, _iterations, _lanes, 32));
    // format: a2id:<memory power of 2 (KiB)>:<iterations>:<lanes>:<version>:<salt>:<hash>
    return '$_prefix:$_memoryPowerOf2:$_iterations:$_lanes:19:${base64.encode(salt)}:${base64.encode(hash)}';
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

class _Job {
  final String secret;
  final Uint8List salt;
  final int memoryPowerOf2, iterations, lanes, length;

  const _Job(this.secret, this.salt, this.memoryPowerOf2, this.iterations, this.lanes, this.length);
}

Uint8List _derive(_Job job) {
  final generator = Argon2BytesGenerator()
    ..init(
      Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        job.salt,
        desiredKeyLength: job.length,
        iterations: job.iterations,
        memoryPowerOf2: job.memoryPowerOf2,
        lanes: job.lanes,
        version: Argon2Parameters.ARGON2_VERSION_13,
      ),
    );
  final out = Uint8List(job.length);
  generator.deriveKey(Uint8List.fromList(utf8.encode(job.secret)), 0, out, 0);
  return out;
}
