import 'dart:async';

import 'package:aves/model/security/failsafe.dart';
import 'package:aves/model/security/failsafe_config.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/services.dart';

enum AttemptOutcome { failed, cooldown, nuke }

// Persistent counter of failed attempts for one kind of secret (app PIN, Master Code, or one vault).
// - state is written to the secure store right after each failure (survives killing the app and clearing the cache)
// - 3 failures start a 5 minute cooldown (with vibration), the 4th failure triggers a nuke
// - the cooldown uses the monotonic clock of the device, so that changing the system date does not skip it;
//   after a reboot (or if the monotonic clock goes backwards), the cooldown restarts from the beginning
class AttemptGuard {
  static const cooldownFailures = 3;
  static const nukeFailures = 4;
  static const cooldownDuration = Duration(minutes: 5);

  static final app = AttemptGuard._('app');
  static final master = AttemptGuard._('master');
  static final Map<String, AttemptGuard> _scopedInstances = {};

  // Reuse one guard per vault/lock. A new instance per prompt would defeat the in-memory queue
  // and let concurrent dialogs race the same persistent counter.
  static AttemptGuard vault(String name) => _scopedInstances.putIfAbsent('vault_$name', () => AttemptGuard._('vault_$name'));

  // other locks (bin, hidden items reveal, locked items)
  static AttemptGuard named(String name) => _scopedInstances.putIfAbsent('lock_$name', () => AttemptGuard._('lock_$name'));

  final String id;
  // Serialize updates so concurrent completions cannot overwrite the persistent counter with a stale value.
  Future<void> _failureQueue = Future<void>.value();

  AttemptGuard._(this.id);

  String get _failsKey => 'att_${id}_fails';

  String get _cooldownKey => 'att_${id}_cooldown';

  Future<void> _writeRequired(String key, String? value) async {
    if (!await securityService.writeValue<String>(key, value)) {
      throw StateError('Could not persist security state for $key');
    }
  }

  Future<int> failures() async => int.tryParse(await securityService.readValue<String>(_failsKey) ?? '') ?? 0;

  // `null` when there is no cooldown
  Future<Duration?> remainingCooldown() async {
    final raw = await securityService.readValue<String>(_cooldownKey);
    if (raw == null) return null;

    // `elapsedRealtime|bootCount|wallClockMillis|durationMillis` (the duration is missing in older markers)
    final parts = raw.split('|');
    if (parts.length < 3) return cooldownDuration;
    final duration = parts.length > 3 ? Duration(milliseconds: int.tryParse(parts[3]) ?? cooldownDuration.inMilliseconds) : cooldownDuration;
    final startElapsed = int.tryParse(parts[0]);
    final startBoot = int.tryParse(parts[1]);
    final startWall = int.tryParse(parts[2]);
    if (startElapsed == null || startBoot == null || startWall == null) return cooldownDuration;

    final clock = await securityService.getClockInfo();
    int elapsedSinceStart;
    if (clock == null) {
      // no monotonic clock available, fall back to the system clock, but never trust a clock set in the past
      elapsedSinceStart = DateTime.now().millisecondsSinceEpoch - startWall;
      if (elapsedSinceStart < 0) {
        await _startCooldown(duration);
        return duration;
      }
    } else {
      final rebooted = (startBoot >= 0 && clock.bootCount >= 0 && clock.bootCount != startBoot) || clock.elapsedRealtimeMillis < startElapsed;
      if (rebooted) {
        // cannot tell how long the device was off: restart the cooldown
        await _startCooldown(duration);
        return duration;
      }
      elapsedSinceStart = clock.elapsedRealtimeMillis - startElapsed;
    }

    final remaining = duration - Duration(milliseconds: elapsedSinceStart);
    if (remaining <= Duration.zero) {
      // keep the marker: the failure counter stays at its value, and the next failure will nuke
      await _writeRequired(_cooldownKey, null);
      return null;
    }
    return remaining;
  }

  Future<void> _startCooldown(Duration duration) async {
    final clock = await securityService.getClockInfo();
    final value = '${clock?.elapsedRealtimeMillis ?? 0}|${clock?.bootCount ?? -1}|${DateTime.now().millisecondsSinceEpoch}|${duration.inMilliseconds}';
    await _writeRequired(_cooldownKey, value);
  }

  // to be called after each verified failed attempt (the counter is persisted before returning)
  // Queue the read-modify-write sequence: two callbacks must never both count as the same failure.
  Future<AttemptOutcome> registerFailure() {
    final completer = Completer<AttemptOutcome>();
    _failureQueue = _failureQueue.then((_) async {
      try {
        completer.complete(await _registerFailure());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  Future<AttemptOutcome> _registerFailure() async {
    final count = await failures() + 1;
    await _writeRequired(_failsKey, count.toString());
    final nukeEnabled = await FailsafeConfig.nukeOnFailures;
    // Global nuke is only valid for the app lock and Master Code. Vaults have their own
    // targeted nuke callback; auxiliary locks (bin/reveal/items) must never wipe app data.
    final supportsNuke = id == 'app' || id == 'master' || id.startsWith('vault_');
    if (nukeEnabled && supportsNuke && count >= nukeFailures) {
      return AttemptOutcome.nuke;
    }
    if (count >= cooldownFailures) {
      // the cooldown grows with each failure, up to the configured maximum
      await _startCooldown(await FailsafeConfig.cooldownFor(count));
      await HapticFeedback.vibrate();
      // without the nuke, the Failsafe takes control of the app until the Master Code is entered
      if (count >= nukeFailures && (id == 'app' || id == 'master') && await FailsafeConfig.lockdownEnabled && await securityService.readValue<String>('master_code') != null) {
        await failsafe.engageLockdown();
      }
      return AttemptOutcome.cooldown;
    }
    return AttemptOutcome.failed;
  }

  Future<void> reset() {
    final completer = Completer<void>();
    // Reset shares the same queue as failures, so a successful authentication cannot race
    // with a stale read-modify-write and leave the counter incremented.
    _failureQueue = _failureQueue.then((_) async {
      try {
        await _writeRequired(_failsKey, null);
        await securityService.writeValue<String>(_cooldownKey, null);
        await _writeRequired('att_${id}_bio', null);
        completer.complete();
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  // biometric failures add to the same counter, but after 3 of them the PIN is mandatory
  Future<int> biometricFailures() async => int.tryParse(await securityService.readValue<String>('att_${id}_bio') ?? '') ?? 0;

  Future<AttemptOutcome> registerBiometricFailure() {
    final completer = Completer<AttemptOutcome>();
    // Keep the biometric counter and shared failure counter in the same serialized operation.
    _failureQueue = _failureQueue.then((_) async {
      try {
        final count = await biometricFailures() + 1;
        await _writeRequired('att_${id}_bio', count.toString());
        completer.complete(await _registerFailure());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }
}
