# Captions

Captions are made on the device with [whisper.cpp](https://github.com/ggml-org/whisper.cpp). Nothing is sent anywhere; the only network use is the one-time model download.

## How a caption job runs

`CaptionGeneration` (`lib/features/captions/application/caption_generation.dart`) runs in the background while editing goes on. The editor shows its progress with Cancel, and closing the editor cancels it.

1. **The sound.**
   - The project's timeline is narrowed to the chosen source (`timelineForSource`):
     - video: the clips and sound extracted from them
     - voiceover: voiceovers alone
     - all: everything
   - The engines render that sound as 16 kHz mono float PCM (`speechAudio`, see [engine.md](engine.md#speech-audio)). The file lines up with the timeline from 0.
2. **The words.** `WhisperRecognizer` runs whisper.cpp on a background isolate over FFI.
   - It reports progress, and can be cancelled.
   - The result is JSON with each token's bytes and times.
3. **The captions.**
   - `Transcript.words` joins tokens into words at spaces. Words never split inside a UTF-8 character. Languages written without spaces get a word per token.
   - `captionGroups` breaks words into captions:
     - at sentence ends
     - at pauses over 0.7 s
     - before 42 characters or 5 s
     - after a comma once half full
   - A caption stays up 0.4 s after its last word, or until the next caption starts.
4. **Applying them.**
   - Captions are anchored in the timeline as it was when the job started, then placed on the current one. Edits made meanwhile (a trimmed clip, say) keep them on the same speech.
   - If a caption's clip was split meanwhile, it moves to the part that holds its speech. If its speech is gone (the clip was deleted), it keeps its time and is flagged for review.
   - Captions on a clip follow its speed: a clip at 2x makes its captions and word times half as long.
   - Languages written without spaces (Chinese, Japanese, Thai, and others) are joined without spaces when captions are merged or split, and a typo fix keeps the word timings when the length matches.
   - Replacing the captions is one undo step. The track's style and position are kept.
   - During a drag, they wait until it ends.

Failures (`CaptionFailure`) are no speech, a damaged model, or recognition failing. A damaged model is deleted, so trying again downloads it again.

## Models

The multilingual models, 8-bit quantized (q8_0): about half the size of the full ones, with nearly the same accuracy.

| Model | Shown as | Size |
| --- | --- | --- |
| `ggml-tiny-q8_0.bin` | Faster | 44 MB |
| `ggml-base-q8_0.bin` | More accurate | 82 MB |

About downloads (`CaptionModelStore`):
- Downloads come from a pinned revision of `huggingface.co/ggerganov/whisper.cpp` and are checked against a pinned SHA-256.
- An interrupted download resumes with a range request.
- Models live in the cache folder (`cache/models`). They stay out of iCloud and Android backups, and are downloaded again if the system clears them.
- The generate sheet offers Generate right away. When the model is missing, it downloads first, with the size shown and a Cancel.

## Building whisper.cpp

`third_party/whisper.cpp` holds the CPU backend of whisper.cpp v1.9.4. `tool/vendor_whisper.sh <tag>` refreshes it.

`hook/build.dart` compiles it with `native_toolchain_c` for every target:
- iOS device and simulator
- Android arm64, arm, and x64
- the host, for `flutter test`

ggml's C files go into a static library first, because a `CBuilder` compiles all its sources as one language. The C++ files and the shim `native/whisper/stitch_whisper.cpp` then link that library into `stitch_whisper`.

The shim:
- is the only interface Dart sees (`whisper_bindings.dart`)
- takes progress and cancellation as plain memory the caller owns, so nothing calls into Dart from whisper's threads
- returns token text one byte per character, so Dart decodes whole words

Settings:
- The CPU baseline is plain for each architecture (NEON on ARM), so it runs on every supported phone.
- Apple builds use Accelerate.
- The library is 2 to 3 MB per architecture once stripped.

## Rendering

Captions are drawn like text (see [engine.md](engine.md#text)): Dart draws each one to a PNG with `OverlayTextLayout`, and the engines place the images.
- **Presets** (`captionStyle`):
  - Plain: white with a thin outline.
  - Box: white on a dark box.
  - Highlight: the spoken word in yellow.
  - Bold: Anton with a heavy outline.
- **Size:** 6.5 percent of the canvas's shorter side, so captions read the same in any aspect ratio.
- **Width:** captions wrap at 80 percent of the width.
- **Position:** top, middle, or bottom (centered at 18, 50, or 78 percent of the height).
- **Highlight preset:** each word gets its own image, shown from that word's start until the next word starts (`captionPieces`).

Without a native preview (the fake engine), `CaptionPreviewLayer` draws the caption at the playhead with the same layout.

## Editing

- **Caption editor** (Text tab):
  - Lists captions in time order. Tapping a time seeks there.
  - Text is edited in place; each visit to a field is one undo step, and emptying a caption deletes it.
  - Split at cursor, merge with next, and delete.
  - Text edits keep word timings when the word count is unchanged; otherwise the words are spread evenly.
- **Style tab:** sets the preset and position for the whole track.
- **A caption selected on the timeline:** Edit, Style, Split (before the first word at or after the playhead), and Delete.

## Tests

- `test/features/captions/`:
  - token joining, grouping, and SRT (`transcript_test.dart`)
  - downloads against a local server: resume, checksum, and cancel (`caption_models_test.dart`)
  - real recognition of `test_media/speech_16k.f32` (`speech_recognizer_test.dart`); needs `tool/fetch_test_model.sh`
  - the pipeline with edits made meanwhile (`caption_generation_test.dart`)
- `test/features/captions_flow_test.dart`: the screens, with fakes.
- **Native:** speech audio on both platforms (16 kHz, lined up with the timeline, empty without sound), and Android's 48 to 16 kHz filter.
- `integration_test/captions_test.dart`: end to end on a device. It downloads the model, renders the sound, recognizes the sample, and checks the words and the images sent to the engine.

## Not yet

- SRT export is written (`srtOf`); the export sheet offers it in M10.
- No GPU or Core ML acceleration: CPU only, which keeps one build for every phone.
- Recognition speed on real phones is not measured yet. On the Apple silicon Mac, the tiny model takes about a second per 30 s window; the arm64 emulator is several times slower.
