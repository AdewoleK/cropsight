import 'package:flutter/material.dart';

import '../../core/sync/diagnosis_result.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/sync_store.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets.dart';
import '../settings/settings_screen.dart';

/// The field log: what's queued/synced locally, with a manual sync trigger.
/// Stands in for a real agronomist dashboard until there's an actual backend
/// to build one against.
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
    SyncStore.instance.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    SyncStore.instance.changes.removeListener(_load);
    super.dispose();
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
    final p = context.palette;
    final pending = _results.where((r) => !r.synced).length;
    final synced = _results.length - pending;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Field log'), style: AppTheme.stencil(size: 19, color: p.ink)),
        actions: [
          OfflinePill(
            label: pending == 0
                ? context.tr('ALL SYNCED')
                : context.tr('{n} UNSYNCED', {'n': pending}),
            dotColor: pending == 0 ? p.fern : p.marigold,
          ),
          const SettingsButton(),
          const SizedBox(width: 8),
        ],
      ),
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
                          child: _StatBox(label: context.tr('Pending'), value: pending, p: p)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatBox(label: context.tr('Synced'), value: synced, p: p)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _syncing ? null : _syncNow,
                    icon: _syncing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: p.onRust),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text(context.tr('Sync now')),
                  ),
                  const SizedBox(height: 8),
                  if (_results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.center_focus_strong_outlined,
                              size: 32, color: p.husk),
                          const SizedBox(height: 10),
                          Text(context.tr('No diagnoses yet.'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: p.husk, fontSize: 13)),
                        ],
                      ),
                    )
                  else ...[
                    SectionLabel(context.tr('Recent')),
                    for (final result in _results) _LogRow(result: result),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.p});
  final String label;
  final int value;
  final CropSightPalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: p.paper2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: AppTheme.stencil(size: 30, color: p.ink)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: p.husk)),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.result});
  final DiagnosisResult result;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final topCard = result.citedCards.isNotEmpty ? result.citedCards.first : null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.hairline))),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: result.synced ? p.fern : p.marigold, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topCard?.label ?? context.tr('Diagnosis'),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(_formatTimestamp(result.timestamp),
                    style: TextStyle(fontSize: 10.5, color: p.husk)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: result.synced ? p.fern : p.paper2,
              borderRadius: BorderRadius.circular(6),
              border: result.synced ? null : Border.all(color: p.hairline),
            ),
            child: Text(
              result.synced ? context.tr('SYNCED') : context.tr('PENDING'),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: result.synced ? p.onFern : p.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime t) {
    final local = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
