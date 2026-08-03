# CropSight

**Offline crop-disease diagnosis that runs entirely on a phone — no internet, no cloud, no data leaving the device.**

A smallholder farmer photographs a diseased leaf. CropSight names the likely
problem, rates its own confidence, and gives two to four low-cost steps to take
next — all with airplane mode on, on a mid-range Android phone. There is no
server, no API key burning through a budget, and no user photo ever uploaded
anywhere.

Most AI demos quietly assume fast, cheap, always-on connectivity. For the
farmers who would benefit most, that assumption is exactly what is missing.
CropSight is built the other way around: the model, the reasoning, and (soon)
the reference knowledge all live on the device.

---

## Why this is hard (and why it matters)

- **Truly offline inference.** A multimodal language model (Gemma3n) runs
  locally through [`flutter_gemma`](https://pub.dev/packages/flutter_gemma) on
  the LiteRT-LM engine. After a one-time model download, the diagnosis path
  never touches the network.
- **Vision, not just text.** The farmer's input is a photo. The model reads the
  image directly — no separate cloud vision API.
- **Grounded, not guessed.** A vision pass turns the photo into a query, the app
  retrieves matching crop-disease cards from an on-device index, and a second
  pass writes the diagnosis grounded in — and citing — those cards. This is a
  two-pass agentic RAG loop, running entirely on the phone.
- **Private by construction.** The image and the reasoning stay on the phone.
  Only optional, anonymised *results* ever sync — and only when a connection
  happens to be available.

## Architecture

```
On device (works fully offline)
  Capture UI  ──►  Diagnosis controller  ──►  Gemma3n engine (multimodal)
                                          └►  RAG store (embeddings + SQLite)   [Phase 3]
  Local model + knowledge files bundled on device
                                          ┄┄►  Optional sync (results only)     [Phase 4]
```

## Tech stack

- **Flutter** — one codebase, Android first.
- **flutter_gemma 0.15+** — on-device Gemma3n E2B (multimodal), embeddings, and
  a SQLite vector store, all local.
- **Gemma3n E2B** — smallest Gemma variant with image input.
- **provider** — light state management.

## Getting started

> This repo contains the application source (`lib/`), configuration, and setup
> notes. Generate the platform folders and fetch packages on your machine.

1. **Create platform folders** (adds `android/`, `ios/`, etc. around this code):
   ```bash
   flutter create .
   ```
   Then apply the changes in [`android/SETUP.md`](android/SETUP.md).

2. **Add your Hugging Face token** (Gemma3n is a gated model — the token is
   free):
   ```bash
   cp config.json.example config.json
   # paste your token from https://huggingface.co/settings/tokens
   # and request access on the Gemma3n model page
   ```

3. **Fetch packages and run:**
   ```bash
   flutter pub get
   flutter run --dart-define-from-file=config.json
   ```

4. On first launch the app downloads the model once, then drops you into the
   camera. Turn on airplane mode and diagnose a leaf — it still works.

## Roadmap

- [x] **Phase 0 — Foundation:** project, model lifecycle, offline vision
      diagnosis end to end.
- [ ] **Phase 1 — Capture polish:** better prompts, structured result cards,
      retake/confirm flow.
- [ ] **Phase 2 — Bundled model:** ship a smaller model as a native asset so the
      app is offline from first launch, no download step.
- [x] **Phase 3 — On-device RAG:** crop-disease reference cards embedded with an
      on-device embedder, retrieved by cosine similarity, and used to ground a
      two-pass diagnosis that cites its sources.
- [ ] **Phase 4 — Opportunistic sync:** queue anonymised results and sync when a
      connection appears; simple agronomist dashboard.
- [ ] **Phase 5 — Field demo:** recorded airplane-mode walkthrough and writeup.

## Privacy

The photo and the diagnosis never leave the phone. Any future sync is
opt-in and carries results only — never the image, never the raw inference.

## License

MIT.
