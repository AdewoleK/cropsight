import 'package:flutter/material.dart';

/// CropSight's design system: a field-instrument identity — stamped stencil
/// numerals over a warm, soil-toned UI — built to stay legible in direct sun
/// on a low-end phone, not to look like a generic "eco" app.
///
/// [CropSightPalette] carries the semantic colors Material's [ColorScheme]
/// doesn't have a slot for (confidence levels, hairlines, the stamp accent).
/// [stencil] is the display face for the brand mark, big numerals and
/// confidence words — deliberately kept out of [TextTheme] so it's never
/// reached for by accident on body copy.
class AppTheme {
  static const String bodyFont = 'Plus Jakarta Sans';
  static const String stencilFont = 'Allerta Stencil';

  static ThemeData light() => _build(CropSightPalette.light);
  static ThemeData dark() => _build(CropSightPalette.dark);

  static ThemeData _build(CropSightPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.rust,
      onPrimary: p.onRust,
      primaryContainer: p.paper2,
      onPrimaryContainer: p.ink,
      secondary: p.fern,
      onSecondary: p.onFern,
      error: p.brick,
      onError: p.onBrick,
      surface: p.paper,
      onSurface: p.ink,
      surfaceContainerHighest: p.paper2,
      outline: p.hairline,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: p.paper,
      fontFamily: bodyFont,
      splashFactory: NoSplash.splashFactory,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.paper,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        foregroundColor: p.ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.rust,
          foregroundColor: p.onRust,
          disabledBackgroundColor: p.rust.withValues(alpha: 0.35),
          disabledForegroundColor: p.onRust.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
              fontFamily: bodyFont,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.2),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          disabledForegroundColor: p.husk,
          side: BorderSide(color: p.ink, width: 1.6),
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
              fontFamily: bodyFont,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.2),
          shape: const StadiumBorder(),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: p.paper2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.hairline),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.hairline, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.rust,
        linearTrackColor: p.paper2,
      ),
      textSelectionTheme:
          TextSelectionThemeData(cursorColor: p.rust, selectionColor: p.rust.withValues(alpha: 0.25)),
      textTheme: _textTheme(p),
    );
  }

  static TextTheme _textTheme(CropSightPalette p) {
    TextStyle s(double size, FontWeight w,
        {double? height, double? spacing, Color? color}) {
      return TextStyle(
        fontFamily: bodyFont,
        fontSize: size,
        fontWeight: w,
        height: height,
        letterSpacing: spacing,
        color: color ?? p.ink,
      );
    }

    return TextTheme(
      headlineSmall: s(22, FontWeight.w800, height: 1.15),
      titleLarge: s(18, FontWeight.w800, height: 1.2),
      titleMedium: s(15.5, FontWeight.w800, height: 1.25),
      titleSmall: s(13, FontWeight.w800, height: 1.25),
      bodyLarge: s(15, FontWeight.w500, height: 1.5),
      bodyMedium: s(13.5, FontWeight.w500, height: 1.5),
      bodySmall: s(12, FontWeight.w600, height: 1.4, color: p.husk),
      labelLarge: s(11, FontWeight.w800, spacing: 1.3, color: p.husk),
      labelMedium: s(10, FontWeight.w800, spacing: 1.1, color: p.husk),
      labelSmall: s(9, FontWeight.w800, spacing: 1, color: p.husk),
    );
  }

  /// The stamped/stencil display face — brand mark, big numerals, confidence
  /// words. Always reached for through this helper, never via [TextTheme].
  static TextStyle stencil({
    required double size,
    Color? color,
    double letterSpacing = 0.2,
  }) {
    return TextStyle(
      fontFamily: stencilFont,
      fontSize: size,
      fontWeight: FontWeight.w400,
      height: 0.95,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}

/// Semantic colors for CropSight's field-instrument identity, threaded
/// through [ThemeData.extensions] so every widget reads from one source.
///
/// Rust is the single brand accent (actions only). Fern / marigold / brick
/// are confidence semantics — high / medium / low — and are never used
/// decoratively outside that meaning.
@immutable
class CropSightPalette extends ThemeExtension<CropSightPalette> {
  const CropSightPalette({
    required this.brightness,
    required this.paper,
    required this.paper2,
    required this.ink,
    required this.inkSoft,
    required this.husk,
    required this.hairline,
    required this.rust,
    required this.onRust,
    required this.fern,
    required this.onFern,
    required this.marigold,
    required this.onMarigold,
    required this.brick,
    required this.onBrick,
  });

  final Brightness brightness;
  final Color paper;
  final Color paper2;
  final Color ink;
  final Color inkSoft;
  final Color husk;
  final Color hairline;
  final Color rust;
  final Color onRust;
  final Color fern;
  final Color onFern;
  final Color marigold;
  final Color onMarigold;
  final Color brick;
  final Color onBrick;

  static const light = CropSightPalette(
    brightness: Brightness.light,
    paper: Color(0xFFEEE7D7),
    paper2: Color(0xFFE3D8BC),
    ink: Color(0xFF201A10),
    inkSoft: Color(0xFF4A4232),
    husk: Color(0xFFA89A76),
    hairline: Color(0x24201A10),
    rust: Color(0xFFA83F24),
    onRust: Color(0xFFFFF9EE),
    fern: Color(0xFF3F6B3A),
    onFern: Color(0xFFF3F7EC),
    marigold: Color(0xFFB9860F),
    onMarigold: Color(0xFF241804),
    brick: Color(0xFF8A3A34),
    onBrick: Color(0xFFFCEFEC),
  );

  static const dark = CropSightPalette(
    brightness: Brightness.dark,
    paper: Color(0xFF17130C),
    paper2: Color(0xFF241E14),
    ink: Color(0xFFEEE6D4),
    inkSoft: Color(0xFFB5A888),
    husk: Color(0xFF8B8064),
    hairline: Color(0x24EEE6D4),
    rust: Color(0xFFD5693F),
    onRust: Color(0xFF1A1108),
    fern: Color(0xFF6FA066),
    onFern: Color(0xFF12200F),
    marigold: Color(0xFFD9A53A),
    onMarigold: Color(0xFF241804),
    brick: Color(0xFFC96155),
    onBrick: Color(0xFF230D0A),
  );

  /// Confidence-level colors: low/medium/high (see `StructuredDiagnosis`).
  Color confidence(String? level) => switch (level) {
        'high' => fern,
        'medium' => marigold,
        'low' => brick,
        _ => husk,
      };

  @override
  CropSightPalette copyWith({
    Brightness? brightness,
    Color? paper,
    Color? paper2,
    Color? ink,
    Color? inkSoft,
    Color? husk,
    Color? hairline,
    Color? rust,
    Color? onRust,
    Color? fern,
    Color? onFern,
    Color? marigold,
    Color? onMarigold,
    Color? brick,
    Color? onBrick,
  }) {
    return CropSightPalette(
      brightness: brightness ?? this.brightness,
      paper: paper ?? this.paper,
      paper2: paper2 ?? this.paper2,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      husk: husk ?? this.husk,
      hairline: hairline ?? this.hairline,
      rust: rust ?? this.rust,
      onRust: onRust ?? this.onRust,
      fern: fern ?? this.fern,
      onFern: onFern ?? this.onFern,
      marigold: marigold ?? this.marigold,
      onMarigold: onMarigold ?? this.onMarigold,
      brick: brick ?? this.brick,
      onBrick: onBrick ?? this.onBrick,
    );
  }

  @override
  CropSightPalette lerp(ThemeExtension<CropSightPalette>? other, double t) {
    if (other is! CropSightPalette) return this;
    return CropSightPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      paper: Color.lerp(paper, other.paper, t)!,
      paper2: Color.lerp(paper2, other.paper2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      husk: Color.lerp(husk, other.husk, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      rust: Color.lerp(rust, other.rust, t)!,
      onRust: Color.lerp(onRust, other.onRust, t)!,
      fern: Color.lerp(fern, other.fern, t)!,
      onFern: Color.lerp(onFern, other.onFern, t)!,
      marigold: Color.lerp(marigold, other.marigold, t)!,
      onMarigold: Color.lerp(onMarigold, other.onMarigold, t)!,
      brick: Color.lerp(brick, other.brick, t)!,
      onBrick: Color.lerp(onBrick, other.onBrick, t)!,
    );
  }
}

/// Shorthand for `Theme.of(context).extension<CropSightPalette>()!`.
extension CropSightThemeX on BuildContext {
  CropSightPalette get palette =>
      Theme.of(this).extension<CropSightPalette>()!;
}
