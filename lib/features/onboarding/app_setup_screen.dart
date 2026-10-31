import 'package:flutter/material.dart';

import '../../core/ai/gemma_service.dart';
import '../../core/rag/embedding_service.dart';
import '../../core/rag/rag_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets.dart';

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
  const AppSetupScreen({super.key, required this.onReady, this.lite = false});
  final VoidCallback onReady;

  /// Lite mode skips installing the multi-GB photo model entirely — it can't
  /// run on this phone, and copying it would waste ~3GB of storage.
  final bool lite;

  @override
  State<AppSetupScreen> createState() => _AppSetupScreenState();
}

class _AppSetupScreenState extends State<AppSetupScreen> {
  List<String> get _steps => [
        widget.lite
            ? 'Photo AI skipped — Lite mode for this phone'
            : 'Loading on-device model',
        'Loading knowledge embedder',
        'Indexing the field guide',
      ];

  int _stepIndex = 0;
  int? _percent;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// setState that's a no-op once this screen has been replaced — setup
  /// keeps running in the background if the gate swaps it out (e.g. the
  /// diagnosis mode changes mid-setup).
  void _update(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _start() async {
    try {
      _update(() {
        _stepIndex = 0;
        _percent = 0;
        _error = null;
      });
      if (!widget.lite) {
        await GemmaService.instance.installModel(
          onProgress: (p) => _update(() => _percent = p),
        );
      }

      _update(() {
        _stepIndex = 1;
        _percent = 0;
      });
      await EmbeddingService.instance.installEmbedder(
        onProgress: (p) => _update(() => _percent = p),
      );

      _update(() {
        _stepIndex = 2;
        _percent = 0;
      });
      await RagService.instance.ensureReady(
        onProgress: (p) => _update(() => _percent = p),
      );

      if (mounted) widget.onReady();
    } catch (e) {
      _update(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              const Center(child: CropSightMark(size: 78)),
              const SizedBox(height: 20),
              Text('CropSight',
                  textAlign: TextAlign.center,
                  style: AppTheme.stencil(size: 30, color: p.ink)),
              const SizedBox(height: 10),
              Text(
                'One-time setup, fully on-device — no signal needed\nafter this.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.5, color: p.inkSoft),
              ),
              const Spacer(flex: 2),
              if (_error == null) ...[
                _Checklist(steps: _steps, stepIndex: _stepIndex, percent: _percent),
              ] else
                _ErrorPanel(error: _error!, onRetry: _start),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.steps, required this.stepIndex, required this.percent});
  final List<String> steps;
  final int stepIndex;
  final int? percent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                _StatusDot(state: i < stepIndex
                    ? TrackState.done
                    : i == stepIndex
                        ? TrackState.active
                        : TrackState.pending),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: i <= stepIndex ? p.ink : p.husk,
                    ),
                  ),
                ),
                if (i == stepIndex && percent != null)
                  Text('$percent%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: p.marigold,
                          fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent != null ? percent! / 100 : null,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.state});
  final TrackState state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: 20,
      height: 20,
      child: switch (state) {
        TrackState.done => Container(
            decoration: BoxDecoration(color: p.fern, shape: BoxShape.circle),
            child: Icon(Icons.check, size: 13, color: p.onFern),
          ),
        TrackState.active => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: p.marigold, width: 2.4),
            ),
          ),
        TrackState.pending => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: p.hairline, width: 2),
            ),
          ),
      },
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.paper2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.brick.withValues(alpha: 0.4)),
          ),
          child: Text(error, style: TextStyle(fontSize: 12.5, color: p.brick)),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
