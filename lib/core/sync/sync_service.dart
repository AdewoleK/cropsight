import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'diagnosis_result.dart';
import 'sync_store.dart';
import 'sync_target.dart';

/// Orchestrates opportunistic sync: queue locally, flush whenever
/// connectivity appears. Disabled (fully local) unless a `SYNC_ENDPOINT` is
/// configured at build time.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final SyncStore _store = SyncStore.instance;
  SyncTarget _target = const NoopSyncTarget();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _started = false;

  /// Registers the connectivity listener. Safe to call once at app startup;
  /// a no-op endpoint means this never attempts any network access.
  void start() {
    if (_started) return;
    _started = true;

    const endpoint = String.fromEnvironment('SYNC_ENDPOINT');
    if (endpoint.isNotEmpty) {
      _target = HttpSyncTarget(Uri.parse(endpoint));
    }
    if (_target is NoopSyncTarget) return;

    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        syncNow();
      }
    });
  }

  /// Queue a completed diagnosis for sync. Best-effort — failures here must
  /// never surface as a diagnosis error.
  Future<void> enqueueResult(DiagnosisResult result) async {
    try {
      await _store.add(result);
    } catch (_) {
      // Local storage failure shouldn't break the diagnosis flow.
    }
  }

  /// Flush whatever's pending through the current target. Safe to call any
  /// time (e.g. a manual "Sync now" button) — no-ops if sync is disabled or
  /// nothing is pending.
  Future<void> syncNow() async {
    if (_target is NoopSyncTarget) return;
    final pending = await _store.pending();
    if (pending.isEmpty) return;

    final anonymousId = await _store.anonymousId();
    try {
      final ok = await _target.sync(pending, anonymousId);
      if (ok) {
        await _store.markSynced(pending.map((r) => r.id).toList());
      }
    } catch (_) {
      // Leave pending — next connectivity change or manual trigger retries.
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
