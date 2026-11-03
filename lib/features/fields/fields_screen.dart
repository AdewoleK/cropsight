import 'package:flutter/material.dart';

import '../../core/fields/field_store.dart';
import '../../core/reminders/reminder_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets.dart';
import '../settings/settings_screen.dart';
import 'field_detail_screen.dart';
import 'field_sheets.dart';

/// The season view: upcoming reminders, then every tracked field with its
/// latest check.
class FieldsScreen extends StatelessWidget {
  const FieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Fields'), style: AppTheme.stencil(size: 19, color: p.ink)),
        actions: const [SettingsButton(), SizedBox(width: 8)],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([FieldStore.instance, ReminderService.instance]),
        builder: (context, _) {
          final fields = FieldStore.instance.fields;
          final reminders = ReminderService.instance.open;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              if (reminders.isNotEmpty) ...[
                SectionLabel(context.tr('To do')),
                for (final r in reminders) ReminderRow(reminder: r),
                const SizedBox(height: 16),
              ],
              SectionLabel(context.tr('Your fields')),
              if (fields.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(Icons.grass_outlined, size: 32, color: p.husk),
                      const SizedBox(height: 10),
                      Text(
                        context.tr('Add a field to track it through the season. After a diagnosis, tap "Save to field" to keep the photo here.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.husk, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                )
              else
                for (final field in fields) _FieldTile(field: field),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => showAddFieldDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.tr('Add field')),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => showAddReminderSheet(context),
                icon: const Icon(Icons.alarm_add_outlined, size: 18),
                label: Text(context.tr('Add a reminder')),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.field});
  final FarmField field;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final store = FieldStore.instance;
    final latest = store.latestEntry(field.id);
    final checks = store.entriesFor(field.id).length;
    final photos = store.photoEntriesFor(field.id);
    final thumb = photos.isEmpty ? null : store.photoFile(photos.last);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FieldDetailScreen(fieldId: field.id)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.hairline))),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox.square(
                dimension: 56,
                child: thumb == null
                    ? ColoredBox(
                        color: p.paper2,
                        child: Icon(Icons.grass_outlined, color: p.husk),
                      )
                    : Image.file(thumb, fit: BoxFit.cover, cacheWidth: 168),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.name,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    latest == null
                        ? context.tr('{crop} · no checks yet', {'crop': context.tr(field.crop)})
                        : checks == 1
                            ? context.tr('{crop} · 1 check · last {day}', {
                                'crop': context.tr(field.crop),
                                'day': formatDay(latest.timestamp),
                              })
                            : context.tr('{crop} · {n} checks · last {day}', {
                                'crop': context.tr(field.crop),
                                'n': checks,
                                'day': formatDay(latest.timestamp),
                              }),
                    style: TextStyle(fontSize: 12, color: p.inkSoft),
                  ),
                  if (latest?.problem != null) ...[
                    const SizedBox(height: 2),
                    Text(context.tr(latest!.problem!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: latest.confidence == null
                                ? p.ink
                                : p.confidence(latest.confidence!))),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.husk),
          ],
        ),
      ),
    );
  }
}

/// One open reminder with a tick-off checkbox.
class ReminderRow extends StatelessWidget {
  const ReminderRow({super.key, required this.reminder});
  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final field = reminder.fieldId == null
        ? null
        : FieldStore.instance.field(reminder.fieldId!);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.hairline))),
      child: Row(
        children: [
          Checkbox(
            value: false,
            onChanged: (_) => ReminderService.instance.complete(reminder),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                Text(
                  [
                    if (field != null) field.name,
                    reminder.isOverdue
                        ? context.tr('overdue since {day}', {'day': formatDay(reminder.due)})
                        : formatDay(reminder.due),
                  ].join(' · '),
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: reminder.isOverdue ? FontWeight.w800 : FontWeight.w500,
                      color: reminder.isOverdue ? p.rust : p.husk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "today", "tomorrow", "yesterday" (in the app language), else e.g. "12 Oct".
String formatDay(DateTime t) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return tr('today');
  if (diff == 1) return tr('tomorrow');
  if (diff == -1) return tr('yesterday');
  return '${t.day} ${months[t.month - 1]}${t.year == now.year ? '' : ' ${t.year}'}';
}
