# iOS setup notes

The iOS target is wired up and builds. Requires iOS 16+ (MediaPipe GenAI's
minimum).

## What's configured

- **Podfile** — `platform :ios, '16.0'` and `use_frameworks! :linkage => :static`
  (both required by `flutter_gemma`).
- **Deployment target** — 16.0 in `Runner.xcodeproj`. Flutter's generated Swift
  package picks this up on the next build; if a first build complains that
  `flutter-gemma` needs 16.0 but the target supports 13.0, just build again.
- **Info.plist** — camera and photo-library usage strings (`image_picker`
  crashes without them), plus `UIFileSharingEnabled`.
- **`Runner/Runner.entitlements`** — `increased-memory-limit` and
  `extended-virtual-addressing`, so iOS lets a ~3GB model stay resident.
- **Bundled model** — iOS runs the LiteRT-LM (`.litertlm`) build of Gemma3n
  E2B, not the MediaPipe `.task` build Android uses: MediaPipe's iOS framework
  has no vision calculator, so photos can't be diagnosed with it. Fetch the
  file into [`Models/`](Models/README.md) (gitignored). The `Models` group in
  the Xcode project references it there, plus the embedder files in place from
  [`android/app/src/main/assets/models/`](../android/app/src/main/assets/models/README.md).
  All three are in Runner's **Copy Bundle Resources**, which is where
  `flutter_gemma`'s `.fromBundled()` looks on iOS (`Bundle.main`). No copy
  step is needed, unlike Android's `BundledAssetCopier`.
- **GPU backend** — the `.litertlm` build marks its vision encoder GPU-only,
  and LiteRT-LM runs vision on the main backend, so iOS uses
  `PreferredBackend.gpu` (CPU fails with "Vision backend constraint
  mismatch"). See `CropSightModel.preferredBackend`.

## Verification status

- **iOS Simulator (iPhone 16 Pro, iOS 26):** builds, launches, and completes
  the whole setup flow (model install, embedder load, field-guide indexing),
  ending on the Diagnose screen. Lite mode and the library work.
- **Photo diagnosis on the Simulator: gets most of the way, then the Simulator
  hangs.** With the `.litertlm` model on the GPU backend, the photo pass
  completes and returns a real description of the leaf (on the tomato early
  blight test photo: "circular brown spots with concentric rings"; it guessed
  the crop as tobacco), retrieval runs, and the answer starts streaming at
  ~12 tokens/s. After ~20 tokens the inference thread blocks inside
  `MTLSimDriver` (the Simulator's emulated Metal) and the UI stops drawing.
  flutter_gemma's docs say the Simulator can't run `.litertlm` on the GPU,
  so this is expected there; it says nothing yet about a real iPhone.
- **Relaunch fix:** flutter_gemma only remembers the active model across
  launches when its file is in app documents, which isn't true for iOS
  bundled models. `GemmaService` and `EmbeddingService` now re-register the
  model before use if it was forgotten. Before this, every iOS relaunch after
  the first failed with "No active inference model set".
- **Physical iPhone:** not yet run. That's the remaining check for photo
  diagnosis on iOS. Needs a signing team (see below) and an iPhone with 6GB+
  RAM (iPhone 13 Pro / 14 / 15 or newer). Older 4GB models likely hit the
  same ceiling documented in the main README.

## Running on a physical iPhone

1. Open `ios/Runner.xcworkspace` in Xcode, select the Runner target, go to
   **Signing & Capabilities**, and pick your Team. Change the bundle ID from
   `com.example.cropsight` to something unique.
2. The increased-memory-limit entitlement may require a paid Apple Developer
   account. If a free personal team rejects it, remove it from
   `Runner.entitlements` to get the app installed, but expect large-model
   loading to be more fragile without it.
3. Enable Developer Mode on the phone, connect it, then run `flutter run -d <device>`.
   The first install copies ~3.8GB, so it takes a while.
