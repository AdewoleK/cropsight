# Android setup notes

`flutter create .` generates the full `android/` folder. After that, make these
three changes so on-device inference works.

## 1. Restrict to arm64 (required for Gemma3n `.litertlm`/vision features)

In `android/app/build.gradle`, inside `android { defaultConfig { ... } }`:

```gradle
ndk {
    abiFilters 'arm64-v8a'
}
```

## 2. Declare OpenCL for GPU acceleration

In `android/app/src/main/AndroidManifest.xml`, just above `</application>`:

```xml
<uses-native-library android:name="libOpenCL.so" android:required="false"/>
<uses-native-library android:name="libOpenCL-car.so" android:required="false"/>
<uses-native-library android:name="libOpenCL-pixel.so" android:required="false"/>
```

## 3. Camera + storage

`image_picker` handles most permissions, but confirm your `minSdkVersion` is
24+ in `android/app/build.gradle`. Gemma3n vision wants a device with ~8 GB RAM
for comfortable performance; it will run on less with CPU backend but slower.

## 4. Release builds

flutter_gemma ships its own ProGuard rules. If you hit `UnsatisfiedLinkError`
in a release build, add the rules listed in the flutter_gemma README under
"Android → ProGuard".
