# Phase 5 — Field demo script

**Status: deferred, not abandoned.** This hasn't been recorded yet — the one
physical Android device available for testing (~3.7GB RAM) can't run
Gemma3n E2B's vision inference (see `README.md`'s "Verification status" and
`WRITEUP.md` for the measured numbers). This script is ready to run the
moment a device with ~6-8GB+ RAM is available; nothing below has been
exercised for real yet.

A step-by-step checklist for recording the airplane-mode walkthrough. This is
the one part of the roadmap that has to happen on a real phone, in your own
hands — nothing here can be scripted or automated.

## Before you hit record

- [ ] The bundled model files are in `android/app/src/main/assets/models/`
      (see that folder's `README.md`) and the app has been built with them —
      `flutter build apk --release` (or `--debug` is fine for a demo) and
      installed on the phone you're filming with.
- [ ] Launch the app **once** with Wi-Fi/data on first, so the one-time setup
      (copying the bundled model into app storage, indexing the knowledge
      base — described in `lib/features/onboarding/app_setup_screen.dart`)
      completes before you start filming. This step is local-only and doesn't
      need network, but it does take real time on first launch, and a good
      demo skips dead air.
- [ ] Fully close the app.
- [ ] Have a real (or printed/on-screen) photo of a diseased leaf ready —
      tomato early blight, maize leaf rust, or whatever your
      `lib/core/rag/knowledge_base.dart` cards actually cover.

## Recording

1. **Show the phone's connectivity is off.** Open Settings → Airplane mode
   on, on camera. This is the whole point — don't skip or fake it.
2. **Launch CropSight.** It should go straight to the camera screen (the
   Diagnosis screen) — no download prompt, no spinner waiting on a network
   call. If you see anything resembling a network wait here, something in
   Phase 2's bundling regressed; don't record over it, fix it first.
3. **Tap the "Offline" icon** in the app bar to show the explicit "runs
   entirely on your phone" message — a small but concrete moment of proof.
4. **Take or pick the leaf photo.** You'll land on the retake/confirm screen
   (Phase 1) — show that beat: "Retake" vs "Diagnose."
5. **Tap Diagnose.** Narrate the three visible stages as they happen:
   "Looking at the photo…" → "Checking the field guide…" → "Writing the
   diagnosis…" — this is the two-pass RAG loop from `gemma_service.dart` /
   `rag_service.dart`, running with the radio off.
6. **Show the structured result.** Crop chip, confidence badge with the
   reason, the numbered "What to do now" steps, and the cited source cards
   with their similarity scores underneath.
7. **Tap the cloud icon** to open Sync status. With airplane mode still on,
   the diagnosis you just ran should show up **Pending** — proof the sync
   queue captured it locally without touching the network.
8. *(Optional, only if you've configured `SYNC_ENDPOINT`.)* Turn Wi-Fi back
   on, come back to Sync status, and either wait for it to flip to **Synced**
   automatically or tap "Sync now." If you're demoing this part, point the
   endpoint at a scratch inspector (e.g. a fresh https://webhook.site URL) so
   you can also show the payload it received — call out on camera that it's
   only `anonymous_id` + `timestamp` + which reference cards matched, never
   the photo or the diagnosis text.
9. **Stop recording.**

## What NOT to show (on purpose)

Per the privacy stance in `README.md`, there's nothing to hide, but be
deliberate that the demo never implies the photo left the phone — don't cut to
a "cloud dashboard with your photo on it" shot, because that shot doesn't
exist and shouldn't.

## After recording

- [ ] Trim to the actual walkthrough — dead air during model loading on first
      launch is the one part you set up ahead of time specifically to avoid.
- [ ] Pair the recording with `WRITEUP.md` for the written half of Phase 5.
