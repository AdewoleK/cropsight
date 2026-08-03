/// Where the on-device embedding model comes from.
///
/// We use Gecko (110M, 768-dim), which is public on Hugging Face and needs no
/// auth token, keeping onboarding simple. flutter_gemma's embedder needs two
/// files: the model (.tflite) and its SentencePiece tokenizer (.model).
///
/// IMPORTANT: confirm the exact filenames on the model repo and paste the real
/// `resolve/main/...` URLs below. Browse the files here:
///   https://huggingface.co/litert-community/Gecko-110m-en/tree/main
/// The two placeholders are the only thing standing between this and a run.
class EmbeddingCatalog {
  const EmbeddingCatalog._();

  /// Bump if you switch embedding models (forces a re-embed of the KB).
  static const String modelId = 'gecko-110m-en';

  /// Embedding vector length (Gecko and EmbeddingGemma are both 768-dim).
  static const int dimensions = 768;

  // TODO(you): replace with the exact file URLs from the repo tree above.
  static const String modelUrl =
      'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/Gecko_256_quant.tflite';
  static const String tokenizerUrl =
      'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/sentencepiece.model';

  /// Gecko is public; no token required. Set if you switch to EmbeddingGemma.
  static const String? token = null;
}
