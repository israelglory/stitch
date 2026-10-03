# Plan: more transitions and an online sound library

Status: T1 and T2 done (50 transitions; see `transitions/README.md`). A1 to A4 not started. Each milestone ends with a report.

## Part 1: Transitions

Today each transition exists three times: a GLSL shader on Android (`TransitionShader.kt`), a Metal shader on iOS (`Transitions.swift`), and a widget approximation for the sheet thumbnails (`lib/design/components/transition_preview.dart`). That does not scale past a handful, and the widget approximation cannot draw complex effects.

### T1: One source per transition (≈4–6 h)

1. **Source format.** One GLSL file per transition in `transitions/`, in the [gl-transitions](https://gl-transitions.com) style: a `transition(uv)` function over `getFromColor`, `getToColor`, and `progress`. A header gives the ID, category, default parameters, and license.
2. **Code generation** (`tool/gen_transitions.dart`; output checked in):
   - Android: the GLSL goes into the existing shader, one branch per transition.
   - iOS: Metal translated at build time with glslang and SPIRV-Cross (open-source command-line tools, needed only on the developer's machine).
   - Flutter: one fragment shader per transition, listed under `shaders:` in `pubspec.yaml`, so the sheet thumbnails show the real effect.
3. **Data-driven transitions.** `TransitionType` (an enum) becomes a catalog of string IDs. Projects already store the type by name, so existing projects load unchanged. An unknown ID (from a newer app version) falls back to a crossfade in Dart and in both engines. `Transition.params` already exists for per-transition settings.
4. **Move the 7 existing transitions** to the pipeline. `test_media/transition_cases.json` must still pass on both platforms, which proves nothing changed.
5. **Image-based parity tests.** The Flutter shader renders reference images for every transition at a few progress points; the Kotlin and Swift engine tests compare their output to them within a tolerance. Every new transition then gets cross-platform checks automatically.

Risk to check first: whether `flutter test` can run fragment shaders. If not, the reference images come from a simulator run instead.

### T2: The library (≈6–10 h for about 50)

1. **License audit.** Port only MIT-licensed (or compatible) gl-transitions; credit them in the app.
2. **Port about 50**, in categories: Basic, Slide & Push, Wipe, Zoom & Spin, Shape, Blur & Light, Glitch & Pixel, Fun.
3. **Sheet redesign.** Category tabs and a thumbnail grid. Only visible thumbnails animate; shaders compile when the sheet opens, so first use does not stutter.
4. **Performance.** Measure each transition in preview and export on the Redmi Note 11. Drop or simplify any that cannot hold 30 fps.
5. Translated names, screen reader labels, golden tests, and the transitions section of `docs/engine.md`.

## Part 2: Online sound library (free hosting)

The bundled 8 music tracks and 15 sound effects stay in the app, so it works with no network. The online library adds more: users see the whole catalog, tap to download (with progress), and then use the sound like any other, offline from then on.

### A1: Content and publishing tool (≈3–5 h, plus curation)

1. **Shortlist for approval**, about 150–300 items:
   - Music: Komiku, Loyalty Freak Music, Lack of Color (CC0), Musopen (public domain). Categories: Upbeat, Calm, Cinematic, Playful, Hip-hop/Beats, Acoustic.
   - Sound effects: Kenney (CC0), Freesound filtered to CC0. Categories: Whoosh, Pop & Click, Impact, UI, Nature, Crowd, Funny.
   - Not allowed (no redistribution): Pixabay, YouTube Audio Library, BBC Sound Effects, Sonniss GDC bundles.
2. **`tool/sound_catalog/` script.** From a source list (URL, license, credit) it:
   - downloads the originals;
   - evens out loudness and trims silence;
   - encodes AAC (128 kbps music, 96 kbps effects);
   - makes 15-second preview clips for music;
   - records SHA-256 checksums and durations;
   - writes `catalog.json`.
3. **Publishing.** Files and `catalog.json` go to an Internet Archive item, uploaded with the open-source `ia` tool. Each catalog entry can list a backup address, so a GitHub Releases mirror can be added later.

Needs: a free archive.org account; its upload keys stay on the developer's machine.

### A2: Download engine (≈3–4 h)

1. **Catalog client.** Fetches `catalog.json` only when it has changed, and caches it. A copy ships in the app so the list shows at first launch, even offline.
2. **`DownloadStore`**, generalized from `CaptionModelStore` (`lib/features/captions/data/caption_models.dart`): resume, SHA-256 check, free-space check, plus a queue (two at a time), cancel, and retry.
3. **Storage** in `downloads/sounds/`. Projects keep their own copy of any sound they use, so deleting a download never breaks a project.
4. **Previews from the network.** The mini player streams preview clips: AVPlayer on iOS (the current `AVAudioPlayer` only plays local files) and ExoPlayer on Android.

### A3: Library UI, settings, credits (≈5–7 h)

1. **Audio library** (`audio_library_screen.dart`): a third tab next to Bundled and From device, with category chips and search over the catalog.
2. **Item states:** not downloaded (preview, download), downloading (progress ring; tap to cancel), ready (Add), failed (Retry), and offline (list stays visible with a notice).
3. **Settings:** downloaded sounds with total size, delete one or all; "Use online sound library" on or off.
4. **Credits screen:** title, artist, license, and source for each item.
5. Translations, accessibility, golden and flow tests against a fake server.
6. **Docs:** the README's network section (today it says the caption model is the only download), F-Droid notes (catalog optional, non-profit host, address configurable), and the privacy statement (no tracking, accounts, or analytics).

### A4: Device testing (≈2–3 h)

On the Redmi Note 11, the iPhone simulator, and an iPad simulator:

- browse, preview, download, add, then play and export with the new sound;
- go offline mid-download, then resume;
- delete a download that a project uses; the project still plays.

## Schedule

| Order | Milestone | Estimate |
|---|---|---|
| 1 | T1 Transition pipeline | 4–6 h |
| 2 | T2 About 50 transitions | 6–10 h |
| 3 | A1 Sound content and tooling | 3–5 h + curation |
| 4 | A2 Download engine | 3–4 h |
| 5 | A3 Library UI, settings, credits | 5–7 h |
| 6 | A4 Device testing | 2–3 h |

About 25–35 hours of implementation over 4–6 sessions. The estimates include build and test runs (release build ≈4 min, Kotlin engine suite 3–7 min, iOS suite ≈5 min). Calendar time also depends on approving the sound shortlist, creating the archive.org account, and upload speed to the Internet Archive.

## Open decisions

1. Number of transitions: about 50 to start, more later?
2. Sound licenses: CC0 only (no credits needed), or CC0 and CC-BY (more choice, credits shown in the app)?
3. Initial catalog size: about 150 items, or more?
4. Order: transitions first (as above) or sounds first?
