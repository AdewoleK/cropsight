import 'package:flutter/material.dart';

import 'core/ai/gemma_service.dart';
import 'features/diagnosis/diagnosis_screen.dart';
import 'features/onboarding/app_setup_screen.dart';
import 'features/sync/sync_status_screen.dart';
import 'theme/app_theme.dart';
import 'theme/widgets.dart';

class CropSightApp extends StatelessWidget {
  const CropSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropSight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const _StartupGate(),
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

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final installed = await GemmaService.instance.isModelInstalled();
    if (mounted) setState(() => _installed = installed);
  }

  @override
  Widget build(BuildContext context) {
    if (_installed == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_installed == false) {
      return AppSetupScreen(
        onReady: () => setState(() => _installed = true),
      );
    }
    return const _RootShell();
  }
}

/// The main two-tab shell — Diagnose is the core flow, Log is the
/// sync/history view. An [IndexedStack] keeps an in-progress diagnosis alive
/// if the farmer flips to the log and back.
class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [DiagnosisScreen(), SyncStatusScreen()],
      ),
      bottomNavigationBar: CropSightBottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
