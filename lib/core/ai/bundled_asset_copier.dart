import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Pre-copies a bundled Android asset (see `android/app/src/main/assets/models/`)
/// to the exact path flutter_gemma's own bundled-resource install expects,
/// using a native background thread instead of flutter_gemma's blocking,
/// main-thread copy — which was confirmed to ANR on-device for multi-GB
/// files. See `MainActivity.kt` for the native side and why this exists.
///
/// A no-op if the destination already exists (nothing to do) or on iOS
/// (flutter_gemma reads directly from `Bundle.main` there — no copy needed).
class BundledAssetCopier {
  const BundledAssetCopier._();

  static const _methodChannel = MethodChannel('cropsight/asset_copy');
  static const _progressChannel = EventChannel('cropsight/asset_copy_progress');

  static Future<void> ensureCopied(
    String resourceName, {
    void Function(int percent)? onProgress,
  }) async {
    if (!Platform.isAndroid) return;

    final dir = await getApplicationDocumentsDirectory();
    final destPath = '${dir.path}/$resourceName';
    if (await File(destPath).exists()) return;

    StreamSubscription<dynamic>? subscription;
    if (onProgress != null) {
      subscription = _progressChannel.receiveBroadcastStream().listen((event) {
        if (event is int) onProgress(event);
      });
    }
    try {
      await _methodChannel.invokeMethod('copyAsset', {
        'assetPath': 'models/$resourceName',
        'destPath': destPath,
      });
    } finally {
      await subscription?.cancel();
    }
  }
}
