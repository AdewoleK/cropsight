import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Decides whether this phone can run photo diagnosis (Gemma3n vision).
///
/// Measured on a real ~3.7GB phone: the vision pass is OOM-killed on GPU and
/// stalls on CPU. The model weights alone are ~2.9GB, so photo diagnosis
/// needs a 6GB-class phone (which reports ~5.5GB usable). Below that, the
/// app runs Lite mode — symptom matching with the small embedder, which is
/// verified working on that same 3.7GB phone.
class DeviceCapability {
  const DeviceCapability._();

  /// 6GB phones report a little under 6GB of usable RAM.
  static const int minRamMbForPhoto = 5500;

  static int? _ramMb;

  /// Total RAM in MB, or null if it couldn't be read.
  static int? get ramMb => _ramMb;

  /// True when photo diagnosis should work. Unknown RAM counts as capable,
  /// so a detection failure never hides the main feature.
  static bool get supportsPhotoDiagnosis =>
      _ramMb == null || _ramMb! >= minRamMbForPhoto;

  static Future<void> load() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        _ramMb = (await info.androidInfo).physicalRamSize;
      } else if (Platform.isIOS) {
        _ramMb = (await info.iosInfo).physicalRamSize;
      }
    } catch (_) {
      _ramMb = null;
    }
  }
}
