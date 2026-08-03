# iOS setup notes

CropSight is Android-first; iOS support for the bundled model isn't wired up
yet. These are manual steps — safely scripting Xcode project-file edits isn't
reliable, so do this by hand in Xcode when you're ready to build for iOS.

## Bundle the model as a native asset

`flutter_gemma`'s `.fromBundled(resourceName)` resolves the file via
`Bundle.main.path(forResource:)` on iOS, which means the file needs to be added
to the `Runner` target's **Copy Bundle Resources** build phase — not placed in
a plain folder the way Android's `assets/` works.

1. Get the same three files described in
   [`android/app/src/main/assets/models/README.md`](../android/app/src/main/assets/models/README.md)
   (the `.task` model and the two embedder files).
2. Open `ios/Runner.xcworkspace` in Xcode (not the `.xcodeproj` — CocoaPods
   needs the workspace).
3. Drag the three files into the `Runner` group in the project navigator.
   When prompted:
   - Check **"Copy items if needed"**.
   - Under **Add to targets**, check **Runner**.
4. Confirm they show up under Runner's **Build Phases → Copy Bundle
   Resources**.
5. Build/run from Xcode (or `flutter run -d <ios device>`).

## Known gap

The Gemma3n `.task` model is loaded through the MediaPipe engine
(`flutter_gemma_mediapipe`), which supports iOS — but this hasn't been built or
tested on iOS in this repo yet. Expect to hit and fix issues (codesigning,
app size limits for a ~3.1GB bundled binary, MediaPipe's iOS pod
dependencies) the first time this is actually attempted.
