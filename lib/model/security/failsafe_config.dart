import 'package:aves/services/common/services.dart';

// Failsafe lockdown options, kept in the secure store.
// Failed attempts first start a cooldown that grows with each failure up to a configurable maximum.
// The destructive reaction (nuke after too many failures) is optional and off by default: without it,
// the 4th failure engages the lockdown, a full screen that only the Master Code can lift.
class FailsafeConfig {
  static const _lockdownKey = 'fs_lockdown';
  static const _nukeKey = 'fs_nuke';
  static const _maxKey = 'fs_max_min';
  static const _activeKey = 'fs_lockdown_active';

  static const recommendedMaxMinutes = 5;
  // above this, the user is asked to confirm
  static const warnAboveMinutes = 120;
  static const maxMinutesOptions = [1, 5, 15, 30, 60, 120, 240, 480, 1440];
  static const _baseCooldown = Duration(seconds: 15);

  static Future<bool> get lockdownEnabled async => await securityService.readValue<String>(_lockdownKey) != '0';

  static Future<void> setLockdownEnabled(bool value) => securityService.writeValue<String>(_lockdownKey, value ? '1' : '0');

  static Future<bool> get nukeOnFailures async => await securityService.readValue<String>(_nukeKey) == '1';

  static Future<void> setNukeOnFailures(bool value) => securityService.writeValue<String>(_nukeKey, value ? '1' : '0');

  // Black Hole: optional root mode, off by default
  static Future<bool> get rootMode async => await securityService.readValue<String>('fs_root') == '1';

  static Future<void> setRootMode(bool value) => securityService.writeValue<String>('fs_root', value ? '1' : '0');

  static Future<int> get maxMinutes async => int.tryParse(await securityService.readValue<String>(_maxKey) ?? '') ?? recommendedMaxMinutes;

  static Future<void> setMaxMinutes(int minutes) => securityService.writeValue<String>(_maxKey, '$minutes');

  static Future<bool> get lockdownActive async => await securityService.readValue<String>(_activeKey) == '1';

  static Future<void> setLockdownActive(bool value) => securityService.writeValue<String>(_activeKey, value ? '1' : null);

  // 15 s at the 3rd failure, doubling at each next failure, never above the configured maximum
  static Future<Duration> cooldownFor(int failures) async {
    final max = Duration(minutes: await maxMinutes);
    final steps = (failures - 3).clamp(0, 20);
    final duration = _baseCooldown * (1 << steps);
    return duration > max ? max : duration;
  }
}
