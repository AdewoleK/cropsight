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

## Verification status — read this before the rest

Stated plainly, once, rather than hedged throughout: on the one physical
device available for testing (~3.7GB RAM), the app builds, installs, and
completes its fully-offline first-launch setup (bundling the model and
embedder with no network call, then indexing the on-device knowledge base) —
all verified working, including finding and fixing a real crash along the
way (see `WRITEUP.md`). **The vision-inference step itself — the core
"photograph a leaf, get a diagnosis" loop — has not been observed completing
on that device.** Gemma3n E2B's vision path needs more RAM than ~3.7GB has to
give on either the GPU backend (gets OOM-killed) or CPU backend (stalls
indefinitely instead). This is a hardware ceiling, measured and documented,
not a bug being hidden — see the roadmap and `WRITEUP.md` for the numbers.
No higher-RAM device was available to finish that verification.

Two updates since then:
- **Lite mode** gives low-memory phones a working path. The farmer taps what
  they see, and the small on-device embedder (the part verified on that
  3.7GB phone) matches it against the 116-entry field guide. The app picks
  Photo or Lite automatically from the phone's RAM.
- **iOS photo diagnosis doesn't work with the current MediaPipe engine.** Its
  iOS build lacks the vision calculator; see `ios/SETUP.md`. Fixing it means
  moving iOS to the LiteRT-LM engine and a `.litertlm` model.

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
- **Honest about the hardware tradeoff — measured, not guessed.** Tested on a
  real ~3.7GB-RAM Android phone: the GPU backend gets the app killed by
  Android's low-memory killer mid-inference; the CPU backend avoids the kill
  but stalls (thrashing, not progressing) rather than actually completing.
  The model's weights alone are ~2.9GB — a phone needs meaningfully more RAM
  than that once the OS and other apps are accounted for. This targets real,
  affordable Android hardware, not a flagship, but "affordable" here still
  means something in the 6-8GB range, not the cheapest phone on the shelf.

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
   you into the camera. No network call happens at any point after that,
   verified with airplane mode on from before install. **A device with at
   least ~6-8GB RAM is required** — see the hardware note above; on a lower-RAM
   device, setup completes but the vision pass itself will stall or get
   killed by the OS.

## Roadmap

Code-complete on every phase below. Live, on-device verification covers
everything *except* the vision-inference step itself — see "Verification
status" above for exactly what that means and why.

- [x] **Phase 0 — Foundation:** model lifecycle and the offline pipeline are
      built and wired end to end; the vision-inference step within it is the
      one thing not yet observed completing (hardware, not code — see above).
- [x] **Phase 1 — Capture polish:** better prompts, structured result cards,
      retake/confirm flow. The parser is unit-tested against synthetic model
      output (`test/structured_diagnosis_test.dart`); not yet seen against a
      real generated answer, for the same reason.
- [x] **Phase 2 — Bundled model:** ship the model as a native asset so the app
      is offline from first launch, no download step. The bundling mechanism
      itself is verified on real hardware, including finding and fixing a
      real ANR bug along the way (see `WRITEUP.md`).
- [x] **Phase 3 — On-device RAG:** crop-disease reference cards embedded with
      an on-device embedder, retrieved by cosine similarity, and used to
      ground a two-pass diagnosis that cites its sources. Fully verified —
      the embedder is a small model (~110MB) that runs fine even on the
      constrained test device.
- [x] **Phase 4 — Opportunistic sync:** queue anonymised results and sync when
      a connection appears; simple agronomist dashboard. Code-complete and
      unit-verified; not exercised against a live diagnosis end-to-end, since
      there's been no completed diagnosis yet to queue.
- [x] **Phase 5 — Field demo:** writeup done ([`WRITEUP.md`](WRITEUP.md)). The
      recorded airplane-mode walkthrough ([`DEMO.md`](DEMO.md) has the script,
      ready whenever suitable hardware is) is deliberately deferred rather
      than faked.

## Privacy

The photo and the diagnosis never leave the phone. Any future sync is
opt-in and carries results only — never the image, never the raw inference.

## License

MIT.
