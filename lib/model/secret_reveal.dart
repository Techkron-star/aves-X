import 'package:flutter/foundation.dart';

final SecretReveal secretReveal = SecretReveal._private();

// Session-only switch, never persisted: while active, the filters hidden by the user
// (`settings.hiddenFilters`) are not applied, so hidden albums can be browsed again.
// Locked vaults are not affected: they are listed as usual and still need to be unlocked.
//
// It is toggled by tapping `tapCount` times within `tapWindow` on a bottom navigation bar item,
// and it switches off by itself when the app goes to the background.
// It gives no visual, haptic or sound feedback on purpose.
class SecretReveal extends ChangeNotifier {
  static const int tapCount = 5;
  static const Duration tapWindow = Duration(seconds: 2);

  SecretReveal._private();

  bool _active = false;
  final List<DateTime> _taps = [];

  bool get active => _active;

  set active(bool value) {
    if (_active == value) return;

    _active = value;
    _taps.clear();
    notifyListeners();
  }

  void registerTap() {
    final now = DateTime.now();
    _taps
      ..add(now)
      ..removeWhere((tap) => now.difference(tap) > tapWindow);
    if (_taps.length >= tapCount) {
      active = !_active;
    }
  }
}
