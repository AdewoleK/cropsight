import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../core/settings/app_settings.dart';
import 'app_theme.dart';

/// Shared vocabulary for CropSight's field-instrument identity: scan
/// brackets, stamped tags, ledger rows — the parts every screen reuses so
/// the app reads as one designed system rather than four separate screens.

/// CropSight's brand glyph: a leaf inside scan brackets, the same mark as
/// the app icon (assets/branding/cropsight-icon.svg). Drawn on a 100-unit
/// grid matching that SVG; the leaf's veins are cut out so it reads on any
/// background.
class CropSightMark extends StatelessWidget {
  const CropSightMark({super.key, this.size = 72, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.rust;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CropSightMarkPainter(c)),
    );
  }
}

class _CropSightMarkPainter extends CustomPainter {
  _CropSightMarkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.scale(size.width / 100, size.height / 100);

    Paint line(double width, {BlendMode mode = BlendMode.srcOver}) => Paint()
      ..color = color
      ..blendMode = mode
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final brackets = Path()
      ..moveTo(22, 36)
      ..lineTo(22, 22)
      ..lineTo(36, 22)
      ..moveTo(64, 22)
      ..lineTo(78, 22)
      ..lineTo(78, 36)
      ..moveTo(22, 64)
      ..lineTo(22, 78)
      ..lineTo(36, 78)
      ..moveTo(64, 78)
      ..lineTo(78, 78)
      ..lineTo(78, 64);
    canvas.drawPath(brackets, line(5));

    final leaf = Path()
      ..moveTo(37, 63)
      ..cubicTo(33, 46, 47, 34, 66, 34)
      ..cubicTo(66, 53, 54, 67, 37, 63)
      ..close();
    canvas.drawPath(leaf, Paint()..color = color);
    canvas.drawLine(const Offset(37, 63), const Offset(32, 68), line(3.4));

    canvas.drawLine(const Offset(39.5, 60.5), const Offset(61, 39),
        line(2.2, mode: BlendMode.clear));
    final veins = Path()
      ..moveTo(47, 53)
      ..lineTo(43.5, 46.5)
      ..moveTo(47, 53)
      ..lineTo(53.5, 56.5)
      ..moveTo(53, 47)
      ..lineTo(50.5, 41.5)
      ..moveTo(53, 47)
      ..lineTo(58.5, 49.5);
    canvas.drawPath(veins, line(1.6, mode: BlendMode.clear));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CropSightMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Wraps [child] with four L-shaped scan-target corner brackets — the
/// viewfinder/diagnostic-instrument motif used on every capture state.
/// When [scanning] is true, an animated highlight line sweeps the frame.
class ScanFrame extends StatefulWidget {
  const ScanFrame({
    super.key,
    required this.child,
    this.scanning = false,
    this.borderRadius = 20,
  });

  final Widget child;
  final bool scanning;
  final double borderRadius;

  @override
  State<ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<ScanFrame> with SingleTickerProviderStateMixin {
  // Created eagerly: a lazy `late final` would first be touched in
  // dispose() when the frame never scanned, creating a ticker on a
  // deactivated element.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (widget.scanning && !reduceMotion)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return FractionallySizedBox(
                  alignment: Alignment(0, _controller.value * 2 - 1),
                  heightFactor: 1,
                  widthFactor: 0.9,
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        boxShadow: [BoxShadow(color: p.marigold, blurRadius: 10)],
                        gradient: LinearGradient(colors: [
                          p.marigold.withValues(alpha: 0),
                          p.marigold,
                          p.marigold,
                          p.marigold.withValues(alpha: 0),
                        ], stops: const [0, 0.2, 0.8, 1]),
                      ),
                    ),
                  ),
                );
              },
            ),
          CustomPaint(
            painter: _CornerBracketPainter(
              color: p.rust,
              radius: widget.borderRadius,
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  _CornerBracketPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    const len = 22.0;
    const inset = 14.0;
    final r = radius * 0.5;

    void corner(Offset origin, double dx, double dy) {
      final path = Path()
        ..moveTo(origin.dx, origin.dy + dy * len)
        ..lineTo(origin.dx, origin.dy + dy * r)
        ..arcToPoint(Offset(origin.dx + dx * r, origin.dy), radius: Radius.circular(r))
        ..moveTo(origin.dx + dx * r, origin.dy)
        ..lineTo(origin.dx + dx * len, origin.dy);
      canvas.drawPath(path, paint);
    }

    corner(const Offset(inset, inset), 1, 1);
    corner(Offset(size.width - inset, inset), -1, 1);
    corner(Offset(inset, size.height - inset), 1, -1);
    corner(Offset(size.width - inset, size.height - inset), -1, -1);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// A stamped tag — dashed outline by default, or a solid "crate stamp" fill
/// for the primary (crop) tag.
class StampTag extends StatelessWidget {
  const StampTag({super.key, required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final textStyle = TextStyle(
      fontFamily: AppTheme.bodyFont,
      fontWeight: FontWeight.w800,
      fontSize: 11.5,
      letterSpacing: 0.4,
      color: filled ? p.paper : p.ink,
    );
    if (filled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(7)),
        child: Text(label.toUpperCase(), style: textStyle),
      );
    }
    return CustomPaint(
      painter: _DashedRectPainter(color: p.ink, radius: 7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(label.toUpperCase(), style: textStyle),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 4.5, gap = 3.5;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next.toDouble()), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A big stencil confidence word ("HIGH" / "MEDIUM" / "LOW") with its reason.
class ConfidenceWord extends StatelessWidget {
  const ConfidenceWord({super.key, required this.level, this.reason});

  final String level;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = p.confidence(level);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
            switch (level) {
              'high' => context.tr('HIGH'),
              'medium' => context.tr('MEDIUM'),
              'low' => context.tr('LOW'),
              _ => level.toUpperCase(),
            },
            style: AppTheme.stencil(size: 36, color: color)),
        if (reason != null) ...[
          const SizedBox(width: 14),
          Expanded(
            child: Text(reason!,
                style: TextStyle(
                    fontSize: 12, height: 1.35, color: p.inkSoft, fontWeight: FontWeight.w500)),
          ),
        ],
      ],
    );
  }
}

