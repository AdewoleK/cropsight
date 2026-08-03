import 'package:flutter/material.dart';

import '../../core/ai/gemma_service.dart';
import '../../core/ai/model_catalog.dart';
import '../../core/rag/embedding_service.dart';
import '../../core/rag/rag_service.dart';

/// First-run screen: download the two on-device models once (the multimodal
/// model + the embedder), then build the knowledge-base index.
///
/// After this completes, the app never needs the internet again to diagnose.
class ModelDownloadScreen extends StatefulWidget {
  const ModelDownloadScreen({super.key, required this.onReady});
  final VoidCallback onReady;

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  int _percent = 0;
  String _step = '';
  bool _downloading = false;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _downloading = true;
      _error = null;
    });
    try {
      const token = String.fromEnvironment('HUGGINGFACE_TOKEN');

      setState(() => _step = 'Downloading AI model (${CropSightModel.approxSize})');
      await GemmaService.instance.installModel(
        hfToken: token.isNotEmpty ? token : null,
        onProgress: (p) => setState(() => _percent = p),
      );

      setState(() {
        _step = 'Downloading knowledge embedder';
        _percent = 0;
      });
      await EmbeddingService.instance.installEmbedder(
        onProgress: (p) => setState(() => _percent = p),
      );

      setState(() {
        _step = 'Indexing the field guide';
        _percent = 0;
      });
      await RagService.instance.ensureReady(
        onProgress: (p) => setState(() => _percent = p),
      );

      widget.onReady();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _downloading = false;
      });
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
              Text('Set up CropSight',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'We download everything once. After that, every diagnosis works '
                'fully offline.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (_downloading) ...[
                Text(_step,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _percent / 100),
                const SizedBox(height: 8),
                Text('$_percent%', textAlign: TextAlign.center),
              ] else
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.download),
                  label: const Text('Get started'),
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error)),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
