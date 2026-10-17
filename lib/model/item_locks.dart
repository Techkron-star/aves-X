import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/dialogs/aves_confirmation_dialog.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/security/privacy_options.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/action_mixins/secret_lock.dart';
import 'package:flutter/widgets.dart';

final ItemLocks itemLocks = ItemLocks._private();

// Locks for regular albums and individual items (not vaults):
// locked thumbnails are blurred, and opening them requires the items lock (biometrics, PIN...).
// The list of locked albums/items is kept in the secure store.
// Once opened, an album or item stays open until the app goes to the background.
class ItemLocks extends ChangeNotifier {
  static const _albumsKey = 'locked_albums';
  static const _itemsKey = 'locked_items';
  static const _favouritesKey = 'locked_favourites';

  bool _favourites = false;

  ItemLocks._private();

  final Set<String> _albums = {};
  final Set<String> _items = {};
  final Set<String> _open = {};
  // just locked: the thumbnails play the lock animation
  final Set<String> _fresh = {};

  bool isFresh(AvesEntry entry) => _fresh.contains(entryKey(entry)) || (entry.directory != null && _fresh.contains('dir:${entry.directory}'));

  void _markFresh(Iterable<String> keys) {
    _fresh.addAll(keys);
    Future.delayed(const Duration(seconds: 3), () => _fresh.removeAll(keys.toList()));
  }

  Future<void> init() async {
    _albums
      ..clear()
      ..addAll(_decode(await securityService.readValue<String>(_albumsKey)));
    _items
      ..clear()
      ..addAll(_decode(await securityService.readValue<String>(_itemsKey)));
    _favourites = await securityService.readValue<String>(_favouritesKey) == '1';
    notifyListeners();
  }

  static Set<String> _decode(String? raw) => raw == null || raw.isEmpty ? <String>{} : raw.split('\n').where((v) => v.isNotEmpty).toSet();

  static String entryKey(AvesEntry entry) => entry.path ?? entry.uri;

  bool isAlbumLocked(String? dirPath) => privacyOptions.itemLocks && dirPath != null && _albums.contains(dirPath) && !_open.contains('a:$dirPath');

  bool isEntryLocked(AvesEntry entry) {
    if (!privacyOptions.itemLocks) return false;
    if (isAlbumLocked(entry.directory)) return true;
    final key = entryKey(entry);
    return _items.contains(key) && !_open.contains('i:$key');
  }

  // whether the album/item is marked as locked (even if it is open at the moment)
  bool isAlbumMarked(String dirPath) => _albums.contains(dirPath);

  bool isEntryMarked(AvesEntry entry) => _items.contains(entryKey(entry)) || _albums.contains(entry.directory);

  bool get favouritesMarked => _favourites;

  bool get isFavouritesLocked => privacyOptions.itemLocks && _favourites && !_open.contains('fav');

  Future<bool> unlockFavourites(BuildContext context) async {
    if (!isFavouritesLocked) return true;
    if (!await SecretLock.items.authenticate(context)) return false;

    _open.add('fav');
    notifyListeners();
    return true;
  }

  Future<void> setFavouritesLocked(BuildContext context, bool value) async {
    if (value) {
      if (!await _ensureEnabled(context) || !context.mounted || !await _ensureLock(context)) return;
    } else {
      if (!await SecretLock.items.authenticate(context)) return;
      _open.remove('fav');
    }
    _favourites = value;
    await securityService.writeValue<String>(_favouritesKey, value ? '1' : null);
    notifyListeners();
    if (context.mounted) _feedback(context, value);
  }

  void closeAll() {
    if (_open.isEmpty) return;
    _open.clear();
    notifyListeners();
  }

  Future<void> _save() async {
    await securityService.writeValue<String>(_albumsKey, _albums.isEmpty ? null : _albums.join('\n'));
    await securityService.writeValue<String>(_itemsKey, _items.isEmpty ? null : _items.join('\n'));
    notifyListeners();
  }

  // haptic and visual feedback after locking or unlocking
  void _feedback(BuildContext context, bool locked) {
    HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    // the animation is played by the locked thumbnails themselves (see `LockedBadge`)
    if (settings.animate && locked) return;
    final l10n = context.l10n;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(locked ? Icons.lock : Icons.lock_open, size: 18),
            const SizedBox(width: 12),
            Text(locked ? l10n.itemLockLockedFeedback : l10n.itemLockUnlockedFeedback),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // asks for the items lock; the user can open the item if there is no lock at all
  Future<bool> unlockEntry(BuildContext context, AvesEntry entry) async {
    if (!isEntryLocked(entry)) return true;
    if (!await SecretLock.items.authenticate(context)) return false;

    if (isAlbumLocked(entry.directory)) {
      _open.add('a:${entry.directory}');
    } else {
      _open.add('i:${entryKey(entry)}');
    }
    notifyListeners();
    return true;
  }

  Future<bool> unlockAlbum(BuildContext context, String dirPath) async {
    if (!isAlbumLocked(dirPath)) return true;
    if (!await SecretLock.items.authenticate(context)) return false;

    _open.add('a:$dirPath');
    notifyListeners();
    return true;
  }

  // item locks are opt-in: ask to enable them the first time the user wants to lock something
  Future<bool> _ensureEnabled(BuildContext context) async {
    if (privacyOptions.itemLocks) return true;
    final accepted = await showConfirmationDialog(
      context: context,
      message: context.l10n.itemLocksEnablePrompt,
      ok: context.l10n.applyButtonLabel,
    );
    if (!accepted || !context.mounted) return false;

    return privacyOptions.change(context, PrivacyOptions.itemLocksKey, true);
  }

  // the lock must exist before locking anything: creates it if needed (requires the Master Code)
  Future<bool> _ensureLock(BuildContext context) async {
    if (await SecretLock.items.getLockType() != null) return true;
    if (!context.mounted) return false;

    await SecretLock.items.configure(context);
    return await SecretLock.items.getLockType() != null;
  }

  // locks the items if some of them are not locked yet, otherwise unlocks them for good (after authentication)
  Future<void> toggleEntries(BuildContext context, Set<AvesEntry> entries) async {
    if (entries.isEmpty) return;

    final allMarked = entries.every((v) => _items.contains(entryKey(v)));
    if (allMarked) {
      if (!await SecretLock.items.authenticate(context)) return;
      _items.removeAll(entries.map(entryKey));
      _open.removeWhere((v) => v.startsWith('i:'));
    } else {
      if (!await _ensureEnabled(context) || !context.mounted || !await _ensureLock(context)) return;
      _items.addAll(entries.map(entryKey));
      _markFresh(entries.map(entryKey));
    }
    await _save();
    if (context.mounted) _feedback(context, !allMarked);
  }

  Future<void> toggleAlbums(BuildContext context, Set<String> dirPaths) async {
    if (dirPaths.isEmpty) return;

    final allMarked = dirPaths.every(_albums.contains);
    if (allMarked) {
      if (!await SecretLock.items.authenticate(context)) return;
      _albums.removeAll(dirPaths);
      _open.removeWhere((v) => v.startsWith('a:'));
    } else {
      if (!await _ensureEnabled(context) || !context.mounted || !await _ensureLock(context)) return;
      _albums.addAll(dirPaths);
      _markFresh(dirPaths.map((v) => 'dir:$v'));
    }
    await _save();
    if (context.mounted) _feedback(context, !allMarked);
  }
}
