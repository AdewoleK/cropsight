// Drives the real app through every screen for the marketing/redesign
// screenshot set. Not a correctness test: it prints `SNAP:<name>` at each
// screen and holds still while tool/capture_screenshots.sh grabs the
// simulator frame (with its status bar) via `xcrun simctl io screenshot`.
//
// Run via:  tool/capture_screenshots.sh <simulator-udid>
// It seeds demo fields/reminders, runs one real photo diagnosis, then
// removes the seeded data and restores settings.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cropsight/app.dart';
import 'package:cropsight/core/ai/device_capability.dart';
import 'package:cropsight/core/fields/field_store.dart';
import 'package:cropsight/core/rag/rag_service.dart';
import 'package:cropsight/core/reminders/reminder_service.dart';
import 'package:cropsight/core/settings/app_settings.dart';
import 'package:cropsight/features/diagnosis/diagnosis_controller.dart';
import 'package:cropsight/features/onboarding/app_setup_screen.dart';
import 'package:cropsight/theme/app_theme.dart';
import 'package:cropsight/theme/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma_embeddings/flutter_gemma_embeddings.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

const _photosDir = String.fromEnvironment('PHOTOS_DIR');

/// Pumps frames in real time. pumpAndSettle can't be used: progress
/// indicators and the scan line animate forever.
Future<void> wait(WidgetTester t, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 50));
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

Future<void> snap(WidgetTester t, String name) async {
  await wait(t, 900);
  // ignore: avoid_print
  print('SNAP:$name');
  await wait(t, 2200); // host captures during this window
}

Future<void> tab(WidgetTester t, String label) async {
  await t.tap(find.descendant(
      of: find.byType(CropSightBottomNav), matching: find.text(label)));
  await wait(t, 1200);
}

Future<void> scrollBy(WidgetTester t, double dy) async {
  await t.drag(find.byType(Scrollable).hitTestable().first, Offset(0, -dy));
  await wait(t, 900);
}

Future<void> back(WidgetTester t) async {
  await t.pageBack();
  await wait(t, 900);
}

