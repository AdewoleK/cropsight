# iOS bundled model

This folder is empty in git (`*.litertlm` is gitignored; too large for version
control). Before building for iOS, place this file here yourself:

| File | Source | Notes |
|---|---|---|
| `gemma-3n-E2B-it-int4.litertlm` | https://huggingface.co/google/gemma-3n-E2B-it-litert-lm/resolve/main/gemma-3n-E2B-it-int4.litertlm | ~3.7GB. Gated — needs a Hugging Face token (see `config.json.example`) and your HF account must have accepted the Gemma3n license on that model page. |

It's the same Gemma3n E2B model Android runs, packaged for the LiteRT-LM
engine instead of MediaPipe. iOS needs this build because MediaPipe's iOS
framework has no vision support (see `../SETUP.md`).

The embedder files (`Gecko_256_quant.tflite`, `sentencepiece.model`) aren't
duplicated here: the Xcode project references them in place from
`android/app/src/main/assets/models/`.

The filename must exactly match `CropSightModel.fileName`
(`lib/core/ai/model_catalog.dart`).
