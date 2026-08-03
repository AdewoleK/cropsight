import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
      return [];
    }
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

  /// Results not yet synced.
  Future<List<DiagnosisResult>> pending() async {
    final results = await _readAll();
    return results.where((r) => !r.synced).toList();
  }

  Future<void> add(DiagnosisResult result) async {
    final results = await _readAll();
    results.add(result);
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (results.length > _maxEntries) {
      // Evict the oldest already-synced entries first; keep pending ones.
      final overflow = results.length - _maxEntries;
      final syncedOldestFirst = results.where((r) => r.synced).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final toEvict = syncedOldestFirst.take(overflow).map((r) => r.id).toSet();
      results.removeWhere((r) => toEvict.contains(r.id));
    }
    await _writeAll(results);
  }

  Future<void> markSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    final results = await _readAll();
    for (final r in results) {
      if (idSet.contains(r.id)) r.synced = true;
    }
    await _writeAll(results);
  }
}
