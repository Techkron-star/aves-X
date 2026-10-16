import 'package:aves/model/security/master_code.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/widgets.dart';

final PrivacyOptions privacyOptions = PrivacyOptions._private();

// Switches to enable or disable each privacy feature, kept in the secure store.
// Everything is opt-in: all the features are off until the user turns them on.
// Turning a protection off requires the Master Code; turning it on does not.
class PrivacyOptions extends ChangeNotifier {
  static const strictDeleteKey = 'opt_strict_delete';
  static const itemLocksKey = 'opt_item_locks';
  static const revealGestureKey = 'opt_reveal_gesture';

  PrivacyOptions._private();

  final Map<String, bool> _values = {};

  Future<void> init() async {
    for (final key in const [strictDeleteKey, itemLocksKey, revealGestureKey]) {
      final raw = await securityService.readValue<String>(key);
      // all the features are opt-in (disabled by default)
      _values[key] = raw == '1';
    }
    notifyListeners();
  }

  bool _get(String key) => _values[key] ?? false;

  // double confirmation (red button with a delay, then typing the word) before deleting
  bool get strictDelete => _get(strictDeleteKey);

  // lock of albums and items, with blurred thumbnails
  bool get itemLocks => _get(itemLocksKey);

  // hold gesture on the Albums button to reveal hidden items
  bool get revealGesture => _get(revealGestureKey);

  Future<void> _set(String key, bool value) async {
    await securityService.writeValue<String>(key, value ? '1' : null);
    _values[key] = value;
    notifyListeners();
  }

  // returns whether the value was changed
  Future<bool> change(BuildContext context, String key, bool value) async {
    if (!value && !await MasterCode.require(context)) return false;

    await _set(key, value);
    return true;
  }
}
