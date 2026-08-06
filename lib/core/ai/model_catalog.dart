import 'package:flutter_gemma/flutter_gemma.dart';

/// Central definition of the on-device model CropSight runs.
///
/// We use Gemma3n E2B because it is the smallest Gemma variant that supports
/// multimodal (image) input, which is what lets a farmer photograph a leaf and
/// get a diagnosis. It uses [ModelType.gemmaIt] under flutter_gemma's mapping.
///
/// The model file ships as a bundled native asset (see
/// android/app/src/main/assets/models/) rather than a runtime download, so the
/// app never needs network access to install it.
class CropSightModel {
  const CropSightModel._();

  /// Filename on-device — also the bundled native resource name (see
  /// android/app/src/main/assets/models/).
  static const String fileName = 'gemma-3n-E2B-it-int4.task';

  /// flutter_gemma model type for the Gemma 3 / Gemma3n family.
  static const ModelType modelType = ModelType.gemmaIt;

  /// Max tokens for a single diagnosis turn. Kept modest to bound memory use on
  /// mid-range devices; raise if you target higher-RAM phones.
  static const int maxTokens = 2048;

  /// GPU delegates carry extra memory overhead (compiled kernels, texture
  /// buffers) on top of the base model weights — CPU is the safer default
  /// on memory-constrained devices, at the cost of speed. Confirmed on a
  /// real ~3.7GB-RAM device: GPU backend got the app killed by Android's
  /// low-memory killer mid-inference ("memavailable critical lower").
  static const PreferredBackend preferredBackend = PreferredBackend.cpu;
}
