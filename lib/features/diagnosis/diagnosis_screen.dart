import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../sync/sync_status_screen.dart';
import 'diagnosis_controller.dart';

/// The core screen: photograph a leaf, get an offline, grounded diagnosis.
class DiagnosisScreen extends StatelessWidget {
  const DiagnosisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiagnosisController(),
      child: const _DiagnosisView(),
    );
  }
}

class _DiagnosisView extends StatelessWidget {
  const _DiagnosisView();

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final controller = context.read<DiagnosisController>();
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;
    controller.setImage(await file.readAsBytes());
    await controller.run();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DiagnosisController>();
    final theme = Theme.of(context);
    final busy = controller.status == DiagnosisStatus.looking ||
        controller.status == DiagnosisStatus.retrieving ||
        controller.status == DiagnosisStatus.answering;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CropSight'),
        actions: [
          IconButton(
            tooltip: 'Offline — no internet needed',
            icon: const Icon(Icons.wifi_off),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This diagnosis runs entirely on your phone.'),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sync status',
            icon: const Icon(Icons.cloud_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SyncStatusScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(controller.imageBytes!,
                      height: 240, fit: BoxFit.cover),
                )
              else
                _EmptyHint(theme: theme),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          busy ? null : () => _pick(context, ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => _pick(context, ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ResultPanel(controller: controller, busy: busy),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_outlined, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Photograph a leaf to begin',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Works with no internet', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.controller, required this.busy});
  final DiagnosisController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (controller.status == DiagnosisStatus.idle) {
      return const SizedBox.shrink();
    }
    if (controller.status == DiagnosisStatus.error) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Something went wrong:\n${controller.error}',
              style: TextStyle(color: theme.colorScheme.error)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (busy)
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Icon(Icons.check_circle,
                          size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(controller.statusLabel,
                        style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  controller.answer.isEmpty
                      ? (busy ? '…' : '')
                      : controller.answer,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        if (controller.sources.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Sources', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          ...controller.sources.map(
            (s) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined, size: 20),
              title: Text(s.card.label),
              trailing: Text('${(s.score * 100).round()}%',
                  style: theme.textTheme.bodySmall),
            ),
          ),
        ],
      ],
    );
  }
}
