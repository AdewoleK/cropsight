import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../settings/app_settings.dart';
import 'diagnosis_result.dart';
import 'sync_store.dart';
import 'sync_target.dart';

/// Orchestrates opportunistic sync: queue locally, flush whenever
/// connectivity appears. Sends to the live Plant Health Watch server unless
/// another `SYNC_ENDPOINT` is given at build time (an empty one turns sync
/// off). Nothing is sent unless the farmer turns on reporting.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final SyncStore _store = SyncStore.instance;
  SyncTarget _target = const NoopSyncTarget();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _started = false;

  AppSettings? _settings;

  /// Registers the connectivity listener. Safe to call once at app startup;
  /// a no-op endpoint means this never attempts any network access.
  /// [settings] supplies the farmer's reporting consent and LGA.
  void start(AppSettings settings) {
    if (_started) return;
    _started = true;
    _settings = settings;

    const endpoint = String.fromEnvironment('SYNC_ENDPOINT',
        defaultValue: 'https://cropsight-watch.onrender.com/api/reports');
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

  /// Queue a completed diagnosis for sync, stamped with the farmer's current
  /// consent and LGA, then try to send it straight away. Best-effort —
  /// failures here must never surface as a diagnosis error.
  Future<void> enqueueResult(DiagnosisResult result) async {
    final settings = _settings;
    try {
      await _store.add(result.withReporting(
        shared: settings?.shareReports ?? false,
        statePcode: settings?.reportStatePcode,
        lgaPcode: settings?.reportLgaPcode,
      ));
    } catch (_) {
      // Local storage failure shouldn't break the diagnosis flow.
      return;
    }
    await syncNow();
  }

  /// Flush whatever's pending through the current target. Safe to call any
  /// time (e.g. a manual "Sync now" button) — no-ops if sync is disabled or
  /// nothing is pending.
  bool _syncing = false;

  Future<void> syncNow() async {
    if (_target is NoopSyncTarget || _syncing) return;
    _syncing = true;
    try {
      await _syncPending();
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncPending() async {
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
