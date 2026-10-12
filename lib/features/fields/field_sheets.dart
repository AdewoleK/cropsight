import 'package:flutter/material.dart';

import '../../core/fields/field_store.dart';
import '../../core/reminders/reminder_service.dart';
import '../../theme/widgets.dart';

/// Asks for a new field's name and crop. Returns the created field, or null
/// if cancelled.
Future<FarmField?> showAddFieldDialog(BuildContext context, {String? crop}) async {
  final name = TextEditingController();
  final cropCtl = TextEditingController(text: crop);
  final created = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New field'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Name', hintText: 'e.g. Behind the house'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: cropCtl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Crop', hintText: 'e.g. Maize'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
      ],
    ),
  );
  if (created != true || name.text.trim().isEmpty) return null;
  return FieldStore.instance.addField(
    name: name.text,
    crop: cropCtl.text.trim().isEmpty ? 'Unknown crop' : cropCtl.text,
  );
}

/// Lets the farmer pick which field a diagnosis belongs to (or make a new
/// one). Returns the chosen field, or null if dismissed.
Future<FarmField?> showPickFieldSheet(BuildContext context, {String? crop}) {
  return showModalBottomSheet<FarmField>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final fields = FieldStore.instance.fields;
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text('Save to which field?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final field in fields)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.grass_outlined),
                title: Text(field.name),
                subtitle: Text(field.crop),
                onTap: () => Navigator.pop(context, field),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add),
              title: const Text('New field'),
              onTap: () async {
                final field = await showAddFieldDialog(context, crop: crop);
                if (context.mounted && field != null) Navigator.pop(context, field);
              },
            ),
          ],
        ),
      );
    },
  );
}

/// Sets a reminder a chosen number of days from now. Returns true if one
/// was created.
Future<bool> showAddReminderSheet(
  BuildContext context, {
  String? fieldId,
  String initialTitle = '',
}) async {
  final title = TextEditingController(text: initialTitle);
  var days = 7;
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Remind me', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'What to do', hintText: 'e.g. Re-check the leaves'),
            ),
            const SectionLabel('When'),
            Wrap(
              spacing: 8,
              children: [
                for (final d in const [1, 3, 7, 14, 30])
                  ChoiceChip(
                    label: Text(d == 1 ? 'Tomorrow' : 'In $d days'),
                    selected: days == d,
                    onSelected: (_) => setState(() => days = d),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Set reminder'),
            ),
          ],
        ),
      ),
    ),
  );
  if (created != true) return false;
  final now = DateTime.now();
  // 8am on the chosen day — a time a farmer is likely heading out.
  final due = DateTime(now.year, now.month, now.day + days, 8);
  await ReminderService.instance.add(
    title: title.text.trim().isEmpty ? 'Check your field' : title.text,
    due: due,
    fieldId: fieldId,
  );
  return true;
}
