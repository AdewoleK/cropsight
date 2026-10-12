import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/ai/photo_quality.dart';
import '../../core/settings/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets.dart';
import '../settings/settings_screen.dart';
import 'diagnosis_controller.dart';
import 'diagnosis_result_view.dart';
import 'lite_diagnosis_screen.dart';
import 'result_actions.dart';

/// The core screen: photograph a leaf, get an offline, grounded diagnosis —
/// or, on phones without the memory for the photo model, Lite mode's
/// describe-the-symptoms flow.
class DiagnosisScreen extends StatelessWidget {
  const DiagnosisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.watch<AppSettings>().useLiteMode) {
      return const LiteDiagnosisScreen();
    }
    return ChangeNotifierProvider(
      create: (context) => DiagnosisController(settings: context.read<AppSettings>()),
      child: const _DiagnosisView(),
    );
  }
}

class _DiagnosisView extends StatelessWidget {
  const _DiagnosisView();

  /// Picks a photo and shows it for confirmation — does not start the
  /// diagnosis yet, that happens when the user taps "Diagnose".
  Future<void> _pick(BuildContext context, ImageSource source) async {
    final controller = context.read<DiagnosisController>();
    final picker = ImagePicker();
    // 1600px is plenty for the model and the quality check, and keeps a
    // 12MP photo from costing ~50MB of RAM on a phone that's already tight.
    final file = await picker.pickImage(
        source: source, imageQuality: 90, maxWidth: 1600, maxHeight: 1600);
    if (file == null) return;
    controller.setImage(await file.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DiagnosisController>();
    final p = context.palette;
    final busy = controller.status == DiagnosisStatus.looking ||
        controller.status == DiagnosisStatus.retrieving ||
        controller.status == DiagnosisStatus.answering;
    // Picked but not yet confirmed — awaiting "Diagnose" or "Retake".
    final awaitingConfirm =
        controller.imageBytes != null && controller.status == DiagnosisStatus.idle;
    // A diagnosis has been run (successfully or not) — offer a fresh start.
    final canStartOver = !awaitingConfirm &&
        controller.status != DiagnosisStatus.idle &&
        !busy;

    return Scaffold(
      appBar: AppBar(
        title: Text('CropSight', style: AppTheme.stencil(size: 19, color: p.ink)),
        actions: const [
          OfflinePill(),
          SettingsButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 260,
                child: ScanFrame(
                  scanning: busy,
                  child: controller.imageBytes != null
                      ? Image.memory(controller.imageBytes!, fit: BoxFit.cover)
                      : const _ViewfinderHint(),
                ),
              ),
              const SizedBox(height: 16),
              if (awaitingConfirm) ...[
                _PhotoCheck(issues: controller.photoIssues),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.reset,
                        icon: const Icon(Icons.replay, size: 18),
                        label: const Text('Retake'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: controller.run,
                        icon: const Icon(Icons.center_focus_strong, size: 18),
                        label: Text(controller.photoIssues?.isNotEmpty == true
                            ? 'Use anyway'
                            : 'Diagnose'),
                      ),
                    ),
                  ],
                ),
              ] else if (canStartOver)
                OutlinedButton.icon(
                  onPressed: controller.reset,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: const Text('New diagnosis'),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            busy ? null : () => _pick(context, ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Gallery'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            busy ? null : () => _pick(context, ImageSource.camera),
                        icon: const Icon(Icons.center_focus_strong, size: 18),
                        label: const Text('Scan leaf'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              _ResultPanel(controller: controller, busy: busy),
              if (controller.status == DiagnosisStatus.done) ...[
                const SizedBox(height: 12),
                ResultActions(
                  summary: controller.summary,
                  savedToFieldId: controller.savedToFieldId,
                  onSaved: controller.markSaved,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the outcome of [PhotoQuality.check] while a picked photo awaits
/// confirmation: nothing while checking or when fine, else what's wrong and
/// how to fix it.
class _PhotoCheck extends StatelessWidget {
  const _PhotoCheck({required this.issues});
  final List<PhotoIssue>? issues;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final found = issues;
    if (found == null || found.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.paper2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.rust, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This photo may give a poor answer',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final issue in found)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: '${issue.title}. ',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: issue.fix),
                ]),
                style: TextStyle(fontSize: 13, height: 1.35, color: p.ink),
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewfinderHint extends StatelessWidget {
  const _ViewfinderHint();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.paper2, p.paper, p.paper2],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('AIM AT ONE LEAF',
                style: AppTheme.stencil(size: 18, color: p.ink)),
            const SizedBox(height: 6),
            Text('Fill the brackets. Natural light works best.',
                style: TextStyle(fontSize: 12, color: p.inkSoft)),
          ],
        ),
      ),
    );
  }
}

/// Maps the diagnosis pipeline onto the three-stage Look / Match / Write
/// status track shown while a diagnosis is running.
List<(String, TrackState)> _stagesFor(DiagnosisStatus status) {
  TrackState stateOf(int stage, int current) => stage < current
      ? TrackState.done
      : stage == current
          ? TrackState.active
          : TrackState.pending;
  final current = switch (status) {
    DiagnosisStatus.looking => 0,
    DiagnosisStatus.retrieving => 1,
    DiagnosisStatus.answering => 2,
    _ => 3,
  };
  return [
    ('Look', stateOf(0, current)),
    ('Match', stateOf(1, current)),
    ('Write', stateOf(2, current)),
  ];
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.controller, required this.busy});
  final DiagnosisController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    if (controller.status == DiagnosisStatus.idle) {
      return const SizedBox.shrink();
    }
    if (controller.status == DiagnosisStatus.error) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.paper2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.brick.withValues(alpha: 0.4)),
        ),
        child: Text('Something went wrong:\n${controller.error}',
            style: TextStyle(color: p.brick, fontSize: 13)),
      );
    }

    if (busy) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.paper2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(controller.statusLabel,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            StatusTrack(stages: _stagesFor(controller.status)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.paper2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.hairline),
      ),
      child: DiagnosisResultView(
        answer: controller.answer,
        structured: controller.structured,
        sources: controller.sources,
      ),
    );
  }
}
