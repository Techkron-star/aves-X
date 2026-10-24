import 'package:aves/services/security_service.dart';
import 'package:test/fake.dart';

/// In-memory secure storage for model tests. It deliberately never invokes
/// Android's platform security channel.
class FakeSecurityService extends Fake implements SecurityService {
  final Map<String, Object?> _values = {};

  @override
  Future<bool> writeValue<T>(String key, T? value) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
    return true;
  }

  @override
  Future<T?> readValue<T>(String key) async {
    final value = _values[key];
    return value is T ? value : null;
  }

  @override
  Future<T?> readValueStrict<T>(String key) async {
    final value = _values[key];
    return value is T ? value : null;
  }
}
