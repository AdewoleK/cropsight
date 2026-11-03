// TEMPORARY visual-QA / screenshot harness for the redesign — exercises the
// real theme and lib/theme/widgets.dart components with representative
// content, deliberately avoiding any import of GemmaService/RagService/
// SyncService (those pull in dart:io + native plugins and won't compile for
// web/desktop). Not part of the app; run with
// `flutter run -d web-server -t lib/dev_preview.dart` and delete once done.
//
// Pass ?screen=N in the URL to render a single screen full-bleed, with no
// picker chrome, for clean screenshotting.
import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'theme/widgets.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropSight preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const _PreviewShell(),
    );
  }
}

class _PreviewShell extends StatefulWidget {
  const _PreviewShell();
  @override
  State<_PreviewShell> createState() => _PreviewShellState();
}

class _PreviewShellState extends State<_PreviewShell> {
  int _screen = 0;
  bool _dark = false;
  int? _screenshotMode;
  static const _names = [
    'Setup',
    'Capture',
    'Confirm',
    'Scanning',
    'Result',
    'Log'
  ];

  @override
  void initState() {
    super.initState();
    final screenParam = Uri.base.queryParameters['screen'];
    final darkParam = Uri.base.queryParameters['dark'];
    if (screenParam != null) {
      _screenshotMode = int.tryParse(screenParam) ?? 0;
      _screen = _screenshotMode!;
    }
    if (darkParam == '1') _dark = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_screenshotMode != null) {
      // Clean, chrome-less render for screenshotting.
      return Theme(
        data: _dark ? AppTheme.dark() : AppTheme.light(),
        child: Builder(builder: (context) {
          final p = context.palette;
          return ColoredBox(
            color: p.paper2,
            child: Center(
              child: _PhoneFrame(child: _screenFor(_screenshotMode!)),
            ),
          );
        }),
      );
    }

    return Theme(
      data: _dark ? AppTheme.dark() : AppTheme.light(),
      child: Scaffold(
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: [
                          for (var i = 0; i < _names.length; i++)
                            ChoiceChip(
                              label: Text(_names[i]),
                              selected: _screen == i,
                              onSelected: (_) => setState(() => _screen = i),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(_dark ? Icons.dark_mode : Icons.light_mode),
                      onPressed: () => setState(() => _dark = !_dark),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Center(
                child: _PhoneFrame(child: _screenFor(_screen)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _screenFor(int i) => switch (i) {
        0 => const _SetupMock(),
        1 => const _CaptureMock(state: _CaptureState.empty),
        2 => const _CaptureMock(state: _CaptureState.confirm),
        3 => const _CaptureMock(state: _CaptureState.scanning),
        4 => const _ResultMock(),
        _ => const _LogMock(),
      };
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 720,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: child,
      ),
    );
  }
}

// ---- Setup ----
class _SetupMock extends StatelessWidget {
  const _SetupMock();
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
                  style:
                      TextStyle(fontSize: 13, height: 1.5, color: p.inkSoft)),
              const Spacer(flex: 2),
              Row(children: [
                Container(
                    width: 20,
                    height: 20,
                    decoration:
                        BoxDecoration(color: p.fern, shape: BoxShape.circle),
                    child: Icon(Icons.check, size: 13, color: p.onFern)),
                const SizedBox(width: 12),
                Text('Loading on-device model',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.ink)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: p.marigold, width: 2.4))),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Loading knowledge embedder',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: p.ink))),
                Text('64%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: p.marigold)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: p.hairline, width: 2))),
                const SizedBox(width: 12),
                Text('Indexing the field guide',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.husk)),
              ]),
              const SizedBox(height: 14),
              ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child:
                      const LinearProgressIndicator(value: 0.64, minHeight: 6)),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Capture ----
enum _CaptureState { empty, confirm, scanning }

