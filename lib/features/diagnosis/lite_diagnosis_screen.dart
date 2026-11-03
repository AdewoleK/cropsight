import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/rag/knowledge_base.dart';
import '../../core/rag/local_vector_index.dart';
import '../../core/rag/rag_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/sync/diagnosis_result.dart';
import '../../core/sync/sync_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets.dart';
import '../library/card_detail_screen.dart';
import '../settings/settings_screen.dart';
import 'result_actions.dart';

/// Lite mode for low-memory phones: the farmer taps what they see, and the
/// small on-device embedder matches that description against the field
/// guide. No photo model is loaded, so this works where Gemma3n vision
/// can't (see `DeviceCapability`).
class LiteDiagnosisScreen extends StatefulWidget {
  const LiteDiagnosisScreen({super.key});

  @override
  State<LiteDiagnosisScreen> createState() => _LiteDiagnosisScreenState();
}

/// Plant parts, as (chip label, phrase used in the matching query).
const _parts = [
  ('Leaves', 'leaves'),
  ('Stem', 'stem'),
  ('Fruit / pod / cob', 'fruit, pods or cobs'),
  ('Roots / tuber', 'roots or tubers'),
  ('Whole plant', 'whole plant'),
];

/// Symptoms, as (chip label, phrase). Phrases use the same plain visual
/// words as the cards' symptom text, which is what they're matched against.
const _symptoms = [
  ('Yellowing', 'leaves turn yellow'),
  ('Spots', 'spots or lesions'),
  ('Rings in spots', 'brown spots with rings, target spots'),
  ('Mosaic / mottled', 'yellow and green mosaic or mottled pattern'),
  ('Streaks', 'streaks or stripes along the veins'),
  ('Holes / chewed', 'holes, ragged chewed leaves'),
  ('Wilting', 'plant wilts and droops'),
  ('Curling', 'curled, twisted or distorted leaves'),
  ('Rot', 'soft rot, rotting'),
  ('Mould / powder', 'white or grey mould or powder'),
  ('Rust pustules', 'orange or rust-coloured powdery pustules'),
  ('Dry edges', 'dry, brown, burnt leaf edges'),
  ('Stunted', 'stunted, small plants'),
  ('Insects seen', 'insects, caterpillars or eggs on the plant'),
  ('Ooze / gum', 'ooze, gum or sticky liquid'),
  ('Root swellings', 'swellings, galls or knots on roots'),
];

class _LiteDiagnosisScreenState extends State<LiteDiagnosisScreen> {
  static final List<String> _crops = {
    for (final c in KnowledgeBase.cards)
      if (c.crop != 'Many crops') c.crop,
  }.toList()
    ..sort();

  String? _crop;
  final Set<int> _partIdx = {};
  final Set<int> _symptomIdx = {};
  final TextEditingController _note = TextEditingController();
  Uint8List? _photo;

  bool _searching = false;
  String? _error;
  String _query = '';

  /// One report per search: choosing a different match replaces it rather
  /// than reporting a second problem.
  String _reportId = '';
  List<RetrievedCard>? _matches;
  RetrievedCard? _chosen;
  String? _savedToFieldId;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _buildQuery() {
    final parts = _partIdx.map((i) => _parts[i].$2).join(', ');
    final symptoms = _symptomIdx.map((i) => _symptoms[i].$2).join('; ');
    return [
      if (_crop != null) '$_crop plant.',
      if (parts.isNotEmpty) 'Problem on the $parts.',
      if (symptoms.isNotEmpty) '$symptoms.',
      _note.text.trim(),
    ].where((s) => s.isNotEmpty).join(' ');
  }

  Future<void> _find() async {
    FocusScope.of(context).unfocus();
    final query = _buildQuery();
    setState(() {
      _searching = true;
      _error = null;
      _matches = null;
      _chosen = null;
      _savedToFieldId = null;
      _query = query;
      _reportId = DateTime.now().millisecondsSinceEpoch.toString();
    });
    try {
      final matches =
          await RagService.instance.retrieveForCrop(query, crop: _crop, k: 5);
      if (mounted) setState(() => _matches = matches);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _searching = false);
  }

  void _choose(RetrievedCard match) {
    setState(() => _chosen = match);
    unawaited(SyncService.instance.enqueueResult(DiagnosisResult(
      id: _reportId,
      timestamp: DateTime.now(),
      description: _query,
      answer: 'Lite match: ${match.card.label}',
      citedCards: [CitedCard.fromRetrieved(match)],
      source: DiagnosisSource.lite,
    )));
  }

