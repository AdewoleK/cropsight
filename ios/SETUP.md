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
- **Bundled model** — the `Models` group in the Xcode project references the
  same three files Android uses, in place, from
  [`android/app/src/main/assets/models/`](../android/app/src/main/assets/models/README.md)
  (gitignored; fetch them per that README). They're in Runner's **Copy Bundle
  Resources**, which is where `flutter_gemma`'s `.fromBundled()` looks on iOS
  (`Bundle.main`). No copy step is needed, unlike Android's
  `BundledAssetCopier`.

## Verification status

- **iOS Simulator (iPhone 16 Pro, iOS 26):** builds, launches, and completes
  the whole setup flow (model install, embedder load, field-guide indexing),
  ending on the Diagnose screen. That means the bundled-resource path and
  on-device embedding inference both work on iOS.
- **Vision diagnosis on iOS: doesn't work with the current engine.** On the
  Simulator, the photo pass fails at session creation with `No registered
  object with name: LlmVisionInferenceCalculator`: the MediaPipe iOS build
  that `flutter_gemma_mediapipe` ships doesn't include the vision
  calculator. flutter_gemma's docs say iOS vision runs on the LiteRT-LM
  (FFI) engine with a `.litertlm` model, so the fix is to switch the model
  format and engine on iOS. Lite mode and the library work on iOS today.
- **Physical iPhone:** not yet run. Needs a signing team (see below). RAM is
  the same constraint as on Android: an iPhone with 6GB+ (iPhone 13 Pro / 14 /
  15 or newer) is a realistic target. Older 4GB models likely hit the same
  ceiling documented in the main README.

## Running on a physical iPhone

1. Open `ios/Runner.xcworkspace` in Xcode, select the Runner target, go to
   **Signing & Capabilities**, and pick your Team. Change the bundle ID from
   `com.example.cropsight` to something unique.
2. The increased-memory-limit entitlement may require a paid Apple Developer
   account. If a free personal team rejects it, remove it from
   `Runner.entitlements` to get the app installed, but expect large-model
   loading to be more fragile without it.
3. Enable Developer Mode on the phone, connect it, then run `flutter run -d <device>`.
   The first install copies ~3.2GB, so it takes a while.
