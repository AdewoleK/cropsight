import 'dart:typed_data';

import 'package:cropsight/core/ai/photo_quality.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Encodes a synthetic 640x480 photo whose pixel brightness is [luma](x, y).
Uint8List _photo(int Function(int x, int y) luma) {
  final image = img.Image(width: 640, height: 480);
  for (final px in image) {
    final v = luma(px.x, px.y).clamp(0, 255);
    px
      ..r = v
      ..g = v
      ..b = v;
  }
  return img.encodeJpg(image, quality: 95);
}

/// 16px checkerboard between [lo] and [hi] — lots of hard edges.
int Function(int, int) _checker(int lo, int hi) =>
    (x, y) => ((x ~/ 16) + (y ~/ 16)).isEven ? lo : hi;

void main() {
  test('a sharp, well-exposed photo has no issues', () async {
    expect(await PhotoQuality.check(_photo(_checker(60, 200))), isEmpty);
  });

  test('a smooth gradient with no edges is flagged blurry', () async {
    final issues = await PhotoQuality.check(_photo((x, _) => 80 + x ~/ 8));
    expect(issues, [PhotoIssue.blurry]);
  });

  test('a dark photo is flagged too dark', () async {
    final issues = await PhotoQuality.check(_photo(_checker(5, 60)));
    expect(issues, contains(PhotoIssue.tooDark));
    expect(issues, isNot(contains(PhotoIssue.blurry)));
  });

  test('a mostly clipped-white photo is flagged washed out', () async {
    final issues = await PhotoQuality.check(
        _photo((x, y) => x < 480 ? 255 : _checker(60, 200)(x, y)));
    expect(issues, contains(PhotoIssue.tooBright));
  });

  test('undecodable bytes report no issues rather than throwing', () async {
    expect(await PhotoQuality.check(Uint8List.fromList([1, 2, 3])), isEmpty);
  });
}
