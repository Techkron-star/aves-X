import 'package:aves/model/security/bat_curity.dart';
import 'package:aves/model/security/attempt_guard.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/foundation.dart';

final AppLock appLock = AppLock._private();

enum AppLockResult { unlocked, panic, wrong, nuke, cooldown }

// Startup lock: App PIN (6 digits), optional biometrics, optional panic PIN.
// The secrets are in the secure store. Attempts are counted by `AttemptGuard.app`.
class AppLock extends ChangeNotifier {
  static const _pinKey = 'app_lock_pin';
  static const _biometricKey = 'app_lock_bio';
  static const _panicKey = 'app_lock_panic';

  // delay in the background before the app locks again
  static const relockDelay = Duration(seconds: 30);

  AppLock._private();

  bool _ready = false;
  bool _enabled = false;
  bool _biometric = false;
  bool _hasPanic = false;
  bool _locked = true;
  Stopwatch? _background;

  // `false` until the state is read from the secure store
  bool get ready => _ready;

  bool get enabled => _enabled;

  bool get biometricEnabled => _biometric;

  bool get hasPanicPin => _hasPanic;

  bool get locked => _locked;

  Future<void> init() async {
    _enabled = await securityService.readValue<String>(_pinKey) != null;
    _biometric = await securityService.readValue<String>(_biometricKey) == '1';
    _hasPanic = await securityService.readValue<String>(_panicKey) != null;
    _locked = _enabled;
    _ready = true;
    notifyListeners();
  }

  Future<bool> setPin(String pin) async {
    final ok = await batCurity.store(_pinKey, pin);
    if (ok) {
      _enabled = true;
      notifyListeners();
    }
    return ok;
  }

  Future<void> disable() async {
    await securityService.writeValue<String>(_pinKey, null);
    await securityService.writeValue<String>(_biometricKey, null);
    await securityService.writeValue<String>(_panicKey, null);
    await AttemptGuard.app.reset();
    _enabled = false;
    _biometric = false;
    _hasPanic = false;
    _locked = false;
    notifyListeners();
  }

  Future<void> setBiometric(bool value) async {
    await securityService.writeValue<String>(_biometricKey, value ? '1' : null);
    _biometric = value;
    notifyListeners();
  }

  Future<bool> setPanicPin(String? pin) async {
    final ok = pin == null ? await securityService.writeValue<String>(_panicKey, null) : await batCurity.store(_panicKey, pin);
    if (ok) {
      _hasPanic = pin != null;
      notifyListeners();
    }
    return ok;
  }

  // the panic PIN has to differ from the app PIN, otherwise it would never be usable
  Future<bool> isSameAsPin(String code) => batCurity.matches(_pinKey, code);

  Future<AppLockResult> attemptPin(String code) async {
    final guard = AttemptGuard.app;
    if (await guard.remainingCooldown() != null) return AppLockResult.cooldown;

    if (await batCurity.matches(_pinKey, code)) {
      await guard.reset();
      _locked = false;
      notifyListeners();
      return AppLockResult.unlocked;
    }
    if (_hasPanic && await batCurity.matches(_panicKey, code)) {
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
