import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropsight/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme builds light and dark themes', (tester) async {
    expect(AppTheme.light(), isA<ThemeData>());
    expect(AppTheme.dark(), isA<ThemeData>());
  });
}
