import 'package:flutter/material.dart';

import '../../core/ai/gemma_service.dart';
import '../../core/rag/embedding_service.dart';
import '../../core/rag/rag_service.dart';

/// First-run screen: install the two bundled on-device models (the
/// multimodal model + the embedder), then build the knowledge-base index.
///
/// Everything here is local — the models ship as native assets, so this runs
/// automatically on first launch with no network access and no user
/// confirmation needed. The model/embedder install steps are effectively
/// instant on later launches, but on Android the very first run copies the
/// model out of the APK into app storage, which takes a real, one-time
/// stretch of wall-clock time for a multi-GB file.
class AppSetupScreen extends StatefulWidget {
  const AppSetupScreen({super.key, required this.onReady});
  final VoidCallback onReady;

  @override
  State<AppSetupScreen> createState() => _AppSetupScreenState();
}

class _AppSetupScreenState extends State<AppSetupScreen> {
  String _step = 'Preparing on-device AI';
  int? _percent;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      setState(() {
        _step = 'Loading on-device model';
        _percent = null;
      });
      await GemmaService.instance.installModel();

      setState(() {
        _step = 'Loading knowledge embedder';
        _percent = null;
      });
      await EmbeddingService.instance.installEmbedder();

      setState(() {
        _step = 'Indexing the field guide';
        _percent = 0;
      });
      await RagService.instance.ensureReady(
        onProgress: (p) => setState(() => _percent = p),
      );

      widget.onReady();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.eco, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Setting up CropSight',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'One-time setup, fully on-device — no internet needed. This '
                'may take a minute on first launch.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (_error == null) ...[
                Text(_step,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                if (_percent != null) ...[
                  LinearProgressIndicator(value: _percent! / 100),
                  const SizedBox(height: 8),
                  Text('$_percent%', textAlign: TextAlign.center),
                ] else
                  const LinearProgressIndicator(),
              ] else ...[
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
