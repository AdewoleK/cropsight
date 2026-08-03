import 'package:flutter/material.dart';

import '../../core/sync/diagnosis_result.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/sync_store.dart';

/// Demo/debug screen: shows what's queued/synced locally and lets you force
/// a sync attempt. Stands in for a real agronomist dashboard until there's an
/// actual backend to build one against.
class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  List<DiagnosisResult> _results = [];
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await SyncStore.instance.all();
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    await SyncService.instance.syncNow();
    await _load();
    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = _results.where((r) => !r.synced).length;
    final synced = _results.length - pending;

    return Scaffold(
      appBar: AppBar(title: const Text('Sync status')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                            label: 'Pending', value: '$pending', theme: theme),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                            label: 'Synced', value: '$synced', theme: theme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _syncing ? null : _syncNow,
                    icon: _syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync),
                    label: const Text('Sync now'),
                  ),
                  const SizedBox(height: 24),
                  if (_results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text('No diagnoses yet.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium),
                    )
                  else ...[
                    Text('Recent diagnoses', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    for (final result in _results) _ResultTile(result: result),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.theme});
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.headlineMedium),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});
  final DiagnosisResult result;

  @override
  Widget build(BuildContext context) {
    final topCard = result.citedCards.isNotEmpty ? result.citedCards.first : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        result.synced ? Icons.cloud_done : Icons.cloud_queue,
        color: result.synced ? Colors.green : null,
      ),
      title: Text(topCard?.label ?? 'Diagnosis'),
      subtitle: Text(_formatTimestamp(result.timestamp)),
      trailing: Text(result.synced ? 'Synced' : 'Pending'),
    );
  }

  String _formatTimestamp(DateTime t) {
    final local = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
