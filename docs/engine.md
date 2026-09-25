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

## Transitions

Each transition is a shader in the style of [gl-transitions](https://gl-transitions.com) (MIT): it gets the outgoing frame, the incoming frame, and the progress `p`, which runs linearly from 0 to 1 over the transition. Coordinates `(x, y)` run from 0 to 1 across the canvas, from the bottom left. Both frames are whole canvases: each clip placed over its own background.

| Type | Color at (x, y) |
|---|---|
| Crossfade | outgoing and incoming mixed: `mix(from, to, p)` |
| Fade to black | `from` darkening to black until halfway, then black brightening into `to` |
| Slide left | both frames move left by `p`: `from(x + p)` where `x < 1 - p`, else `to(x - (1 - p))` |
| Slide right | both frames move right by `p`: `from(x - p)` where `x >= p`, else `to(x + (1 - p))` |
| Wipe left | `to` where `x >= 1 - p` (revealed from the right edge), else `from` |
| Wipe right | `to` where `x < p` (revealed from the left edge), else `from` |
| Zoom in | `from` scaled up by `1 + 0.6p` about the center, mixed into `to` by `p` |

The shaders are `TransitionShader.kt` (GLSL) on Android and the Metal source in `Transitions.swift` on iOS. `test_media/transition_cases.json` lists expected colors for all seven types at three progress points and four positions, generated from the table above. Both platforms' tests render every case and compare. The looping previews in the Transitions sheet (`TransitionPreview`) follow the same definitions.

## iOS (`ios/Runner/Engine/`)

**Composition (`CompositionBuilder`):** an `AVMutableComposition`.
- Clips alternate between two video tracks and two audio tracks (A and B), so the clips on either side of a transition overlap.
- Speed uses `scaleTimeRange`. Pitch is kept with the spectral time-pitch algorithm.
- Photos and missing files sit on a bundled one-second black clip stretched over their range. The compositor draws the photo, or black, on top.
- Audio items are packed onto as few tracks as possible. A loop is inserted repeatedly until the video ends.
- An `AVMutableAudioMix` sets volumes, fades, and crossfades during transitions. AVFoundation resamples mismatched sample rates.

**Compositor (`StitchCompositor`):** Core Image on Metal. For each frame, every active clip is drawn on its own canvas:
1. the background: a solid color, or a blurred copy of the clip
2. the clip, turned upright from its rotation flag, fitted or filled, then framed (scale, offset, rotation)

During a transition, `Transitions` mixes the two canvases.
- It renders both into textures and runs the shader as a Metal compute kernel.
- The shader is compiled at runtime by the system's Metal compiler. A Core Image kernel would be compiled at build time instead, which needs Xcode's optional Metal toolchain for every build.
- Without Metal it falls back to a dissolve.
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

## Android (`android/app/src/main/kotlin/xyz/gloryolaifa/stitch/engine/`)

Built on Media3 1.11 (`Transformer`, `CompositionPlayer`, and effects). Much of this API is marked unstable, so the version is pinned in `android/app/build.gradle.kts` and should only be upgraded with the engine tests passing.

**Composition (`CompositionBuilder`):** a Media3 `Composition`, the same for preview and export.
- Video is one sequence: the clips back to back.
  - A clip that ends in a transition stops where the transition starts.
  - The next clip's effect draws the rest of it, mixed with the incoming clip.
- Speed uses `EditedMediaItem.setSpeed`, which keeps pitch. Photos are image items with a duration. A missing file becomes a gap and plays as black.
- Sound:
  - Each clip's own sound plays with its item and fades in across an incoming transition.
  - The sound of a clip's part under an outgoing transition plays from a second, audio-only sequence, fading out.
  - Audio items get one sequence each, with loops inserted repeatedly.
  - `Gain` places each clip's fades on the whole clip, even when the clip plays as two items.
- HDR is tone mapped to SDR in OpenGL. That needs the `GL_EXT_YUV_target` extension, which phones that play HDR have and emulators lack. Without it, HDR sources are read as SDR, and on emulators 10-bit sources fail as `unsupported_media`.

**Clip effect (`ClipEffect`):** one GL effect per clip draws the whole canvas in a single full-resolution pass:
- the background: the canvas color, or a blur of the clip (filled into a texture 96 px on the long side, then blurred in two gaussian passes, with sigma 4 percent of the width as on iOS)
- the clip, fitted or filled, then framed, with the same geometry as iOS

During the transition into its clip, the effect also draws the outgoing clip and mixes the two with the transition shader.
- Media3 hands an effect one clip at a time, so `OutgoingFrames` decodes the outgoing clip's last moments itself. Photos are uploaded once.
- Video is decoded to memory with `MediaCodec` and uploaded as Y, U, and V textures, then converted in the shader (BT.601, BT.709, or BT.2020, full or limited range, from the stream).
- Decoding into a `SurfaceTexture` instead stalled the decoder while the GL thread waited for a frame.
- A frame not ready in time repeats the previous one. Export waits up to 8 s, under Media3's 10 s export watchdog. Preview waits up to 3 s, so it never freezes.
- This replaces Media3's compositor, which cannot run custom shaders and stops drawing when previewing two video sequences.

**Preview (`PreviewPlayer`):** a `CompositionPlayer` drawing into a Flutter `SurfaceProducer`.
- Rendering is capped at 1280 px on the long side.
- Scrubbing seeks use the player's scrubbing mode. Audio focus is handled, so calls pause the preview.
- Pausing seeks exactly to the paused position, so the frame shown matches the playhead even when video fell behind the audio clock.

**Export (`Exporter`):** a `Transformer`.
- Video is H.264 or HEVC at the requested bitrate. The frame rate is capped at the requested rate: frames are dropped above it and never duplicated below it.
- Audio is AAC at 192 kbps, resampled to 48 kHz.
- The file is written to `*.part.mp4`, then renamed. A cancelled or failed export leaves no file behind.

**Probe, thumbnails, and proxies:** in `MediaTools.kt`.
- `MediaExtractor` reads durations, rotation, frame rate, and HDR transfer. `ExifInterface` reads photo orientation.
- Filmstrip frames use `MediaMetadataRetriever` and the same stable file names as iOS.
- Proxies are 720p (short side) H.264, made by `Transformer`.

## Dart

- `NativeEditorEngine` implements `EditorEngine` over the bridge.
- `FakeEditorEngine` backs tests and platforms without a native engine.
- `Filmstrip` batches frame requests per file and caches them in memory and on disk. The disk cache is capped at 150 MB and pruned at startup.

## Tests

- **Both platforms:** every transition is checked against `test_media/transition_cases.json`.
- **Swift:** `ios/RunnerTests/EngineTests.swift` covers probe, composition, export, transitions, thumbnails, and proxies. The inputs are the corpus in `test_media/`, which `tool/make_test_media.sh` regenerates:
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
- **Kotlin:** `android/app/src/androidTest/.../engine/EngineTests.kt` mirrors the Swift tests. It adds checks for:
  - each clip appearing in its time range, in export and preview
  - a video transition drawing both clips, in export and preview
  - the blurred background
  - letterbox bars taking the background color
  - clip fades and the crossfade under a transition, measured from the exported sound The corpus is packaged as test assets. Run the tests with `cd android && ./gradlew :app:connectedDebugAndroidTest`.
- **End to end:** `integration_test/editor_flow_test.dart` covers the whole path. It picks from Photos, creates a project, previews, plays, exports, and then probes the export.

## Xcode project

`ruby tool/xcode_sync.rb` adds new files in `ios/Runner/Engine` and `ios/RunnerTests` to their targets, and the test media to the test bundle. It is safe to run repeatedly.

## Deferred

- The audio limiter moves to M8: `AVAudioMix` has no limiter stage.
- Transition `params` (the model's extra settings) are not used yet; every transition has fixed looks.
- On Android, an HDR clip leaving through a transition is drawn without tone mapping for those frames.
- Text and captions are drawn from M8 and M9.