  void _reset() {
    _note.clear();
    setState(() {
      _crop = null;
      _partIdx.clear();
      _symptomIdx.clear();
      _photo = null;
      _matches = null;
      _chosen = null;
      _savedToFieldId = null;
      _error = null;
    });
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.camera, imageQuality: 85, maxWidth: 1600, maxHeight: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _photo = bytes);
  }

  ResultSummary _summaryFor(RetrievedCard match) {
    final card = match.card;
    final share = StringBuffer()
      ..writeln(tr('Crop: {crop}', {'crop': tr(_crop ?? card.crop)}))
      ..writeln(tr('Possible problem: {problem} ({percent}% match)', {
        'problem': tr(card.title),
        'percent': (match.score * 100).round(),
      }))
      ..writeln(tr('What I saw: {description}', {'description': _query}))
      ..writeln(tr('What to do: {steps}', {'steps': card.management}));
    if (card.safety != null) {
      share.writeln(tr('Safety: {safety}', {'safety': card.safety}));
    }
    share.write('\n$shareFooter');
    return ResultSummary(
      spokenText: '${card.title}. What to do: ${card.management}',
      shareText: share.toString(),
      // Cards are English; Lite mode has no model to translate them.
      language: AnswerLanguage.english,
      photo: _photo,
      crop: _crop ?? card.crop,
      problem: card.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final canSearch = _symptomIdx.isNotEmpty || _note.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('CropSight', style: AppTheme.stencil(size: 19, color: p.ink)),
        actions: [
          OfflinePill(label: context.tr('LITE MODE'), dotColor: p.marigold),
          const SettingsButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text(context.tr('What do you see?'), style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              context.tr(
                  'Tap what matches your plant. CropSight compares it with {n} field-guide entries — on this phone, no internet.',
                  {'n': KnowledgeBase.cards.length}),
              style: text.bodyMedium?.copyWith(color: p.inkSoft),
            ),
            SectionLabel(context.tr('1 · Crop')),
            _ChipWrap(
              labels: [for (final c in _crops) context.tr(c)],
              isSelected: (i) => _crop == _crops[i],
              onTap: (i) => setState(() => _crop = _crop == _crops[i] ? null : _crops[i]),
            ),
            const SizedBox(height: 8),
            SectionLabel(context.tr('2 · Where on the plant')),
            _ChipWrap(
              labels: [for (final p in _parts) context.tr(p.$1)],
              isSelected: _partIdx.contains,
              onTap: (i) => setState(
                  () => _partIdx.contains(i) ? _partIdx.remove(i) : _partIdx.add(i)),
            ),
            const SizedBox(height: 8),
            SectionLabel(context.tr('3 · What it looks like')),
            _ChipWrap(
              labels: [for (final s in _symptoms) context.tr(s.$1)],
              isSelected: _symptomIdx.contains,
              onTap: (i) => setState(() =>
                  _symptomIdx.contains(i) ? _symptomIdx.remove(i) : _symptomIdx.add(i)),
            ),
            const SizedBox(height: 8),
            SectionLabel(context.tr('4 · Anything else? (optional)')),
            TextField(
              controller: _note,
              onChanged: (_) => setState(() {}),
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: context.tr('e.g. started after heavy rain, spreading fast'),
                filled: true,
                fillColor: p.paper2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_photo != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_photo!, width: 44, height: 44, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(_photo == null
                        ? context.tr('Add a photo for your records')
                        : context.tr('Photo kept for your records')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_matches != null) ...[
                  Expanded(
                    child: OutlinedButton(onPressed: _reset, child: Text(context.tr('Start over'))),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canSearch && !_searching ? _find : null,
                    icon: _searching
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: p.onRust),
                          )
                        : const Icon(Icons.search, size: 18),
                    label: Text(context.tr('Find matches')),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(context.tr('Something went wrong:\n{error}', {'error': _error}),
                  style: TextStyle(color: p.brick, fontSize: 13)),
            ],
            if (_matches != null) ...[
              const SizedBox(height: 8),
              SectionLabel(context.tr('Possible matches')),
              Text(
                context.tr(
                    'Compare each with your plant and pick the one that fits. Lite mode matches your description — it cannot see the photo.'),
                style: text.bodySmall,
              ),
              const SizedBox(height: 8),
              const EnglishOnlyNote(),
              if (_matches!.isEmpty)
                Text(context.tr('No matches. Try choosing fewer or different symptoms.'),
                    style: TextStyle(color: p.husk))
              else
                for (final m in _matches!)
                  _MatchCard(
                    match: m,
                    chosen: identical(_chosen, m),
                    dimmed: _chosen != null && !identical(_chosen, m),
                    onChoose: () => _choose(m),
                  ),
            ],
            if (_chosen != null) ...[
              const SizedBox(height: 12),
              ResultActions(
                summary: _summaryFor(_chosen!),
                savedToFieldId: _savedToFieldId,
                onSaved: (id) => setState(() => _savedToFieldId = id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.labels, required this.isSelected, required this.onTap});
  final List<String> labels;
  final bool Function(int) isSelected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected(i) ? p.ink : p.paper2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isSelected(i) ? p.ink : p.hairline),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected(i) ? p.paper : p.ink)),
            ),
          ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.chosen,
    required this.dimmed,
    required this.onChoose,
  });

  final RetrievedCard match;
  final bool chosen;
  final bool dimmed;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = match.card;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: dimmed ? 0.45 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.paper2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: chosen ? p.ink : p.hairline, width: chosen ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(spacing: 6, runSpacing: 6, children: [
                    StampTag(label: context.tr(card.crop), filled: true),
                    StampTag(label: context.tr(card.kind.label)),
                  ]),
                ),
                Text('${(match.score * 100).round()}%',
                    style: AppTheme.stencil(size: 22, color: p.inkSoft)),
              ],
            ),
            const SizedBox(height: 10),
            Text(context.tr(card.title), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(card.symptoms,
                style: TextStyle(fontSize: 13, height: 1.4, color: p.ink)),
            if (chosen) ...[
              SectionLabel(context.tr('What to do')),
              Text(card.management,
                  style: TextStyle(fontSize: 13.5, height: 1.45, color: p.ink)),
              if (card.safety != null) ...[
                const SizedBox(height: 12),
                SafetyNote(title: context.tr('Before you spray'), text: card.safety!),
              ],
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CardDetailScreen(card: card),
                  )),
                  child: Text(context.tr('Read more')),
                ),
                const Spacer(),
                if (!chosen)
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed: onChoose,
                    child: Text(context.tr('This looks right')),
                  )
                else
                  Text(context.tr('YOUR MATCH'), style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
