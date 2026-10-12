import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/ai/gemma_service.dart';
import 'core/rag/rag_service.dart';
import 'core/settings/app_settings.dart';
import 'features/diagnosis/diagnosis_screen.dart';
import 'features/fields/fields_screen.dart';
import 'features/library/library_screen.dart';
import 'features/onboarding/app_setup_screen.dart';
import 'features/sync/sync_status_screen.dart';
import 'theme/app_theme.dart';
import 'theme/widgets.dart';

class CropSightApp extends StatelessWidget {
  const CropSightApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: settings,
      child: Consumer<AppSettings>(
        builder: (context, settings, _) => MaterialApp(
          title: 'CropSight',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          home: const _StartupGate(),
        ),
      ),
    );
  }
}

/// Decides where to send the user on launch: run first-time setup, or the
/// main two-tab shell.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool? _installed;
  bool? _checkedLite;

  /// Re-checks whenever the effective mode changes, so switching Lite →
  /// Photo in settings runs the photo-model setup it now needs.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lite = context.watch<AppSettings>().useLiteMode;
    if (lite != _checkedLite) {
      _checkedLite = lite;
      _installed = null;
      _check(lite);
    }
  }

  Future<void> _check(bool lite) async {
    final installed = lite
        ? context.read<AppSettings>().liteReady
        : await GemmaService.instance.isModelInstalled();
    if (mounted && lite == _checkedLite) setState(() => _installed = installed);
  }

  @override
  Widget build(BuildContext context) {
    final lite = context.watch<AppSettings>().useLiteMode;
    if (_installed == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_installed == false) {
      return AppSetupScreen(
        key: ValueKey(lite),
        lite: lite,
        onReady: () {
          if (lite) context.read<AppSettings>().liteReady = true;
          setState(() => _installed = true);
        },
      );
    }
    return const _RootShell();
  }
}

/// The main tab shell — Diagnose is the core flow; Fields tracks plots over
/// the season; Library is the browsable field guide; Log is the sync/history
/// view. An [IndexedStack] keeps an in-progress diagnosis alive if the farmer
/// flips to another tab and back.
class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // After an app update grows the field guide, re-index in the background
    // now rather than stalling the farmer's next diagnosis. A no-op when the
    // cached index is current.
    RagService.instance.ensureReady().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DiagnosisScreen(),
          FieldsScreen(),
          LibraryScreen(),
          SyncStatusScreen(),
        ],
      ),
      bottomNavigationBar: CropSightBottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
