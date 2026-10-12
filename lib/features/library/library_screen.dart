import 'package:flutter/material.dart';

import '../../core/rag/knowledge_base.dart';
import '../../core/rag/knowledge_card.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets.dart';
import '../settings/settings_screen.dart';
import 'card_detail_screen.dart';

/// The field guide, browsable without a photo: every reference card the
/// diagnosis can cite, searchable and filterable by crop and kind.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _query = '';
  String? _crop;
  CardKind? _kind;

  static final List<String> _crops = {
    for (final c in KnowledgeBase.cards) c.crop,
  }.toList()
    ..sort();

  List<KnowledgeCard> get _filtered {
    final q = _query.trim().toLowerCase();
    return KnowledgeBase.cards.where((c) {
      if (_crop != null && c.crop != _crop) return false;
      if (_kind != null && c.kind != _kind) return false;
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          c.crop.toLowerCase().contains(q) ||
          c.symptoms.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        final byCrop = a.crop.compareTo(b.crop);
        return byCrop != 0 ? byCrop : a.title.compareTo(b.title);
      });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cards = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text('Library', style: AppTheme.stencil(size: 19, color: p.ink)),
        actions: const [SettingsButton(), SizedBox(width: 8)],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search a crop, disease or symptom',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: p.paper2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _ChipRow(
              children: [
                for (final kind in CardKind.values)
                  _FilterChip(
                    label: kind.label,
                    selected: _kind == kind,
                    onTap: () => setState(() => _kind = _kind == kind ? null : kind),
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _ChipRow(
              children: [
                for (final crop in _crops)
                  _FilterChip(
                    label: crop,
                    selected: _crop == crop,
                    onTap: () => setState(() => _crop = _crop == crop ? null : crop),
                  ),
              ],
            ),
          ),
          if (cards.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Nothing matches.', style: TextStyle(color: p.husk)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.builder(
                itemCount: cards.length,
                itemBuilder: (context, i) {
                  final card = cards[i];
                  final newCrop = i == 0 || cards[i - 1].crop != card.crop;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (newCrop) SectionLabel(card.crop),
                      _CardTile(card: card),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? p.ink : p.paper2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? p.ink : p.hairline),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? p.paper : p.ink)),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card});
  final KnowledgeCard card;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.hairline))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(card.symptoms,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, height: 1.35, color: p.inkSoft)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(card.kind.label.toUpperCase(),
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: p.husk)),
            Icon(Icons.chevron_right, color: p.husk),
          ],
        ),
      ),
    );
  }
}
