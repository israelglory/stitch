# Stitch

A free, open source video editor for iOS and Android. Everything stays on your device: no accounts, no backend, no tracking. The only network access is an optional one-time download of speech recognition models for captions.

Status: early development. See [docs/architecture.md](docs/architecture.md) for how the code is organized [docs/design-system.md](docs/design-system.md) for the design system, [docs/timeline.md](docs/timeline.md) for the editing model, and [docs/engine.md](docs/engine.md) for the native media engine.

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

## Native engine tests

```sh
# Swift engine tests (probe, composition, export) on a simulator
xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RunnerTests/EngineTests

# End to end on a simulator: import, preview, play, export
flutter test integration_test -d <simulator id> --dart-define=STITCH_TEST_MEDIA=$PWD/test_media

# Kotlin engine tests (probe, composition, preview, export) on an emulator or device
cd android && ./gradlew :app:connectedDebugAndroidTest

# End to end on Android: the emulator cannot read host files, so push the media first
adb shell mkdir -p /data/local/tmp/stitch_media
adb push test_media/{large_1440p,rotated_portrait,vfr}.mp4 /data/local/tmp/stitch_media
adb shell chmod -R a+rX /data/local/tmp/stitch_media
flutter test integration_test -d emulator-5554 --dart-define=STITCH_TEST_MEDIA=/data/local/tmp/stitch_media
```

`test_media/` holds the media corpus; `tool/make_test_media.sh` regenerates it.

## Checks

CI runs these on every push and pull request. Run them before opening a PR:

```sh
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --exclude-tags golden
flutter test --tags golden          # macOS only; goldens are generated there
flutter test --tags golden --update-goldens   # after an intended visual change
```

`test/architecture/rules_test.dart` enforces project rules:

- No raw colors, paddings, radii, font sizes, or gaps outside `lib/design/`. Use tokens.
- No Material buttons, sliders, dialogs, text styles, or other icon sets outside `lib/design/`. Use design components.
- No Flutter imports in any `domain/` folder.
- No em dashes in code, docs, or copy.

## License

GPL-3.0. See [LICENSE](LICENSE). Bundled fonts: Inter (SIL Open Font License 1.1) and Lucide (ISC); their licenses are in `assets/licenses/` and shown in the app.

The transitions are modeled on [gl-transitions](https://gl-transitions.com) (MIT). They are written for Stitch; no code is copied.
