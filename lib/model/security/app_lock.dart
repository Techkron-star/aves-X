import 'package:aves/model/security/master_guard.dart';
import 'package:aves/model/security/attempt_guard.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/foundation.dart';

final AppLock appLock = AppLock._private();

enum AppLockResult { unlocked, panic, wrong, nuke, cooldown }

// Startup lock: App PIN (6 digits), optional biometrics, optional panic PIN.
// The secrets are in the secure store. Attempts are counted by `AttemptGuard.app`.
class AppLock extends ChangeNotifier {
  static const _pinKey = 'app_lock_pin';
  static const _altKey = 'app_lock_alt_secret';
  static const _typeKey = 'app_lock_type';
  static const _biometricKey = 'app_lock_bio';
  static const _panicKey = 'app_lock_panic';

  static const _delayKey = 'app_lock_delay';

  // delays in the background before the app locks again (zero: as soon as the app comes back)
  static const relockDelayOptions = [Duration.zero, Duration(seconds: 30), Duration(minutes: 1), Duration(minutes: 5)];
  static const defaultRelockDelay = Duration(seconds: 30);

  AppLock._private();

  Duration _relockDelay = defaultRelockDelay;
  bool _ready = false;
  bool _enabled = false;
  bool _biometric = false;
  bool _hasPanic = false;
  bool _locked = true;
  String _lockTypeName = 'code';
  Stopwatch? _background;

  // `false` until the state is read from the secure store
  bool get ready => _ready;

  bool get enabled => _enabled;

  bool get biometricEnabled => _biometric;

  bool get hasPanicPin => _hasPanic;

  /// `code` preserves the legacy six-digit app PIN; other types use the shared lock challenge.
  String get lockTypeName => _lockTypeName;

  static String get secretKey => _pinKey;

  static String get alternativeSecretKey => _altKey;

  bool get locked => _locked;

  Duration get relockDelay => _relockDelay;

  Future<void> init() async {
    final storedType = await securityService.readValue<String>(_typeKey);
    _lockTypeName = storedType ?? 'code';
    final hasSecret = await securityService.readValue<String>(_pinKey) != null;
    final hasAlternativeSecret = await securityService.readValue<String>(_altKey) != null;
    _enabled = storedType != null || hasSecret;
    if (storedType != null && storedType != 'code' && storedType != 'system' && !hasAlternativeSecret) {
      // Keep a malformed configured lock closed instead of silently disabling protection.
      _enabled = true;
    }
    _biometric = await securityService.readValue<String>(_biometricKey) == '1';
    _hasPanic = await securityService.readValue<String>(_panicKey) != null;
    final delaySeconds = int.tryParse(await securityService.readValue<String>(_delayKey) ?? '');
    _relockDelay = relockDelayOptions.firstWhere((v) => v.inSeconds == delaySeconds, orElse: () => defaultRelockDelay);
    _locked = _enabled;
    _ready = true;
    notifyListeners();
  }

  Future<bool> setPin(String pin) async {
    final stored = await masterGuard.store(_pinKey, pin);
    final typed = stored && await securityService.writeValue<String>(_typeKey, 'code');
    final ok = stored && typed;
    if (ok) {
      await securityService.writeValue<String>(_altKey, null);
      _lockTypeName = 'code';
      _enabled = true;
      notifyListeners();
    }
    return ok;
  }

  /// Activates an alternative lock type after its secret has been stored successfully.
  /// The Master Code remains separate and is never affected by this selection.
  Future<bool> setLockType(String type) async {
    if (type == 'code') return false;
    if (type != 'system' && await securityService.readValue<String>(_altKey) == null) return false;
    // Commit the new mode only after the new secret (if any) is safely stored under its own key.
    if (!await securityService.writeValue<String>(_typeKey, type)) return false;
    // Stale credentials are not used by the new mode; remove them after the mode switch is durable.
    if (type == 'system') {
      await securityService.writeValue<String>(_altKey, null);
    } else {
      await securityService.writeValue<String>(_pinKey, null);
    }
    await securityService.writeValue<String>(_panicKey, null);
    _lockTypeName = type;
    _enabled = true;
    _hasPanic = false;
    notifyListeners();
    return true;
  }

  Future<void> alternativeSucceeded() async {
    _locked = false;
    notifyListeners();
  }

  Future<void> disable() async {
    await securityService.writeValue<String>(_pinKey, null);
    await securityService.writeValue<String>(_altKey, null);
    await securityService.writeValue<String>(_biometricKey, null);
    await securityService.writeValue<String>(_panicKey, null);
    await securityService.writeValue<String>(_typeKey, null);
    await securityService.writeValue<String>(_delayKey, null);
    await AttemptGuard.app.reset();
    _enabled = false;
    _biometric = false;
    _hasPanic = false;
    _lockTypeName = 'code';
    _relockDelay = defaultRelockDelay;
    _locked = false;
    notifyListeners();
  }

  Future<void> setRelockDelay(Duration delay) async {
    await securityService.writeValue<String>(_delayKey, delay.inSeconds.toString());
    _relockDelay = delay;
    notifyListeners();
  }

  Future<void> setBiometric(bool value) async {
    await securityService.writeValue<String>(_biometricKey, value ? '1' : null);
    _biometric = value;
    notifyListeners();
  }

  Future<bool> setPanicPin(String? pin) async {
    final ok = pin == null ? await securityService.writeValue<String>(_panicKey, null) : await masterGuard.store(_panicKey, pin);
    if (ok) {
      _hasPanic = pin != null;
      notifyListeners();
    }
    return ok;
  }

  // the panic PIN has to differ from the app PIN, otherwise it would never be usable
  Future<bool> isSameAsPin(String code) => masterGuard.matches(_pinKey, code);

  Future<AppLockResult> attemptPin(String code) async {
    if (_lockTypeName != 'code') throw StateError('PIN verification requested for an alternative lock type');
    final guard = AttemptGuard.app;
    if (await guard.remainingCooldown() != null) return AppLockResult.cooldown;

    if (await masterGuard.matches(_pinKey, code)) {
      await guard.reset();
      _locked = false;
      notifyListeners();
      return AppLockResult.unlocked;
    }
    if (_hasPanic && await masterGuard.matches(_panicKey, code)) {
      return AppLockResult.panic;
    }
    return _fail(guard.registerFailure());
  }

  Future<AppLockResult> biometricSucceeded() async {
    await AttemptGuard.app.reset();
    _locked = false;
    notifyListeners();
    return AppLockResult.unlocked;
  }

  Future<AppLockResult> biometricFailed() => _fail(AttemptGuard.app.registerBiometricFailure());

  Future<AppLockResult> _fail(Future<AttemptOutcome> outcome) async {
    switch (await outcome) {
      case AttemptOutcome.nuke:
        return AppLockResult.nuke;
      case AttemptOutcome.cooldown:
        return AppLockResult.cooldown;
      case AttemptOutcome.failed:
        return AppLockResult.wrong;
    }
  }

  Future<bool> canUseBiometric() async => _biometric && await AttemptGuard.app.biometricFailures() < 3;

  void onPaused() {
    _background = Stopwatch()..start();
  }

  void onResumed() {
    final elapsed = _background?.elapsed;
    _background = null;
    if (_enabled && elapsed != null && elapsed >= relockDelay) {
      _locked = true;
      notifyListeners();
    }
  }
}