/// One state in a [StatusTrack] — mirrors the diagnosis pipeline stage.
enum TrackState { pending, active, done }

/// The three-stage "Look / Match / Write" pipeline indicator shown while a
/// diagnosis is running.
class StatusTrack extends StatelessWidget {
  const StatusTrack({super.key, required this.stages});

  /// Ordered (label, state) pairs.
  final List<(String, TrackState)> stages;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        for (final (label, state) in stages)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: switch (state) {
                    TrackState.done => p.fern,
                    TrackState.active => p.marigold,
                    TrackState.pending => p.paper2,
                  },
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: state == TrackState.pending ? p.hairline : Colors.transparent,
                  ),
                ),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: switch (state) {
                      TrackState.done => p.onFern,
                      TrackState.active => p.onMarigold,
                      TrackState.pending => p.husk,
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A numbered instruction with a connecting line to the next step — the
/// "feed-sack instructions" motif for remediation steps.
class StepTimeline extends StatelessWidget {
  const StepTimeline({super.key, required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: p.rust, shape: BoxShape.circle),
                      child: Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800, color: p.onRust)),
                    ),
                    if (i < steps.length - 1)
                      Expanded(child: Container(width: 1.4, color: p.hairline)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 2),
                    child: Text(steps[i],
                        style: TextStyle(fontSize: 13.5, height: 1.4, color: p.ink)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A dotted-rule row — label on the left, value on the right — for the
/// sources "ledger".
class LedgerRow extends StatelessWidget {
  const LedgerRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.hairline, style: BorderStyle.solid)),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_outlined, size: 15, color: p.husk),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: p.inkSoft,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

/// A section header used above steps/sources — small caps label with a
/// hairline rule, matching the mockup's "instrument readout" vocabulary.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.hairline))),
      child: Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

/// The small "OFFLINE READY" status stamp shown in every app bar.
class OfflinePill extends StatelessWidget {
  const OfflinePill({super.key, this.label, this.dotColor});

  /// Defaults to "OFFLINE READY" in the app language.
  final String? label;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: p.paper2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor ?? p.fern, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label ?? context.tr('OFFLINE READY'),
              style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: p.inkSoft)),
        ],
      ),
    );
  }
}

/// Safety guidance for chemical treatments — a heavy ink rule rather than a
/// colour, since fern/marigold/brick are reserved for confidence.
class SafetyNote extends StatelessWidget {
  const SafetyNote({super.key, required this.text, this.title});

  final String text;

  /// Defaults to "Stay safe" in the app language.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.paper2,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: p.ink, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined, size: 20, color: p.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((title ?? context.tr('Stay safe')).toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(fontSize: 13, height: 1.4, color: p.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The pill bottom navigation across the app's top-level tabs.
class CropSightBottomNav extends StatelessWidget {
  const CropSightBottomNav({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tabs = [
      (Icons.center_focus_strong_outlined, context.tr('Diagnose')),
      (Icons.grass_outlined, context.tr('Fields')),
      (Icons.menu_book_outlined, context.tr('Library')),
      (Icons.receipt_long_outlined, context.tr('Log')),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < tabs.length - 1 ? 6 : 0),
                  child: GestureDetector(
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: i == index ? p.ink : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tabs[i].$1,
                              size: 19, color: i == index ? p.paper : p.husk),
                          const SizedBox(height: 3),
                          Text(tabs[i].$2,
                              style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: i == index ? p.paper : p.husk)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


/// Shown above field-guide text when the app isn't in English: the long
/// descriptions haven't been translated yet, only the names.
class EnglishOnlyNote extends StatelessWidget {
  const EnglishOnlyNote({super.key});

  @override
  Widget build(BuildContext context) {
    if (LanguageScope.of(context) == AnswerLanguage.english) {
      return const SizedBox.shrink();
    }
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.paper2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.marigold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.translate, size: 18, color: p.marigold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr('Field guide details are in English for now. Ask an extension officer if you need help reading them.'),
              style: TextStyle(fontSize: 12.5, height: 1.4, color: p.ink),
            ),
          ),
        ],
      ),
    );
  }
}
