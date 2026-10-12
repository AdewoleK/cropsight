import 'package:flutter/material.dart';

import '../../core/fields/field_store.dart';
import '../../core/reminders/reminder_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets.dart';
import 'field_sheets.dart';
import 'fields_screen.dart';

/// One field across the season: first vs latest photo, every check in
/// order, and its reminders.
class FieldDetailScreen extends StatelessWidget {
  const FieldDetailScreen({super.key, required this.fieldId});
  final String fieldId;

  Future<void> _confirmDelete(BuildContext context, FarmField field) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${field.name}"?'),
        content: const Text('Its photos and reminders are deleted from this phone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ReminderService.instance.deleteForField(field.id);
    await FieldStore.instance.deleteField(field.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListenableBuilder(
      listenable: Listenable.merge([FieldStore.instance, ReminderService.instance]),
      builder: (context, _) {
        final store = FieldStore.instance;
        final field = store.field(fieldId);
        if (field == null) return const Scaffold();
        final entries = store.entriesFor(fieldId);
        final photos = store.photoEntriesFor(fieldId);
        final reminders = ReminderService.instance.openFor(fieldId);

        return Scaffold(
          appBar: AppBar(
            title: Text(field.name, style: AppTheme.stencil(size: 19, color: p.ink)),
            actions: [
              IconButton(
                tooltip: 'Delete field',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, field),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Wrap(spacing: 8, children: [StampTag(label: field.crop, filled: true)]),
              if (photos.length >= 2) ...[
                const SizedBox(height: 8),
                const SectionLabel('Then and now'),
                Row(
                  children: [
                    Expanded(child: _Snapshot(entry: photos.first, label: 'First')),
                    const SizedBox(width: 10),
                    Expanded(child: _Snapshot(entry: photos.last, label: 'Latest')),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              const SectionLabel('To do'),
              if (reminders.isEmpty)
                Text('No reminders.', style: TextStyle(color: p.husk, fontSize: 13))
              else
                for (final r in reminders) ReminderRow(reminder: r),
              TextButton.icon(
                onPressed: () => showAddReminderSheet(
                  context,
                  fieldId: fieldId,
                  initialTitle: 'Check ${field.name}',
                ),
                icon: const Icon(Icons.alarm_add_outlined, size: 18),
                label: const Text('Add a reminder'),
              ),
              const SizedBox(height: 8),
              const SectionLabel('Checks'),
              if (entries.isEmpty)
                Text(
                  'No checks yet. Diagnose a leaf from this field, then tap '
                  '"Save to field".',
                  style: TextStyle(color: p.husk, fontSize: 13, height: 1.4),
                )
              else
                for (final entry in entries.reversed) _EntryRow(entry: entry),
            ],
          ),
        );
      },
    );
  }
}

class _Snapshot extends StatelessWidget {
  const _Snapshot({required this.entry, required this.label});
  final FieldEntry entry;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.file(FieldStore.instance.photoFile(entry)!,
                fit: BoxFit.cover, cacheWidth: 480),
          ),
        ),
        const SizedBox(height: 6),
        Text('${label.toUpperCase()} · ${formatDay(entry.timestamp)}',
            style: Theme.of(context).textTheme.labelMedium),
        if (entry.problem != null)
          Text(entry.problem!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.ink)),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});
  final FieldEntry entry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final photo = FieldStore.instance.photoFile(entry);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.hairline))),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: photo == null
                ? Container(
                    width: 52,
                    height: 52,
                    color: p.paper2,
                    child: Icon(Icons.edit_note, color: p.husk),
                  )
                : Image.file(photo,
                    width: 52, height: 52, fit: BoxFit.cover, cacheWidth: 156),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.problem ?? 'No clear diagnosis',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(formatDay(entry.timestamp),
                    style: TextStyle(fontSize: 11.5, color: p.husk)),
              ],
            ),
          ),
          if (entry.confidence != null)
            Text(entry.confidence!.toUpperCase(),
                style: AppTheme.stencil(size: 14, color: p.confidence(entry.confidence!))),
        ],
      ),
    );
  }
}
