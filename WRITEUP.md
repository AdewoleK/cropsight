# CropSight — writeup

## The problem

Most AI demos quietly assume fast, cheap, always-on connectivity. More than
60% of Sub-Saharan Africa's population depends on smallholder farming for
their livelihood, frequently in places where that assumption simply doesn't
hold — signal is patchy, data is expensive relative to income, or both.
CropSight is built the other way around: a smallholder farmer photographs a
diseased leaf, and the entire pipeline — vision, retrieval, reasoning — runs
on the phone in their hand, with airplane mode on.

## What it does

1. Farmer photographs a leaf.
2. An on-device multimodal model (Gemma3n E2B, via
   [`flutter_gemma`](https://pub.dev/packages/flutter_gemma)) looks at the
   photo and produces a short candidate description (crop + visible
   symptoms) — this is the retrieval query, not the final answer.
3. That description is embedded on-device and matched by cosine similarity
   against a small, hand-authored knowledge base of crop-disease reference
   cards (`lib/core/rag/knowledge_base.dart`) — a two-pass, agentic RAG loop
   running entirely locally.
4. A second model pass writes the actual diagnosis, instructed to ground
   itself *only* in the retrieved cards and to cite them — this is what makes
   the answer something more than a plausible-sounding guess.
5. The result renders as distinct cards — crop, a confidence badge with its
   reasoning, 2-4 concrete low-cost next steps, and the cited sources with
   their match scores — not a wall of text.
6. If (and only if) a connection is ever available, an anonymised summary of
   which reference cards matched can sync out — never the photo, never the
   free-text diagnosis.

## Why each piece was hard

- **Bundling a 3.1GB vision model with no download step.** There is no small,
  vision-capable Gemma3n variant — E2B is already the smallest Gemma3n
  release with image input, and `flutter_gemma`'s own docs recommend its
  bundled-native-asset mechanism only for much smaller (sub-600MB) models. We
  bundled the full model anyway (native Android asset, not a Flutter asset —
  `fromBundled(...)`, not `fromAsset(...)`), accepting the app-size cost to
  keep vision capability rather than degrade the core feature or gamble on an
  unverified smaller model family mid-build.
- **Grounded, not guessed.** A single model pass over a photo will produce a
  fluent, confident-sounding answer whether or not it's actually right. The
  two-pass split — describe, retrieve, *then* answer strictly from what was
  retrieved — is what lets the app say "I'm not sure, here's why, get a
  second opinion" instead of confabulating a disease name.
- **Privacy that survives contact with a real sync feature.** It's easy to
  promise "anonymised results only" and then accidentally sync the whole
  free-text diagnosis because that's the only structured-ish thing lying
  around. The sync payload was deliberately scoped to the minimum: an
  install-local random ID, a timestamp, and which reference cards matched —
  the photo and the model's own words never leave the local on-device record.
- **Being honest about what "affordable hardware" actually means.** It's
  tempting to claim this runs great on the cheapest phone available; it
  doesn't, and that claim wouldn't survive scrutiny. Gemma3n's vision path
  wants a GPU and roughly 8GB of RAM for comfortable latency — closer to a
  mid-range device than the very cheapest entry-level ones on the market
  today. It still runs on less via the CPU backend, just slower. That
  tradeoff is stated plainly rather than glossed over.
- **Making an on-device model's output UI-renderable.** Small local models
  don't reliably emit valid JSON, so structured result cards come from a
  forgiving line-based parser (`lib/features/diagnosis/structured_diagnosis.dart`)
  over a simple labeled-line prompt format, with a raw-text fallback if the
  model doesn't follow the format — verified with unit tests
  (`test/structured_diagnosis_test.dart`) since the model itself couldn't be
  exercised in every environment this was built in.
- **A real crash, found only by actually running on hardware.** `flutter_gemma`'s
  own bundled-asset install copies the file on the Android platform thread —
  fine for the small models its own examples ship, an ANR for a ~2.9GB one.
  Confirmed on a real device: Android wrote a tombstone and killed the app
  mid-copy. Still present in the latest release (1.5.2 at the time), so not a
  version bump away. Fixed by reverse-engineering the plugin's own
  file-existence check and beating it to the punch: a small native
  MethodChannel (`MainActivity.kt`) copies the same asset on a background
  thread first — to a `.part` file, atomically renamed only once complete, so
  an interrupted copy can never masquerade as a finished one — landing it
  exactly where the plugin expects to find it already done. No static
  analysis or emulator would have caught this; it only showed up running the
  real ~2.9GB file on real, non-flagship hardware.

## Architecture

```
On device (works fully offline)
  Capture UI → retake/confirm → Diagnosis controller
                                    ├─► Gemma3n E2B (vision pass: describe)
                                    ├─► On-device RAG (embed + cosine match
                                    │     against bundled knowledge cards)
                                    └─► Gemma3n E2B (grounded, cited answer)
                                          → parsed into structured result cards

  Local model + embedder + knowledge cards, all bundled — no download step

Opportunistic (only if configured, only if online)
  Local sync queue → connectivity-triggered flush → anonymised payload only
```

## Status against the roadmap

- **Phase 0 — Foundation:** done. Offline vision diagnosis end to end.
- **Phase 1 — Capture polish:** done. Labeled-line prompt + parser + structured
  result cards; retake/confirm flow before running a diagnosis.
- **Phase 2 — Bundled model:** done, verified on real hardware. Model/embedder
  install from bundled native assets, no runtime download — confirmed reaching
  the working Diagnosis screen on a physical Android phone with the real
  ~2.9GB model bundled, after finding and fixing the ANR bug above.
- **Phase 3 — On-device RAG:** done.
- **Phase 4 — Opportunistic sync:** code-complete, not yet exercised against a
  real sync target. Local queue, connectivity detection, pluggable sync
  target (disabled unless configured), in-app status screen standing in for
  a dashboard until a real backend exists.
- **Phase 5 — Field demo:** this writeup, plus `DEMO.md`'s recording script.
  The actual recording is the one thing that has to happen by hand, on a real
  phone — see `DEMO.md`.

This is a personal project, built and shared as a portfolio piece — not
heading for the Play Store or App Store. Distributed as a direct APK install
(`flutter build apk` → sideload/`adb install`).

## What's next / known gaps

- No real backend exists for sync yet — `SyncTarget` is pluggable specifically
  so one can be wired in later without touching the queueing/connectivity
  logic.
- iOS bundling is documented (`ios/SETUP.md`) but not implemented — this repo
  is Android-first, and the manual Xcode steps haven't actually been
  exercised.
