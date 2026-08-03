/// Where the on-device embedding model comes from.
///
/// We use Gecko (110M, 768-dim). Both files ship as bundled native assets (see
/// android/app/src/main/assets/models/) rather than a runtime download.
class EmbeddingCatalog {
  const EmbeddingCatalog._();

  /// Bump if you switch embedding models (forces a re-embed of the KB).
  static const String modelId = 'gecko-110m-en';

  /// Embedding vector length (Gecko and EmbeddingGemma are both 768-dim).
  static const int dimensions = 768;

  /// Bundled native resource names (see android/app/src/main/assets/models/).
  static const String modelFileName = 'Gecko_256_quant.tflite';
  static const String tokenizerFileName = 'sentencepiece.model';
}
