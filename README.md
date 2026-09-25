# Stitch

A free, open source video editor for iOS and Android. Everything stays on your device: no accounts, no backend, no tracking. The only network access is an optional one-time download of speech recognition models for captions.

Status: early development. See [docs/architecture.md](docs/architecture.md) for how the code is organized, [docs/design-system.md](docs/design-system.md) for the design system, [docs/timeline.md](docs/timeline.md) for the editing model, and [docs/engine.md](docs/engine.md) for the native media engine.

## Requirements

- Flutter 3.47 (stable), Dart 3.13
- iOS 16 or later, Android 8.0 (API 26) or later
- Xcode 26 and Android Studio with JDK 17 for native builds

## Getting started

```sh
flutter pub get
flutter run
```

Generated code (Riverpod providers, freezed models, localizations) is committed. After changing an annotated file or an ARB file, regenerate:

```sh
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

iOS uses Swift Package Manager for plugins; CocoaPods is not needed.

Speech recognition (whisper.cpp) is compiled from source by a Dart build hook (`hook/build.dart`) as part of every build, for each target; the first build takes a minute or two longer. Android needs the NDK, which the Android Gradle plugin installs. See [docs/captions.md](docs/captions.md).

## Native engine tests

```sh
# Swift engine tests (probe, composition, export) on a simulator
xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RunnerTests/EngineTests

# End to end on a simulator: import, preview, play, export, captions.
# The export test saves to Photos; grant access first so no prompt waits.
xcrun simctl privacy <simulator id> grant photos-add xyz.gloryolaifa.stitch
flutter test integration_test -d <simulator id> --dart-define=STITCH_TEST_MEDIA=$PWD/test_media

# Kotlin engine tests (probe, composition, preview, export) on an emulator or device
cd android && ./gradlew :app:connectedDebugAndroidTest

# End to end on Android: the emulator cannot read host files, so push the media first
adb shell mkdir -p /data/local/tmp/stitch_media
adb push test_media/{large_1440p,rotated_portrait,speech,vfr}.mp4 /data/local/tmp/stitch_media
adb shell chmod -R a+rX /data/local/tmp/stitch_media
flutter test integration_test -d emulator-5554 --dart-define=STITCH_TEST_MEDIA=/data/local/tmp/stitch_media
```

`test_media/` holds the media corpus; `tool/make_test_media.sh` regenerates it.

The end to end tests include captions (`integration_test/captions_test.dart`), which download the tiny caption model (44 MB) on first run. The Dart speech recognition tests run whisper.cpp on your computer and skip until the model is fetched:

```sh
tool/fetch_test_model.sh
flutter test test/features/captions
```

## Checks

CI runs these on every push and pull request. Run them before opening a PR:

```sh
flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs
dart run pigeon --input pigeons/engine_api.dart && dart format lib/engine/pigeon
git status --porcelain              # generated code must already be committed
dart format --set-exit-if-changed lib test integration_test hook
flutter analyze --fatal-infos --fatal-warnings
tool/fetch_test_model.sh            # else the speech recognition tests skip
flutter test --exclude-tags golden
flutter test --tags golden          # macOS only; goldens are generated there
flutter test --tags golden --update-goldens   # after an intended visual change
```

CI also builds a release APK, runs the Kotlin and Swift engine tests, and runs the end to end tests on an emulator and a simulator.

`test/architecture/rules_test.dart` enforces project rules:

- No raw colors, paddings, radii, font sizes, or gaps outside `lib/design/`. Use tokens.
- No Material buttons, sliders, dialogs, text styles, or other icon sets outside `lib/design/`. Use design components.
- No Flutter imports in any `domain/` folder.
- No em dashes in code, docs, or copy.

## Release builds

Android release builds are signed with the key described in `android/key.properties` (not committed):

```properties
storeFile=/path/to/stitch.jks
storePassword=...
keyAlias=stitch
keyPassword=...
```

Without that file the release build falls back to the debug key and prints a warning. The app icon is drawn from code; `tool/make_icons.sh` regenerates every iOS and Android size.

## F-Droid

Stitch is built to meet F-Droid's inclusion policy: no proprietary libraries, no Google Play Services, no analytics, and every bundled asset is open (see below). Notes for reviewers:

- **Native code.** whisper.cpp is built from source in `third_party/whisper.cpp` by the Dart build hook (`hook/build.dart`), using the NDK's clang. There is no CMake or prebuilt binary. The NDK version is Flutter's default (`flutter.ndkVersion`, currently 28.2.13676358). Build paths are mapped out of the binary (`-ffile-prefix-map`), so builds are reproducible across machines.
- **Network.** The only network access is the optional caption model download, started by the user from the captions tool. Models come from Hugging Face (`huggingface.co/ggerganov/whisper.cpp`) at a pinned revision and are checked against a SHA-256 before use. They are OpenAI's Whisper weights (MIT). Nothing else is sent or fetched.
- **Anti-features.** None expected. The model download could be seen as `NonFreeNet` only if the host is considered a non-free service; the files themselves are free.

## Known limitations

- Android: swiping the app away from Recents stops a running export (the foreground service goes with the task).
- iOS: transitions render slightly soft in 4K exports.
- Tablets ignore the portrait lock; the editor layout works in both orientations but is designed for portrait.
- Android: 10-bit (HDR) clips are shown without tone mapping in the frame handed to transitions, so they look flat there.

## License

GPL-3.0. See [LICENSE](LICENSE). Bundled assets, with licenses in `assets/licenses/` (also shown in the app):

- Fonts: Inter, Anton, Bebas Neue, DM Serif Display, Pacifico, and Space Mono (SIL Open Font License 1.1); Lucide icons (ISC).
- Music: eight tracks by Komiku, Loyalty Freak Music, and Lack of Color, under CC0 (sources in `assets/licenses/music.txt`).
- Sound effects: Kenney's Interface Sounds, Impact Sounds, and Music Jingles, under CC0.
- Speech recognition: [whisper.cpp](https://github.com/ggml-org/whisper.cpp) v1.9.4 (MIT), vendored in `third_party/whisper.cpp` and built from source. The caption models are OpenAI's Whisper models (MIT), downloaded on first use and not bundled.

The transitions are modeled on [gl-transitions](https://gl-transitions.com) (MIT). They are written for Stitch; no code is copied.
