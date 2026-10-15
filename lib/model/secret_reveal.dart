import 'package:flutter/foundation.dart';

final SecretReveal secretReveal = SecretReveal._private();

// Session-only switch, never persisted: while active, the filters hidden by the user
// (`settings.hiddenFilters`) are not applied, so hidden albums can be browsed again,
// and vaults hidden from the album list are listed again.
// Locked vaults are not affected: they still need to be unlocked.
//
// It is toggled by holding the Albums item of the bottom navigation bar,
// and after passing the reveal lock when revealing (hiding does not require it).
// It switches off by itself when the app goes to the background.
// It gives no visual, haptic or sound feedback on purpose.
class SecretReveal extends ChangeNotifier {
  static const Duration holdDuration = Duration(seconds: 5);

  SecretReveal._private();

  bool _active = false;

  bool get active => _active;

  set active(bool value) {
    if (_active == value) return;

    _active = value;
    notifyListeners();
  }
}