class _CaptureMock extends StatelessWidget {
  const _CaptureMock({required this.state});
  final _CaptureState state;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title:
            Text('CropSight', style: AppTheme.stencil(size: 19, color: p.ink)),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: OfflinePill())
        ],
      ),
      bottomNavigationBar: CropSightBottomNav(index: 0, onChanged: (_) {}),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 280,
                child: ScanFrame(
                  scanning: state == _CaptureState.scanning,
                  child: state == _CaptureState.empty
                      ? Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [p.paper2, p.hairline, p.paper2])),
                          child: Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('AIM AT ONE LEAF',
                                      style: AppTheme.stencil(
                                          size: 18, color: p.ink)),
                                  const SizedBox(height: 6),
                                  Text(
                                      'Fill the brackets. Natural light works best.',
                                      style: TextStyle(
                                          fontSize: 12, color: p.inkSoft)),
                                ]),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                                center: Alignment(-0.2, -0.3),
                                radius: 1.0,
                                colors: [Color(0xFF6D8A3E), Color(0xFF35501E)]),
                          ),
                          child: CustomPaint(painter: _LeafDetailPainter()),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (state == _CaptureState.empty)
                Row(children: [
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.photo_library_outlined,
                              size: 18),
                          label: const Text('Gallery'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.center_focus_strong, size: 18),
                          label: const Text('Scan leaf'))),
                ])
              else if (state == _CaptureState.confirm)
                Row(children: [
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.replay, size: 18),
                          label: const Text('Retake'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.center_focus_strong, size: 18),
                          label: const Text('Diagnose'))),
                ])
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: p.paper2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.hairline)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Checking the field guide…',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        const StatusTrack(stages: [
                          ('Look', TrackState.done),
                          ('Match', TrackState.active),
                          ('Write', TrackState.pending)
                        ]),
                      ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeafDetailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final vein = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 19) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), vein);
    }
    final spot = Paint()
      ..color = const Color(0xFF6B431C).withValues(alpha: 0.85);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.34, size.height * 0.4),
            width: 34,
            height: 26),
        spot);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.58, size.height * 0.62),
            width: 24,
            height: 18),
        spot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---- Result ----
class _ResultMock extends StatelessWidget {
  const _ResultMock();
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title:
            Text('CropSight', style: AppTheme.stencil(size: 19, color: p.ink)),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: OfflinePill())
        ],
      ),
      bottomNavigationBar: CropSightBottomNav(index: 0, onChanged: (_) {}),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                  height: 200,
                  child: ScanFrame(
                      child: Container(color: const Color(0xFF4C6B2C)))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: p.paper2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.hairline)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      StampTag(label: 'Tomato', filled: true),
                      StampTag(label: 'Early blight'),
                    ]),
                    SizedBox(height: 16),
                    ConfidenceWord(
                        level: 'high',
                        reason: 'clear match to 2 of 3 field-guide cards'),
                    SectionLabel('What to do now'),
                    SizedBox(height: 4),
                    StepTimeline(steps: [
                      "Remove and destroy affected lower leaves — don't compost them.",
                      'Space plants for airflow; avoid wetting leaves when watering.',
                      'Apply a copper-based fungicide if spread continues past 3 days.',
                    ]),
                    SectionLabel('Sources'),
                    LedgerRow(label: 'Early blight — tomato', value: '94%'),
                    LedgerRow(label: 'Leaf spot, general', value: '71%'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Log ----
class _LogMock extends StatelessWidget {
  const _LogMock();
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Field log', style: AppTheme.stencil(size: 19, color: p.ink)),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 16),
              child: OfflinePill(label: '3 UNSYNCED', dotColor: p.marigold))
        ],
      ),
      bottomNavigationBar: CropSightBottomNav(index: 1, onChanged: (_) {}),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(child: _statBox(p, 'Pending', 3)),
              const SizedBox(width: 12),
              Expanded(child: _statBox(p, 'Synced', 11)),
            ]),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Sync now')),
            const SectionLabel('Recent'),
            _logRow(p, 'Tomato — early blight', 'Aug 7, 09:14', false),
            _logRow(p, 'Maize — nitrogen deficiency', 'Aug 6, 17:02', true),
            _logRow(p, 'Cassava — mosaic virus', 'Aug 5, 08:41', true),
          ],
        ),
      ),
    );
  }

  Widget _statBox(CropSightPalette p, String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: p.paper2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$value', style: AppTheme.stencil(size: 30, color: p.ink)),
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: p.husk)),
      ]),
    );
  }

  Widget _logRow(CropSightPalette p, String title, String time, bool synced) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: p.hairline))),
      child: Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: synced ? p.fern : p.marigold, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w800)),
            Text(time, style: TextStyle(fontSize: 10.5, color: p.husk)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: synced ? p.fern : p.paper2,
              borderRadius: BorderRadius.circular(6),
              border: synced ? null : Border.all(color: p.hairline)),
          child: Text(synced ? 'SYNCED' : 'PENDING',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: synced ? p.onFern : p.inkSoft)),
        ),
      ]),
    );
  }
}
