import 'dart:io';
import 'dart:math';

import 'package:aves/model/security/failsafe_config.dart';

import 'package:aves/model/db/db.dart';
import 'package:aves/model/entry/origins.dart';
import 'package:aves/model/security/attempt_guard.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/vaults/vaults.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/foundation.dart';

// Destruction of private data.
// A "pending" flag is persisted before wiping, so that if the process is killed in the middle of the operation,
// the wipe is executed at next startup, before showing any UI.
// Only data of the app is touched (vaults, app data); other files of the device are never deleted.
class Nuke {
  static const _pendingAllKey = 'nuke_pending_all';
  static const _pendingVaultsKey = 'nuke_pending_vaults';

  static Future<void> markAll() => securityService.writeValue<String>(_pendingAllKey, '1');

  static Future<void> markVault(String name) async {
    final names = await _pendingVaults();
    if (names.add(name)) {
      await securityService.writeValue<String>(_pendingVaultsKey, names.join('\n'));
    }
  }

  static Future<Set<String>> _pendingVaults() async {
    final raw = await securityService.readValue<String>(_pendingVaultsKey);
    return raw == null || raw.isEmpty ? <String>{} : raw.split('\n').toSet();
  }

  // early at startup, before the UI: wipes everything (like clearing the data from the system settings)
  static Future<void> runPendingTotal() async {
    if (await securityService.readValue<String>(_pendingAllKey) != '1') return;
    // crypto-erase first, then wipe: on success the app data is gone and the process stops here
    await securityService.destroyCryptoKeys();
    await securityService.wipeAppData();
  }

  // at startup, once the vaults are loaded
  static Future<void> runPendingVaults() async {
    if (await securityService.readValue<String>(_pendingAllKey) == '1') {
      // the total wipe did not work: at least delete all the vaults
      await nukeAllVaults();
      await securityService.writeValue<String>(_pendingAllKey, null);
    }
    for (final name in await _pendingVaults()) {
      await nukeVaultContent(name);
    }
  }

  // wipes everything, immediately
  static Future<void> nukeEverything() async {
    await markAll();
    await runPendingTotal();
    // only reached if the system refused to clear the data
    await runPendingVaults();
  }

  // deletes all the vaults and their content (manual nuke)
  static Future<void> nukeAllVaults({CollectionSource? source}) async {
    // crypto-erase first: once the keys are gone, whatever remains of encrypted files is unreadable,
    // even if the process is killed before the files are deleted
    await securityService.destroyCryptoKeys();
    final all = vaults.all.toList();
    for (final details in all) {
      await _deleteVaultContent(details.path, source);
    }
    if (all.isNotEmpty) {
      await vaults.remove(all.map((v) => v.path).toSet());
    }
    for (final details in all) {
      await AttemptGuard.vault(details.name).reset();
    }
  }

  // deletes the content of one vault (the empty vault remains)
  static Future<void> nukeVaultContent(String name, {CollectionSource? source}) async {
    final details = vaults.all.where((v) => v.name == name).firstOrNull;
    if (details != null) {
      await _deleteVaultContent(details.path, source);
    }
    await AttemptGuard.vault(name).reset();
    final names = await _pendingVaults()..remove(name);
    await securityService.writeValue<String>(_pendingVaultsKey, names.isEmpty ? null : names.join('\n'));
  }

  static Future<void> _deleteVaultContent(String dirPath, CollectionSource? source) async {
    try {
      final entries = await localMediaDb.loadEntries(origin: EntryOrigins.vault, directory: dirPath);
      for (final entry in entries) {
        final trashPath = entry.trashDetails?.path;
        if (trashPath != null) {
          await _deleteFile(trashPath);
        }
      }
      if (entries.isNotEmpty) {
        await localMediaDb.removeIds(entries.map((v) => v.id).toSet());
        await source?.removeEntries(entries.map((v) => v.uri).toSet(), includeTrash: true);
      }
    } catch (error, stack) {
      debugPrint('Failed to clear vault entries error=$error\n$stack');
    }
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) await _shred(entity);
        }
        await dir.delete(recursive: true);
      }
    } catch (error, stack) {
      debugPrint('Failed to delete vault directory error=$error\n$stack');
    }
    await _trimIfRoot();
  }

  // overwrites the content with random data before the file is deleted, so that it is not left as is in the freed blocks
  static Future<void> _shred(File file) async {
    try {
      final length = await file.length();
      if (length == 0) return;
      final random = Random.secure();
      final raf = await file.open(mode: FileMode.writeOnly);
      try {
        const chunk = 64 * 1024;
        var written = 0;
        while (written < length) {
          final n = min(chunk, length - written);
          await raf.writeFrom(List<int>.generate(n, (_) => random.nextInt(256)));
          written += n;
        }
        await raf.flush();
      } finally {
        await raf.close();
      }
    } catch (error) {
      debugPrint('Failed to overwrite file error=$error');
    }
  }

  // Black Hole (root mode): discards the freed blocks of the data partition
  static Future<void> _trimIfRoot() async {
    try {
      if (await FailsafeConfig.rootMode) await securityService.rootTrim();
    } catch (error) {
      debugPrint('Failed to trim error=$error');
    }
  }

  static Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await _shred(file);
        await file.delete();
      }
    } catch (error) {
      debugPrint('Failed to delete file error=$error');
    }
  }
}
