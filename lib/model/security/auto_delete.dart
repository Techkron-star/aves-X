import 'dart:async';

import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/foundation.dart';

final AutoDelete autoDelete = AutoDelete._private();

// Automatic deletion of old items, to free space or to wipe information when the user stays away:
// - the recycle bin keeps its items for a configurable time (30 days by default)
// - albums and vaults can delete the items that were added more than a configurable time ago
// Settings are kept in the secure store. Items are deleted for good (not moved to the bin).
class AutoDelete extends ChangeNotifier {
  static const _binKey = 'ad_bin_minutes';
  static const _albumsKey = 'ad_albums';

  // delays under this threshold need an explicit confirmation from the user
  static const shortDelay = Duration(hours: 48);

  static const presets = <Duration>[
    Duration(minutes: 1),
    Duration(hours: 1),
    Duration(hours: 6),
    Duration(hours: 12),
    Duration(days: 1),
    Duration(days: 2),
    Duration(days: 7),
    Duration(days: 14),
    Duration(days: 30),
    Duration(days: 90),
  ];

  AutoDelete._private();

  Duration _bin = const Duration(days: 30);
  final Map<String, Duration> _albums = {};
  Timer? _timer;

  Future<void> init() async {
    final binMinutes = int.tryParse(await securityService.readValue<String>(_binKey) ?? '');
    if (binMinutes != null && binMinutes > 0) _bin = Duration(minutes: binMinutes);
    _albums.clear();
    final raw = await securityService.readValue<String>(_albumsKey);
    if (raw != null) {
      for (final line in raw.split('\n')) {
        final i = line.lastIndexOf('\t');
        if (i <= 0) continue;
        final minutes = int.tryParse(line.substring(i + 1));
        if (minutes != null && minutes > 0) _albums[line.substring(0, i)] = Duration(minutes: minutes);
      }
    }
    notifyListeners();
  }

  Duration get binRetention => _bin;

  Duration? albumRetention(String dirPath) => _albums[dirPath];

  Future<void> setBinRetention(Duration value) async {
    _bin = value;
    await securityService.writeValue<String>(_binKey, value.inMinutes.toString());
    notifyListeners();
  }

  Future<void> setAlbumRetention(String dirPath, Duration? value) async {
    if (value == null) {
      _albums.remove(dirPath);
    } else {
      _albums[dirPath] = value;
    }
    await securityService.writeValue<String>(
      _albumsKey,
      _albums.isEmpty ? null : _albums.entries.map((kv) => '${kv.key}\t${kv.value.inMinutes}').join('\n'),
    );
    notifyListeners();
  }

  // checks every minute while the app is open
  void start(CollectionSource source) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => run(source));
    unawaited(run(source));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static int? _addedMillis(AvesEntry entry) {
    final secs = entry.dateAddedSecs;
    if (secs != null) return secs * 1000;
    return entry.dateModifiedMillis;
  }

  Future<void> run(CollectionSource source) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final kv in _albums.entries) {
        final limit = kv.value.inMilliseconds;
        final expired = source.allEntries.where((entry) {
          if (entry.trashed || entry.directory != kv.key) return false;
          final added = _addedMillis(entry);
          return added != null && now - added > limit;
        }).toSet();
        if (expired.isEmpty) continue;

        final processed = <dynamic>[];
        final deletedUris = <String>{};
        await for (final event in mediaEditService.delete(entries: expired)) {
          processed.add(event);
          if (event.success && !event.skipped) deletedUris.add(event.uri);
        }
        if (deletedUris.isNotEmpty) {
          debugPrint('auto-deleted ${deletedUris.length} items from ${kv.key}');
          await source.removeEntries(deletedUris, includeTrash: true);
        }
      }

      // the bin has its own retention (see `TrashMixin.binKeepDuration`)
      final deletedFromBin = await source.deleteExpiredTrash();
      if (deletedFromBin.isNotEmpty) {
        await source.removeEntries(deletedFromBin, includeTrash: true);
      }
    } catch (error, stack) {
      debugPrint('auto-delete failed error=$error\n$stack');
    }
  }
}
