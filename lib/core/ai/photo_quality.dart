import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// A problem with a photo that makes a diagnosis unreliable.
enum PhotoIssue {
  tooDark('Too dark', 'Move into daylight or open shade.'),
  tooBright('Washed out', 'Avoid direct glare — shade the leaf with your body.'),
  blurry('Blurry', 'Hold the phone still and tap the leaf to focus.');

  const PhotoIssue(this.title, this.fix);
  final String title;
  final String fix;
}

/// Cheap, fully offline checks run on a photo before the (slow) model sees
/// it, so a farmer can retake a bad shot instead of waiting for a bad answer.
///
/// Heuristics on a downscaled greyscale copy: mean brightness for exposure,
/// and variance of the Laplacian for focus. Deliberately lenient — these are
/// warnings, never blockers.
class PhotoQuality {
  const PhotoQuality._();

  static Future<List<PhotoIssue>> check(Uint8List bytes) =>
      compute(_analyze, bytes);

  static const int _sampleSize = 320;
  static const double _darkMean = 50;
  static const double _clippedLuma = 250;
  static const double _maxClippedFraction = 0.4;
  static const double _minSharpness = 40;
}

List<PhotoIssue> _analyze(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return const [];
  final small = decoded.width >= decoded.height
      ? img.copyResize(decoded, width: PhotoQuality._sampleSize)
      : img.copyResize(decoded, height: PhotoQuality._sampleSize);

  final w = small.width, h = small.height;
  final luma = Float64List(w * h);
  var sum = 0.0;
  var clipped = 0;
  for (final px in small) {
    final y = 0.299 * px.r + 0.587 * px.g + 0.114 * px.b;
    luma[px.y * w + px.x] = y;
    sum += y;
    if (y >= PhotoQuality._clippedLuma) clipped++;
  }
  final mean = sum / luma.length;

  // Variance of the 4-neighbour Laplacian: low means few sharp edges.
  var lapSum = 0.0, lapSqSum = 0.0;
  var n = 0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final i = y * w + x;
      final lap =
          4 * luma[i] - luma[i - 1] - luma[i + 1] - luma[i - w] - luma[i + w];
      lapSum += lap;
      lapSqSum += lap * lap;
      n++;
    }
  }
  final lapMean = n == 0 ? 0 : lapSum / n;
  final sharpness = n == 0 ? 0 : lapSqSum / n - lapMean * lapMean;

  return [
    if (mean < PhotoQuality._darkMean) PhotoIssue.tooDark,
    if (clipped / luma.length > PhotoQuality._maxClippedFraction)
      PhotoIssue.tooBright,
    if (sharpness < PhotoQuality._minSharpness) PhotoIssue.blurry,
  ];
}
