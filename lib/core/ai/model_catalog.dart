import 'package:flutter_gemma/flutter_gemma.dart';

/// Central definition of the on-device model CropSight runs.
///
/// We use Gemma3n E2B because it is the smallest Gemma variant that supports
/// multimodal (image) input, which is what lets a farmer photograph a leaf and
/// get a diagnosis. It uses [ModelType.gemmaIt] under flutter_gemma's mapping.
///
/// The Gemma3n repo on Hugging Face is gated, so a (free) Hugging Face token is
/// required to download it. See README -> "Hugging Face token" for setup. Once
/// downloaded, the model file lives on the device and no network is ever used
/// again for inference.
class CropSightModel {
  const CropSightModel._();

  /// Filename used on-device once installed.
  static const String fileName = 'gemma-3n-E2B-it-int4.task';

  /// flutter_gemma model type for the Gemma 3 / Gemma3n family.
  static const ModelType modelType = ModelType.gemmaIt;

  /// Multimodal 4-bit Gemma3n E2B in MediaPipe `.task` format (mobile).
  ///
  /// This is a gated Google repo — a Hugging Face token is required to download.
  static const String downloadUrl =
      'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task';

  /// Approximate download size, shown to the user before they commit.
  static const String approxSize = '~3.1 GB';

  /// Max tokens for a single diagnosis turn. Kept modest to bound memory use on
  /// mid-range devices; raise if you target higher-RAM phones.
  static const int maxTokens = 2048;

  /// Gemma3n vision needs more RAM; GPU is preferred where available.
  static const PreferredBackend preferredBackend = PreferredBackend.gpu;
}
