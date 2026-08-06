# CropSight

**Offline crop-disease diagnosis that runs entirely on a phone — no internet, no cloud, no data leaving the device.**

A smallholder farmer photographs a diseased leaf. CropSight names the likely
problem, rates its own confidence, and gives two to four low-cost steps to take
next — all with airplane mode on, on a mid-range Android phone. There is no
server, no API key burning through a budget, and no user photo ever uploaded
anywhere.

Most AI demos quietly assume fast, cheap, always-on connectivity — a safe bet
in a well-connected office, and exactly the assumption that fails for the more
than 60% of Sub-Saharan Africa's population whose livelihoods run through
smallholder farming, frequently in places where signal is patchy or absent
altogether. CropSight is built the other way around: the model, the reasoning,
and the reference knowledge all live on the device, so the one constraint that
breaks most AI products is the one this is designed around from the ground up.

---

## Why this is hard (and why it matters)

- **Truly offline inference.** A multimodal language model (Gemma3n) runs
  locally through [`flutter_gemma`](https://pub.dev/packages/flutter_gemma) on
  the MediaPipe engine. The model ships bundled as a native asset, so the app
  never touches the network to install it — offline from the very first
  launch.
- **Vision, not just text.** The farmer's input is a photo. The model reads the
  image directly — no separate cloud vision API.
- **Grounded, not guessed.** A vision pass turns the photo into a query, the app
  retrieves matching crop-disease cards from an on-device index, and a second
  pass writes the diagnosis grounded in — and citing — those cards. This is a
  two-pass agentic RAG loop, running entirely on the phone.
- **Private by construction.** The image and the reasoning stay on the phone.
  Only optional, anonymised *results* ever sync — and only when a connection
  happens to be available.
- **Honest about the hardware tradeoff.** Gemma3n's vision path is memory-
  hungry — comfortable latency wants a GPU and roughly 8GB of RAM. It still
  runs on cheaper devices via the CPU backend, just slower. Stated plainly
  here rather than glossed over: this targets real, affordable Android
  hardware, not a flagship, and the tradeoff that comes with that is real.

## Architecture

```
On device (works fully offline)
  Capture UI → retake/confirm → Diagnosis controller
                                    ├─► Gemma3n E2B (vision pass: describe)
                                    ├─► On-device RAG (embed + cosine match
                                    │     against bundled knowledge cards)
                                    └─► Gemma3n E2B (grounded, cited answer)
                                          → parsed into structured result cards

  Model + embedder + knowledge cards all bundled as native assets — no
  download step, offline from the very first launch

Opportunistic (only if configured, only if online)
  Local sync queue → connectivity-triggered flush → anonymised payload only
```

The RAG index is deliberately plain Dart cosine similarity over cached
embeddings, not a native vector database — at a few dozen short reference
cards it's instant and dependency-free, and easy to swap for something like
`flutter_gemma_rag_sqlite` if the knowledge base grows large enough to need it.

## Tech stack

- **Flutter** — one codebase, Android first.
- **flutter_gemma 1.5+** (with `flutter_gemma_mediapipe` and
  `flutter_gemma_embeddings`) — on-device Gemma3n E2B (multimodal) and
  embeddings, all local.
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

2. **Place the bundled model files.** The model and embedder ship as native
   assets, not a runtime download — see
   [`android/app/src/main/assets/models/README.md`](android/app/src/main/assets/models/README.md)
   for the exact files and sources (one of them, the Gemma3n model, is gated on
   Hugging Face and needs a free token + license acceptance to fetch once;
   `config.json.example` is still there for that one-time fetch, but the app
   itself never needs it at runtime).

3. **Fetch packages and run:**
   ```bash
   flutter pub get
   flutter run
   ```

4. First launch does a one-time, fully-local setup (no network) — copying the
   bundled model into app storage and indexing the knowledge base — then drops
   you into the camera. Turn on airplane mode before you even install it and
   diagnose a leaf — it still works.

## Roadmap

- [x] **Phase 0 — Foundation:** project, model lifecycle, offline vision
      diagnosis end to end.
- [x] **Phase 1 — Capture polish:** better prompts, structured result cards,
      retake/confirm flow.
- [ ] **Phase 2 — Bundled model:** ship the model as a native asset so the app
      is offline from first launch, no download step. Code-complete; blocked
      on placing the actual (large, gated) model file — see
      [`android/app/src/main/assets/models/README.md`](android/app/src/main/assets/models/README.md).
- [x] **Phase 3 — On-device RAG:** crop-disease reference cards embedded with an
      on-device embedder, retrieved by cosine similarity, and used to ground a
      two-pass diagnosis that cites its sources.
- [ ] **Phase 4 — Opportunistic sync:** queue anonymised results and sync when a
      connection appears; simple agronomist dashboard. Code-complete (in-app
      dashboard, not a separate product yet); real end-to-end verification
      needs the same model file as Phase 2 plus, optionally, a `SYNC_ENDPOINT`.
- [ ] **Phase 5 — Field demo:** recorded airplane-mode walkthrough and writeup.
      Writeup done ([`WRITEUP.md`](WRITEUP.md)); recording script ready
      ([`DEMO.md`](DEMO.md)) — the recording itself is a manual step.

## Privacy

The photo and the diagnosis never leave the phone. Any future sync is
opt-in and carries results only — never the image, never the raw inference.

## License

MIT.
