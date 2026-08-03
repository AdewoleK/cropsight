# Bundled model assets

This folder is empty in git (see the root `.gitignore` — `*.task`, `*.litertlm`,
`*.bin` are excluded; too large for version control). Before building, place
these three files here yourself:

| File | Source | Notes |
|---|---|---|
| `gemma-3n-E2B-it-int4.task` | https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task | ~3.1GB. Gated — needs a Hugging Face token (see `config.json.example`) and your HF account must have accepted the Gemma3n license on that model page. |
| `Gecko_256_quant.tflite` | https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/Gecko_256_quant.tflite | Public, no token needed. |
| `sentencepiece.model` | https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/sentencepiece.model | Public, no token needed. |

These filenames must exactly match `CropSightModel.fileName`
(`lib/core/ai/model_catalog.dart`) and `EmbeddingCatalog.modelFileName` /
`EmbeddingCatalog.tokenizerFileName` (`lib/core/rag/embedding_catalog.dart`) — the
Dart code references bundled native resources by name, not by declaring them as
Flutter assets in `pubspec.yaml`.

The Hugging Face token is only needed to fetch the gated `.task` file once, on
your machine — the app itself never makes a network call to install these.
