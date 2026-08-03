import 'package:flutter/material.dart';

import 'core/ai/gemma_service.dart';
import 'features/diagnosis/diagnosis_screen.dart';
import 'features/onboarding/app_setup_screen.dart';
import 'theme/app_theme.dart';

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

/// Decides where to send the user on launch: run first-time setup, or diagnose.
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
    return const DiagnosisScreen();
  }
}
