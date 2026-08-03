import 'dart:convert';

import 'package:http/http.dart' as http;

import 'diagnosis_result.dart';

/// Where synced results go. Pluggable so a real backend can be wired in later
/// without touching the queueing/connectivity logic in [SyncService].
abstract class SyncTarget {
  /// Attempt to sync [results] (already anonymised via [DiagnosisResult]).
  /// Returns true on success.
  Future<bool> sync(List<DiagnosisResult> results, String anonymousId);
}

/// Default target when no endpoint is configured — sync stays fully local.
class NoopSyncTarget implements SyncTarget {
  const NoopSyncTarget();

  @override
  Future<bool> sync(List<DiagnosisResult> results, String anonymousId) async =>
      false;
}

/// POSTs the anonymised payload to a configured HTTP endpoint.
class HttpSyncTarget implements SyncTarget {
  const HttpSyncTarget(this.endpoint);
  final Uri endpoint;

  @override
  Future<bool> sync(List<DiagnosisResult> results, String anonymousId) async {
    final body = jsonEncode({
      'results': results.map((r) => r.toSyncPayload(anonymousId)).toList(),
    });
    final response = await http.post(
      endpoint,
      headers: const {'Content-Type': 'application/json'},
      body: body,
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }
}
