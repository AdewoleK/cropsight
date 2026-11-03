import 'dart:io';

import 'package:cropsight/core/rag/knowledge_base.dart';
import 'package:cropsight/core/settings/app_settings.dart';
import 'package:cropsight/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every literal passed to tr() / context.tr() in lib/.
Set<String> _keysInCode() {
  final call = RegExp(r'''\btr\(\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")''');
  final keys = <String>{};
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (!name.endsWith('.dart') || name.startsWith('translations_') || name == 'dev_preview.dart') {
      continue;
    }
    for (final m in call.allMatches(f.readAsStringSync())) {
      keys.add((m.group(1) ?? m.group(2)!)
          .replaceAll(r"\'", "'")
          .replaceAll(r'\"', '"')
          .replaceAll(r'\n', '\n'));
    }
  }
  return keys;
}

void main() {
  final needed = {
    ..._keysInCode(),
    for (final c in KnowledgeBase.cards) ...[c.crop, c.title, c.kind.label],
    for (final m in DiagnosisMode.values) m.label,
  };

  test('found the phrases', () => expect(needed.length, greaterThan(300)));

  for (final entry in translations.entries) {
    test('${entry.key.name} translates every phrase', () {
      final missing = needed.where((k) => !entry.value.containsKey(k)).toList();
      expect(missing, isEmpty, reason: 'run python3 tool/l10n/build.py');
    });

    test('${entry.key.name} keeps every {placeholder}', () {
      final ph = RegExp(r'\{\w+\}');
      for (final e in entry.value.entries) {
        final want = ph.allMatches(e.key).map((m) => m[0]).toList()..sort();
        final got = ph.allMatches(e.value).map((m) => m[0]).toList()..sort();
        expect(got, want, reason: e.key);
      }
    });
  }

  test('placeholders are filled and English falls back', () {
    expect(translate(AnswerLanguage.hausa, 'In {n} days', {'n': 3}), 'Bayan kwana 3');
    expect(translate(AnswerLanguage.english, 'In {n} days', {'n': 3}), 'In 3 days');
    expect(translate(AnswerLanguage.yoruba, 'not a known phrase'), 'not a known phrase');
  });
}