Uint8List photo(String name) => File('$_photosDir/$name').readAsBytesSync();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture every screen', timeout: const Timeout(Duration(minutes: 40)),
      (t) async {
    await FlutterGemma.initialize(
      inferenceEngines: [const MediaPipeEngine()],
      embeddingBackends: [const LiteRtEmbeddingBackend()],
    );
    await DeviceCapability.load();
    final settings = await AppSettings.load()
      ..themeMode = ThemeMode.light
      ..language = AnswerLanguage.english
      ..diagnosisMode = DiagnosisMode.photo;
    final fields = FieldStore.instance;
    final reminders = ReminderService.instance..askForPermission = false;
    await fields.load();
    await reminders.load();

    // ── Seed demo fields, history and reminders ─────────────────────────
    // (clearing leftovers from an aborted earlier run first)
    for (final f in fields.fields.where(
        (f) => f.name == 'River plot' || f.name == 'Tomato garden')) {
      await reminders.deleteForField(f.id);
      await fields.deleteField(f.id);
    }
    final now = DateTime.now();
    final maize = await fields.addField(name: 'River plot', crop: 'Maize');
    final tomato = await fields.addField(name: 'Tomato garden', crop: 'Tomato');
    await fields.addEntry(
      fieldId: maize.id,
      photo: photo('maize_nclb.jpg'),
      problem: 'Northern corn leaf blight',
      confidence: 'medium',
      timestamp: now.subtract(const Duration(days: 9)),
    );
    await fields.addEntry(
      fieldId: tomato.id,
      photo: photo('tomato_early_blight_2.jpg'),
      problem: 'Early blight',
      confidence: 'medium',
      timestamp: now.subtract(const Duration(days: 14)),
    );
    await reminders.add(
      title: 'Re-check maize for leaf blight',
      due: now.add(const Duration(days: 2)),
      fieldId: maize.id,
    );
    await reminders.add(
      title: 'Remove lower tomato leaves',
      due: now.add(const Duration(days: 1)),
      fieldId: tomato.id,
    );

    addTearDown(() async {
      for (final f in [maize, tomato]) {
        await reminders.deleteForField(f.id);
        await fields.deleteField(f.id);
      }
      settings
        ..themeMode = ThemeMode.system
        ..diagnosisMode = DiagnosisMode.auto;
    });

    // ── First-launch setup ──────────────────────────────────────────────
    final setupDone = Completer<void>();
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      home: AppSetupScreen(onReady: setupDone.complete),
    ));
    await wait(t, 300);
    // ignore: avoid_print
    print('SNAP:01-setup');
    await wait(t, 2500);
    while (!setupDone.isCompleted) {
      await wait(t, 500);
    }

    // ── Photo diagnosis ─────────────────────────────────────────────────
    await t.pumpWidget(CropSightApp(settings: settings));
    await wait(t, 4000);
    await snap(t, '02-diagnose-home');

    final controller = Provider.of<DiagnosisController>(
        t.element(find.byType(ScanFrame)),
        listen: false);

    final leaf = photo('tomato_early_blight.jpg');
    final blurred = img.encodeJpg(
        img.gaussianBlur(img.decodeImage(leaf)!, radius: 14), quality: 85);
    await controller.setImage(blurred);
    await snap(t, '03-photo-check-warning');

    await controller.setImage(leaf);
    await snap(t, '04-photo-ready');

    final run = controller.run();
    await wait(t, 2500);
    await snap(t, '05-diagnosing');
    final started = DateTime.now();
    var sawAnswering = false;
    while (controller.status != DiagnosisStatus.done &&
        controller.status != DiagnosisStatus.error) {
      if (!sawAnswering &&
          controller.status == DiagnosisStatus.answering &&
          controller.answer.length > 40) {
        sawAnswering = true;
        await snap(t, '06-diagnosing-writing');
      }
      await wait(t, 1000);
    }
    await run;
    // ignore: avoid_print
    print('DIAGNOSIS ${controller.status.name} after '
        '${DateTime.now().difference(started).inSeconds}s\n'
        'DESCRIPTION: ${controller.description}\nANSWER:\n${controller.answer}\n'
        'ERROR: ${controller.error}');

    // Only real model output goes in the screenshot set — if the photo
    // pipeline can't run on this device, its result screens are skipped.
    final photoWorked = controller.status == DiagnosisStatus.done;
    if (photoWorked) {
      await scrollBy(t, 230);
      await snap(t, '07-result');
      await scrollBy(t, 420);
      await snap(t, '08-result-steps');
      await scrollBy(t, 2000);
      await snap(t, '09-result-safety-actions');
      settings.themeMode = ThemeMode.dark;
      await wait(t, 800);
      await snap(t, '30-dark-result');
      settings.themeMode = ThemeMode.light;
      await wait(t, 800);
      await t.tap(find.text('Save'));
      await wait(t, 1200);
      await t.tap(find.text('Tomato garden'));
      await wait(t, 1500);
    } else {
      controller.reset();
      await wait(t, 600);
    }

    // ── Fields ──────────────────────────────────────────────────────────
    await tab(t, 'Fields');
    await snap(t, '12-fields');
    await t.tap(find.text('River plot').hitTestable());
    await wait(t, 1200);
    await snap(t, '13-field-detail');
    await t.tap(find.text('Add a reminder').hitTestable());
    await wait(t, 1200);
    await snap(t, '14-set-reminder');
    await t.tap(find.text('In 3 days'));
    await t.tap(find.text('Set reminder'));
    await wait(t, 1500);
    await scrollBy(t, 500);
    await snap(t, '15-field-history');
    await back(t);

    // ── Library ─────────────────────────────────────────────────────────
    await tab(t, 'Library');
    await snap(t, '16-library');
    await t.tap(find.text('Pest').hitTestable());
    await wait(t, 900);
    await snap(t, '17-library-pests');
    await t.tap(find.text('Pest').hitTestable());
    await t.enterText(find.byType(TextField).hitTestable(), 'armyworm');
    await wait(t, 900);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await wait(t, 900);
    await t.tap(find.text('Fall armyworm').hitTestable());
    await wait(t, 1200);
    await snap(t, '18-card-detail');
    await scrollBy(t, 500);
    await snap(t, '19-card-detail-safety');
    await back(t);
    await t.enterText(find.byType(TextField).hitTestable(), '');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await wait(t, 600);

    // ── Settings ────────────────────────────────────────────────────────
    await t.tap(find.byTooltip('Settings').hitTestable().first);
    await wait(t, 1200);
    await snap(t, '21-settings');
    await scrollBy(t, 600);
    await snap(t, '22-settings-languages');
    await back(t);

    // ── Lite mode ───────────────────────────────────────────────────────
    settings.liteReady = false;
    settings.diagnosisMode = DiagnosisMode.lite;
    await wait(t, 700);
    await snap(t, '23-lite-setup');
    for (var i = 0; i < 120 && find.text('What do you see?').evaluate().isEmpty; i++) {
      await wait(t, 500);
    }
    await tab(t, 'Diagnose');
    await snap(t, '24-lite-home');

    // Retrieval sanity check: print the top matches for a few descriptions.
    const checks = {
      'Maize': 'Maize plant. Problem on the leaves. holes, ragged chewed leaves; '
          'insects, caterpillars or eggs on the plant.',
      'Cassava': 'Cassava plant. Problem on the leaves. yellow and green mosaic or '
          'mottled pattern; curled, twisted or distorted leaves.',
      'Tomato': 'Tomato plant. Problem on the leaves. brown spots with rings, '
          'target spots; leaves turn yellow.',
      'Banana': 'Banana plant. Problem on the fruit, pods or cobs, whole plant. '
          'plant wilts and droops; ooze, gum or sticky liquid.',
    };
    for (final e in checks.entries) {
      final hits =
          await RagService.instance.retrieveForCrop(e.value, crop: e.key, k: 3);
      // ignore: avoid_print
      print('LITE ${e.key}: ${hits.map((h) => '${h.card.title} '
          '${(h.score * 100).round()}%').join(' | ')}');
    }

    for (final chip in ['Maize', 'Leaves', 'Holes / chewed', 'Insects seen']) {
      await t.ensureVisible(find.text(chip).hitTestable().first);
      await t.tap(find.text(chip).hitTestable().first);
      await wait(t, 300);
    }
    await scrollBy(t, 250);
    await snap(t, '25-lite-describe');
    await t.ensureVisible(find.text('Find matches'));
    await t.tap(find.text('Find matches'));
    await wait(t, 4000);
    for (var i = 0; i < 8 && find.text('This looks right').evaluate().isEmpty; i++) {
      await scrollBy(t, 350);
    }
    // ignore: avoid_print
    print('LITE UI: matches shown=${find.text('This looks right').evaluate().length} '
        'header=${find.text('POSSIBLE MATCHES').evaluate().length}');
    // Lazily built list: step back until the header exists, then pin it to
    // the top of the viewport.
    for (var i = 0; i < 6 && find.text('POSSIBLE MATCHES').evaluate().isEmpty; i++) {
      await scrollBy(t, -100);
    }
    await Scrollable.ensureVisible(t.element(find.text('POSSIBLE MATCHES')));
    await wait(t, 600);
    await snap(t, '26-lite-matches');
    await t.ensureVisible(find.text('This looks right').first);
    await wait(t, 400);
    await t.tap(find.text('This looks right').first);
    await wait(t, 1200);
    await Scrollable.ensureVisible(t.element(find.text('WHAT TO DO')), alignment: 0.3);
    await wait(t, 600);
    await snap(t, '27-lite-chosen');
    await scrollBy(t, 2000);
    await snap(t, '28-lite-actions');
    await t.tap(find.text('Save').hitTestable());
    await wait(t, 1200);
    await snap(t, '29-save-to-field');
    await t.tap(find.text('River plot').hitTestable());
    await wait(t, 1500);

    // ── Log (after the Lite diagnosis, so it has an entry) ──────────────
    await wait(t, 4000); // let the "Saved to" snackbar clear
    await tab(t, 'Log');
    await snap(t, '20-log');

    // ── Dark mode ───────────────────────────────────────────────────────
    settings.diagnosisMode = DiagnosisMode.photo;
    settings.themeMode = ThemeMode.dark;
    await wait(t, 3000);
    await tab(t, 'Diagnose');
    await snap(t, '31-dark-diagnose-home');
    await tab(t, 'Fields');
    await snap(t, '32-dark-fields');
    await tab(t, 'Library');
    await snap(t, '33-dark-library');

    await tab(t, 'Fields');
    await t.tap(find.text('River plot').hitTestable());
    await wait(t, 1200);
    await snap(t, '34-dark-field-detail');
    await back(t);
    // ignore: avoid_print
    print('SNAP:DONE');
  });
}
