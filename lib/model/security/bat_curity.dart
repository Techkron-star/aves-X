import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:aves/model/security/master_code.dart';
import 'package:aves/model/vaults/vaults.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pointycastle/export.dart';

// "Bat-curity": optional extra protection layer.
// For now: Argon2id (+ random salt) hashing of every credential (Master Code, PINs, patterns, passwords).
// It is opt-in, and only the Master Code can turn it off.
final BatCurity batCurity = BatCurity._();

class BatCurity extends ChangeNotifier {
  static const _enabledKey = 'batcurity_hash';
  static const _prefix = 'a2id';

  // Argon2id parameters: 16 MiB, 3 passes, 1 lane
  static const _memoryPowerOf2 = 14;
  static const _iterations = 3;
  static const _lanes = 1;

  BatCurity._();

  bool _enabled = false;

  bool get hashingEnabled => _enabled;

  Future<void> init() async {
    _enabled = await securityService.readValue<String>(_enabledKey) == '1';
    notifyListeners();
  }

  // enabling hashes the existing credentials; disabling needs the Master Code
  Future<bool> setHashing(BuildContext context, bool value) async {
    if (value == _enabled) return true;
    if (!await MasterCode.require(context)) return false;

    if (value) {
      await _migrateSecrets();
    }
    await securityService.writeValue<String>(_enabledKey, value ? '1' : null);
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
      'app_lock_panic',
      'bin_lock_pass',
      'reveal_lock_pass',
      'items_lock_pass',
      for (final v in vaults.all) v.passKey,
      for (final v in vaults.all) 'adv_vault2pass_${v.name}',
    };
    for (final key in keys) {
      final stored = await securityService.readValue<String>(key);
      if (stored == null || isHashed(stored)) continue;
      await securityService.writeValue<String>(key, await _hash(stored));
    }
  }

  static bool isHashed(String stored) => stored.startsWith('$_prefix:');

  // value to store for a new secret
  Future<String> prepare(String secret) => _enabled ? _hash(secret) : Future.value(secret);

  // stores a secret, hashed when Bat-curity hashing is on
  Future<bool> store(String key, String secret) async {
    return securityService.writeValue<String>(key, await prepare(secret));
  }

  // checks an input against the stored secret
  Future<bool> matches(String key, String input) async {
    final stored = await securityService.readValue<String>(key);
    if (stored == null) return false;
    return matchesStored(stored, input);
  }

  Future<bool> matchesStored(String stored, String input) async {
    if (!isHashed(stored)) return _constantTimeEquals(utf8.encode(stored), utf8.encode(input));

    final parts = stored.split(':');
    if (parts.length != 7) return false;
    final salt = base64.decode(parts[5]);
    final expected = base64.decode(parts[6]);
    final actual = await compute(
      _derive,
      _Job(input, salt, int.parse(parts[1]), int.parse(parts[2]), int.parse(parts[3]), expected.length),
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
