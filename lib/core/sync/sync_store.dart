import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'diagnosis_result.dart';

/// Local, on-device history of diagnoses and their sync state.
///
/// Small enough (a few hundred entries at most) that reading/writing the
/// whole file each time is simplest — same approach as
/// `local_vector_index.dart`'s cache. Caps stored entries so a long-lived
/// install doesn't grow this file forever.
class SyncStore {
  SyncStore._();
  static final SyncStore instance = SyncStore._();

  static const int _maxEntries = 500;

  /// Bumped whenever stored results change, so screens kept alive in the
  /// tab shell (the Log) can reload.
  final ValueNotifier<int> changes = ValueNotifier(0);

  Future<File> _resultsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/sync_results.json');
  }

  Future<File> _anonIdFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/sync_anon_id.txt');
  }

  /// A random ID generated once per install, persisted locally. Not tied to
  /// any farmer identity — exists purely so a receiving server can dedupe.
  Future<String> anonymousId() async {
    final file = await _anonIdFile();
    if (await file.exists()) {
      final existing = await file.readAsString();
      if (existing.isNotEmpty) return existing;
    }
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final id = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await file.writeAsString(id);
    return id;
  }

  Future<List<DiagnosisResult>> _readAll() async {
    final file = await _resultsFile();
    if (!await file.exists()) return [];
    try {
      final raw = jsonDecode(await file.readAsString()) as List;
      return raw
          .map((e) => DiagnosisResult.fromLocalJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Keep the damaged file rather than letting the next write erase the
      // farmer's history and unsent queue.
      await file.rename('${file.path}.damaged-${DateTime.now().millisecondsSinceEpoch}');
      return [];
    }
  }

  // add() and markSynced() each read, change and rewrite the whole file. A
  // sync finishing while a new diagnosis is being saved would otherwise
  // drop one of the two writes, so they take turns.
  Future<void> _queue = Future.value();

  Future<T> _exclusive<T>(Future<T> Function() task) {
    final run = _queue.then((_) => task());
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<void> _writeAll(List<DiagnosisResult> results) async {
    final file = await _resultsFile();
    await file.writeAsString(
      jsonEncode(results.map((r) => r.toLocalJson()).toList()),
    );
  }

  /// All stored results, most recent first.
  Future<List<DiagnosisResult>> all() async {
    final results = await _readAll();
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  /// Results not yet synced that the farmer agreed to share.
  Future<List<DiagnosisResult>> pending() async {
    final results = await _readAll();
    return results.where((r) => !r.synced && r.reportable).toList();
  }

  Future<void> add(DiagnosisResult result) => _exclusive(() => _add(result));

  Future<void> _add(DiagnosisResult result) async {
    final results = await _readAll();
    // Same id means the farmer changed their pick: replace it, and send the
    // correction even if the first pick was already uploaded.
    results.removeWhere((r) => r.id == result.id);
    results.add(result);
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (results.length > _maxEntries) {
      // Evict the oldest entries that will never be sent (already synced,
      // or made with reporting off); keep ones still waiting to upload.
      final overflow = results.length - _maxEntries;
      final doneOldestFirst =
          results.where((r) => r.synced || !r.reportable).toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final toEvict = doneOldestFirst.take(overflow).map((r) => r.id).toSet();
      results.removeWhere((r) => toEvict.contains(r.id));
    }
    await _writeAll(results);
    changes.value++;
  }

  Future<void> markSynced(List<String> ids) => _exclusive(() => _markSynced(ids));

  Future<void> _markSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    final results = await _readAll();
    for (final r in results) {
      if (idSet.contains(r.id)) r.synced = true;
    }
    await _writeAll(results);
    changes.value++;
  }
}
