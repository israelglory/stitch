# Media engine

The engine plays and exports what the editor describes. Dart owns all editing; the engine is stateless with respect to editing and renders one document.

## Contract

`pigeons/engine_api.dart` defines the bridge. Regenerate after editing:

```sh
dart run pigeon --input pigeons/engine_api.dart
```

That writes `lib/engine/pigeon/engine_api.g.dart`, `ios/Runner/Engine/EngineApi.g.swift`, and the Kotlin file for Android.

**Host calls (Dart to native):**
- `createPreview` returns a Flutter texture id.
- `setDocument(json)` replaces what is previewed and exported.
- `play`, `pause`, and `seek(us, exact)`. A non-exact seek may land up to 100 ms off, which is faster for scrubbing.
- `probe(path)` returns the exact duration, the display size after rotation, fps, and whether the file has sound or HDR video.
- `thumbnails(path, times, maxSize, outDir)` writes filmstrip JPEGs.
- `createProxy(path, out)` writes a 720p copy for preview.
- `capabilities` reports HEVC support and whether 4K is available.
- `startExport(request)` and `cancelExport(id)`.
- `release` frees decoders when leaving the editor.

**Callbacks (native to Dart):**
- `onPlaybackState`, about 30 times a second while playing and on every change.
- `onExportProgress`, `onExportCompleted`, and `onExportFailed(code, message)`.

Error codes are stable. Dart maps them to failure types: `missing_file`, `unsupported_media`, `bad_document`, `export_failed`, and `cancelled`.

## The document

`engineDocumentJson` in `lib/features/editor/application/engine_document.dart` builds this:

```json
{
  "canvas": {"width": 1080, "height": 1920, "frameRate": 30},
  "background": {"type": "solid", "color": 4278190080},
  "media": {"<mediaId>": {"path": "/abs/path.mov", "kind": "video", "proxyPath": "/abs/proxy.mp4"}},
  "composition": { ... ResolvedComposition.toJson() ... }
}
```

The composition is the timeline resolved to absolute microseconds (see `docs/timeline.md`), so the engine does no layout math.

## iOS (`ios/Runner/Engine/`)

**Composition (`CompositionBuilder`):** an `AVMutableComposition`.
- Clips alternate between two video tracks and two audio tracks (A and B), so the clips on either side of a transition overlap.
- Speed uses `scaleTimeRange`. Pitch is kept with the spectral time-pitch algorithm.
- Photos and missing files sit on a bundled one-second black clip stretched over their range. The compositor draws the photo, or black, on top.
- Audio items are packed onto as few tracks as possible. A loop is inserted repeatedly until the video ends.
- An `AVMutableAudioMix` sets volumes, fades, and crossfades during transitions. AVFoundation resamples mismatched sample rates.

**Compositor (`StitchCompositor`):** Core Image on Metal. For each frame it draws, in order:
1. the background: a solid color, or a blurred copy of the clip
2. each clip, turned upright from its rotation flag, fitted or filled, then framed (scale, offset, rotation)

During transitions it mixes the two clips.
- Geometry is computed in canvas pixels, then scaled to the render size, so every resolution frames the same.
- The compositor does not declare HDR support, so AVFoundation tone maps HDR to SDR before frames arrive. Output is Rec. 709.

**Preview (`PreviewPlayer`):** an `AVPlayer` whose frames go to a Flutter texture on every display refresh.
- Seeks are coalesced: while one is running, only the latest target is kept.
- Audio interruptions such as calls pause playback.
- A new document rebuilds the player item and keeps the current position and play state.

**Export (`Exporter`):** an `AVAssetReader` feeds an `AVAssetWriter`.
- This path is used so bitrate, frame rate, and codec can be set exactly.
- Video is H.264 High, or HEVC. Audio is AAC, 48 kHz stereo, 192 kbps.
- The file is written to `*.part.mp4`, then renamed. A cancelled or failed export leaves no file behind.

**Probe, thumbnails, and proxies:** in `MediaTools.swift`. Filmstrip file names use a hash that stays stable across launches, so frames are cached on disk.

## Dart

- `NativeEditorEngine` implements `EditorEngine` over the bridge.
- `FakeEditorEngine` backs tests and platforms without a native engine (Android until M6).
- `Filmstrip` batches frame requests per file and caches them in memory and on disk. The disk cache is capped at 150 MB and pruned at startup.

## Tests

- **Swift:** `ios/RunnerTests/EngineTests.swift` covers probe, composition, export, thumbnails, and proxies. The inputs are the corpus in `test_media/`, which `tool/make_test_media.sh` regenerates:
  - variable frame rate
  - HEVC HDR
  - rotated portrait
  - 44.1 and 48 kHz audio
  - a video with no sound
  - a long clip
  - a 1440p source
  - a still, and MP3, M4A, and WAV files

  Run them with:
  ```sh
  xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner \
    -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RunnerTests/EngineTests
  ```
- **End to end:** `integration_test/editor_flow_test.dart` covers the whole path. It picks from Photos, creates a project, previews, plays, exports, and then probes the export.

## Xcode project

`ruby tool/xcode_sync.rb` adds new files in `ios/Runner/Engine` and `ios/RunnerTests` to their targets, and the test media to the test bundle. It is safe to run repeatedly.

## Deferred

- The audio limiter moves to M8: `AVAudioMix` has no limiter stage.
- Transitions other than crossfade and fade to black come with the shader milestone, M7.
- Text and captions are drawn from M8 and M9.
