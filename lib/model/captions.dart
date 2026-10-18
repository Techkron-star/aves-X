import 'package:aves/model/entry/entry.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/foundation.dart';

final Captions captions = Captions._private();

// free text labels on photos and videos (e.g. "foto madre 17/11/2017"), stored in the app only
// (files are never modified) and searchable from the search page
class Captions with ChangeNotifier {
  Map<int, String> _byId = {};

  new _private() {
    if (kFlutterMemoryAllocationsEnabled) ChangeNotifier.maybeDispatchObjectCreation(this);
  }

  Future<void> init() async {
    _byId = await localMediaDb.loadAllCaptions();
  }

  String? of(AvesEntry entry) => _byId[entry.id];

  Future<void> set(AvesEntry entry, String? caption) async {
    final text = caption?.trim();
    await localMediaDb.setCaption(entry.id, text);
    if (text == null || text.isEmpty) {
      _byId.remove(entry.id);
    } else {
      _byId[entry.id] = text;
    }
    notifyListeners();
  }

  void removeIds(Set<int> ids) {
    if (ids.any(_byId.containsKey)) {
      ids.forEach(_byId.remove);
      notifyListeners();
    }
  }
}
