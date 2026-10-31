// Writes server/data/cards.json: the field-guide catalogue (id, crop, title,
// kind) the surveillance server uses to name what phones report. Phones only
// send card ids, so rerun this whenever KnowledgeBase.cards changes:
//
//   dart run tool/export_cards.dart
import 'dart:convert';
import 'dart:io';

import 'package:cropsight/core/rag/knowledge_base.dart';

void main() {
  final cards = {
    for (final c in KnowledgeBase.cards)
      c.id: {'crop': c.crop, 'title': c.title, 'kind': c.kind.name},
  };
  File('server/data/cards.json').writeAsStringSync(
    const JsonEncoder.withIndent(' ').convert({
      'knowledge_base_version': KnowledgeBase.version,
      'cards': cards,
    }),
  );
  stdout.writeln('${cards.length} cards written to server/data/cards.json');
}
