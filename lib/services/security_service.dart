import 'package:aves/services/common/channel.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/services.dart';

class SecurityClockInfo {
  // monotonic time since boot, not affected by changes of the system date and time
  final int elapsedRealtimeMillis;

  // number of device boots, or `-1` when unavailable
  final int bootCount;

  const SecurityClockInfo({
    required this.elapsedRealtimeMillis,
    required this.bootCount,
  });
}

abstract class SecurityService {
  Future<bool> writeValue<T>(String key, T? value);

  Future<T?> readValue<T>(String key);

  Future<SecurityClockInfo?> getClockInfo();

  // clears all the data of the app (vaults included) and stops the app, `false` if it failed
  Future<bool> wipeAppData();

  // encrypts or decrypts the files of a vault (by name); `null` if the call failed
  Future<VaultCryptoReport?> cryptVault(String vault, {required bool encrypt});

  // same for all the vaults
  Future<VaultCryptoReport?> cryptAllVaults({required bool encrypt});

  // `null` when the encryption key works, the error otherwise
  Future<String?> cryptSelfTest();

  // crypto-erase: destroys the vault encryption keys
  Future<bool> destroyCryptoKeys();

  // Black Hole (optional root mode)
  Future<bool> isRootAvailable();

  Future<bool> rootTrim();
}

class VaultCryptoReport {
  final int done, skipped, failed;
  final List<String> errors;

  const VaultCryptoReport({required this.done, required this.skipped, required this.failed, this.errors = const []});

  bool get success => failed == 0;
}

class PlatformSecurityService implements SecurityService {
  static const _platform = AvesMethodChannel('deckers.thibault/aves/security');

  @override
  Future<bool> writeValue<T>(String key, T? value) async {
    try {
      await _platform.invokeMethod('writeValue', <String, Object?>{
        'key': key,
        'value': value,
      });
      return true;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return false;
  }

  @override
  Future<T?> readValue<T>(String key) async {
    try {
      final result = await _platform.invokeMethod('readValue', <String, Object?>{
        'key': key,
      });
      if (result != null) return result as T;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return null;
  }

  @override
  Future<SecurityClockInfo?> getClockInfo() async {
    try {
      final result = await _platform.invokeMethod<Map>('getClockInfo');
      if (result != null) {
        return SecurityClockInfo(
          elapsedRealtimeMillis: (result['elapsedRealtimeMillis'] as num).toInt(),
          bootCount: (result['bootCount'] as num).toInt(),
        );
      }
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return null;
  }

  @override
  Future<bool> wipeAppData() async {
    try {
      final result = await _platform.invokeMethod<bool>('wipeAppData');
      return result ?? false;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return false;
  }

  @override
  Future<VaultCryptoReport?> cryptVault(String vault, {required bool encrypt}) => _crypt('cryptVault', {'vault': vault, 'encrypt': encrypt});

  @override
  Future<VaultCryptoReport?> cryptAllVaults({required bool encrypt}) => _crypt('cryptAllVaults', {'encrypt': encrypt});

  Future<VaultCryptoReport?> _crypt(String method, Map<String, Object?> args) async {
    try {
      final result = await _platform.invokeMethod<Map>(method, args);
      if (result != null) {
        return VaultCryptoReport(
          done: (result['done'] as num).toInt(),
          skipped: (result['skipped'] as num).toInt(),
          failed: (result['failed'] as num).toInt(),
          errors: (result['errors'] as List?)?.map((v) => v.toString()).toList() ?? const [],
        );
      }
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return null;
  }

  @override
  Future<String?> cryptSelfTest() async {
    try {
      return await _platform.invokeMethod<String>('cryptSelfTest');
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
      return e.message ?? e.code;
    }
  }

  @override
  Future<bool> destroyCryptoKeys() async {
    try {
      return await _platform.invokeMethod<bool>('destroyCryptoKeys') ?? false;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
      return false;
    }
  }

  @override
  Future<bool> isRootAvailable() async {
    try {
      return await _platform.invokeMethod<bool>('isRootAvailable') ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> rootTrim() async {
    try {
      return await _platform.invokeMethod<bool>('rootTrim') ?? false;
    } on PlatformException {
      return false;
    }
  }
}
