import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma_embeddings/flutter_gemma_embeddings.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';

import 'app.dart';
import 'core/ai/device_capability.dart';
import 'core/fields/field_store.dart';
import 'core/reminders/reminder_service.dart';
import 'core/settings/app_settings.dart';
import 'core/sync/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the on-device inference engine (MediaPipe .task, backing the
  // Gemma3n E2B model) and embedding backend (Gecko/EmbeddingGemma, powering
  // knowledge retrieval). Both models ship as bundled native assets, so no
  // Hugging Face token is needed at runtime. Must be awaited: nothing else in
  // the plugin is safe to call until this completes.
  await FlutterGemma.initialize(
    inferenceEngines: [const MediaPipeEngine()],
    embeddingBackends: [const LiteRtEmbeddingBackend()],
  );

  // Opportunistic sync: fully disabled unless SYNC_ENDPOINT is configured.
  // Just registers a connectivity listener — no network access on its own.
  SyncService.instance.start();

  // Everything the farmer keeps lives on the phone — no account to fetch.
  await DeviceCapability.load();
  final settings = await AppSettings.load();
  await FieldStore.instance.load();
  await ReminderService.instance.load();

  runApp(CropSightApp(settings: settings));
}
