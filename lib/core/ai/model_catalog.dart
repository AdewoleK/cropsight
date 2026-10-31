import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';

/// Central definition of the on-device model CropSight runs.
///
/// We use Gemma3n E2B because it is the smallest Gemma variant that supports
/// multimodal (image) input, which is what lets a farmer photograph a leaf and
/// get a diagnosis. It uses [ModelType.gemmaIt] under flutter_gemma's mapping.
///
/// The model file ships as a bundled native asset (see
/// android/app/src/main/assets/models/ and ios/Models/) rather than a runtime
/// download, so the app never needs network access to install it.
///
/// Same model, two packagings: Android runs the MediaPipe `.task` build; iOS
/// runs the LiteRT-LM `.litertlm` build, because the MediaPipe iOS framework
/// ships without the vision calculator (`LlmVisionInferenceCalculator`), so
/// photo diagnosis can't run on it there.
class CropSightModel {
  const CropSightModel._();

  /// Filename on-device — also the bundled native resource name (see
  /// android/app/src/main/assets/models/ and ios/Models/).
  static String get fileName => Platform.isIOS
      ? 'gemma-3n-E2B-it-int4.litertlm'
      : 'gemma-3n-E2B-it-int4.task';

  /// Which engine runs [fileName]: LiteRT-LM on iOS, MediaPipe elsewhere.
  static ModelFileType get fileType =>
      Platform.isIOS ? ModelFileType.litertlm : ModelFileType.task;

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
  ///
  /// iOS has no choice: the `.litertlm` build's vision encoder is marked
  /// GPU-only, and LiteRT-LM runs vision on the main backend, so CPU fails
  /// with "Vision backend constraint mismatch". The Simulator can't run it
  /// (Metal there caps single allocations at 256MB), so photo diagnosis on
  /// iOS can only be checked on a physical iPhone.
  static PreferredBackend get preferredBackend =>
      Platform.isIOS ? PreferredBackend.gpu : PreferredBackend.cpu;
}
