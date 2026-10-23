# Architecture

## Layout

```
lib/
  app/        bootstrap, router, app widget, global providers
  design/     tokens, theme, components, timeline components, design gallery
  core/       errors (sealed Failure), logging, time utilities
  engine/     EditorEngine interface, Pigeon wrappers, fake engine
  features/
    <feature>/
      domain/        pure Dart models and operations, no Flutter imports
      data/          repositories, storage, platform access
      application/   Riverpod Notifiers and AsyncNotifiers
      presentation/  screens and widgets built from design/ components
  l10n/       ARB files; generated/ is produced by flutter gen-l10n
```

Feature folders and layers are created when a milestone first needs them, not ahead of time. Current features: onboarding, projects, media (picker), editor, timeline, settings (stub).

Still to come: transitions, text, captions, audio, export.

## Dependencies between layers

- `presentation` reads `application` providers and `design/` components. It never touches `data` directly.
- `application` depends on `domain` and on `data` through providers.
- `domain` depends only on `core/` and other `domain` code.
- `engine/` depends on `core/` only. Features reach it through `editorEngineProvider`.

## State

- Riverpod with code generation. `Notifier` and `AsyncNotifier` only.
- All timeline edits go through one `EditorController`, which applies pure domain operations and pushes immutable snapshots to undo and redo history (M3, M4).
- Playback position streams from the engine through a separate provider. Widgets `select` the fields they need, so the timeline does not rebuild at display rate.
- `keyframing.dart` derives what the keyframe button acts on (`keyframeTarget`) and the selected item's values at the playhead (`valuesAtPlayhead`). Sliders and canvas gestures start from those values.
- Moving text or a clip on the preview snaps it (`editor/domain/canvas_snap.dart`): its position to the frame's centre and edges and to other text, a twist to a quarter turn, and a clip's zoom to its own size, filling the frame, or fitting it. The snapped values are what is stored, keyframes included.
- New clips from the add button go in at the cut nearest the playhead (`TimelineLayout.insertionIndexAt`): before the clip under it in its first half, after it in its second half. A transition at that cut stays with the clip before it, so the new clips end in a plain cut.
- Overlays are moved, zoomed, and turned on the preview like clips, with the same guides. While one is edited by hand, the engine's picture still has it where it was, so the editor draws the whole moment itself (`CanvasFramePreview`: the clip under the playhead and every overlay, each a frame read from its file) until the engine shows the edit. A clip edited by hand shows its frame the same way (`ClipFramePreview`).
- Tapping the preview selects text first, then an overlay (the topmost under the finger), and otherwise deselects or plays. A drag moves the selected overlay or clip; on an unselected overlay, it selects that overlay and moves it.
- After a seek, the playhead holds the target until the engine reports being there (`PlaybackController`): reports the engine sent before it got to the seek still have the old place, and an edit made at the playhead then (adding an overlay, a freeze) would land there.
- During a gesture (a drag, pinch, or slider move), edits update the editor state only. The engine gets one document when the gesture ends, which keeps dragging smooth on slower Android phones.

## Engine boundary

`EditorEngine` receives the whole serialized composition. The same document drives preview and export, so they cannot drift apart. During a drag nothing is sent; the result goes once, when the drag ends (on Android every document rebuilds the preview's players). While a clip's trim handle is dragged, the preview shows the frame at the handle instead (`TrimPreview`, from the engine's `previewFrame`). Native implementations use AVFoundation and Metal on iOS, and Media3 and OpenGL ES on Android. Both sit behind Pigeon. `FakeEditorEngine` backs tests and UI work.

## Storage

Everything is on the device, under the app's documents folder:

```text
projects/index.json          summaries for the home grid (a cache)
projects/<id>/project.json   the project document (versioned, see docs/timeline.md)
projects/<id>/media/         imported copies of picked photos and videos
projects/<id>/posters/       one still per media item
```

- Every write is atomic: the app writes a uniquely named temp file, flushes it, then renames it over the old one.
- Saves of one project run one at a time, and index updates run one at a time, so an older save never lands after a newer one. A failed save shows a banner with Retry.
- Duplicating assembles the copy in a `.staging` folder and renames it when complete; leftovers are removed when the index is rebuilt.
- The index is rebuilt from the project documents when it is missing or unreadable. An unreadable project is skipped, not fatal.
- Media is copied on import, so projects keep working when the gallery changes.
- The editor autosaves 500 ms after the last edit. It also saves when you leave the editor or the app goes to the background.
- Videos larger than 1080p get a 720p preview copy. Import makes it when the device decodes the source in hardware (seconds). Otherwise a software decoder must, which takes minutes, so `PreviewCopies` makes it in the background while the project is open, one at a time, with a banner; the same worker remakes copies that are missing. A copy is not an edit: it goes into every history step, with no undo step. A clip that cannot be decoded even in software is marked (`previewCopyFailed`) and the banner says so, with Retry.
- A clip whose copy has gone missing shows a banner with Relink: a new pick replaces the file for every clip and sound that used it, as one undo step. Trims and speed are kept (cut back if the new file is shorter). Export is disabled while any media in use is missing.

The cache folder holds what can be made again, and Settings shows its size and clears it:

```text
filmstrip/   timeline frames (150 MB, pruned at startup)
text/        drawn text and captions (50 MB, pruned at startup)
waveforms/   loudness peaks (20 MB, pruned at startup)
exports/     exported videos, kept for sharing (500 MB, pruned at startup); copies are in the gallery
models/      caption models (kept by Clear cache)
```

Free space is checked before each import copy, each export (twice the estimated size, for the gallery copy, plus 100 MB), and each model download.

## Settings

`SettingsController` keeps the preferences in the app's key-value store:
- the export defaults (resolution, frame rate, quality)
- the format of new projects
- the theme: dark by default, light, or the same as the device

The light palette uses the same token names as the dark one. Text over media uses `onOverlay`, which stays light in both themes.

## Export

`ExportController` runs an export from the export screen:
1. Deselects everything, so every text is drawn by the engine, and waits for the latest document to reach the engine.
2. Checks free space and keeps the screen on.
3. Exports at the chosen size and bitrate (`export_options.dart`: 5, 10, or 35 Mbps at 30 fps for 720p, 1080p, or 4K; 1.5 times at 60 fps, 0.8 times at 24 fps, 60 percent for smaller files, 70 percent with HEVC).
4. Writes the captions as SRT if asked.
5. Saves to the gallery.

The done screen plays the export in the engine's preview, as a one-clip document. On leaving, the editor sends its own document again.

## Media library

`MediaLibrary` is implemented with photo_manager (PhotoKit on iOS, MediaStore on Android). Tests use `FakeMediaLibrary`.

The picker explains why it needs access before the system prompt appears. After a refusal it offers "Open settings".

The gallery is reloaded every time the app returns to the foreground. On Android, a query made while access was being granted can come back empty, and new media may have been added in the meantime.

## Online sound library

The audio library's Online tab offers music and sound effects to download. The library lives on the Internet Archive; `tool/sound_catalog/README.md` describes it.

- **`SoundCatalog` and `SoundLibraryStore`** (`features/audio/data/sound_library.dart`):
  - the catalog format;
  - downloaded sounds in the cache folder (`sounds/`, kept by Clear cache);
  - the newest catalog, fetched and saved;
  - previews. Music plays a 15-second clip; an effect is small enough to just download.
- **`downloadFile`** (`core/network/file_download.dart`) does the downloading, shared with the caption models:
  - downloads into a `.part` file and resumes from it;
  - tries the base address, then each mirror;
  - checks size and SHA-256 before renaming the file into place.
- **`SoundLibrary`** (`features/audio/application/sound_library.dart`):
  - loads the saved catalog, or the shipped one (`assets/sound_library/catalog.json`);
  - fetches the newest catalog once per run of the app;
  - runs downloads two at a time, with cancel, retry, and delete.
  - Nothing is requested until the Online tab is opened, and nothing at all when "Online sound library" is off in Settings.
- **Adding a sound copies the file into the project**, as for any audio. Deleting downloads never affects a project.

## Ads

`Ads` (`lib/features/ads/ads.dart`) is the only way the app touches ads; `adsProvider` gives `AdMobAds`, and tests give `NoAds` or a fake.
- `start()` runs once, at launch (`StitchApp`), and again harmlessly from the projects screen's banner: consent update, Apple's tracking question on iOS (once, after Google's form), Google's consent form when required, then `MobileAds.initialize`. Nothing is requested when `canRequestAds` is false.
- The banner is the projects screen's `bottomNavigationBar`, so it stays put while the list scrolls. It is anchored adaptive at the screen's width and takes no room until it loads.
- `showInterstitial()` completes when the ad closes. One preloads at launch and after each show, failed loads retry every 60 s, and a call waits up to 3 s for a load in flight; with none after that, or within 60 s of the last ad, it completes at once. Captions: the sheet closes, the ad shows, then generation starts. Export: after the export sheet, the ad shows, then the export screen opens. The next ad loads right after one shows.
- Settings shows "Ad privacy choices" when `getPrivacyOptionsRequirementStatus` says it is required.
- `integration_test/ads_test.dart` checks live test ads on a device: the banner at the bottom, and a full-screen ad loading and showing.

## Analytics

`Analytics` (`lib/features/analytics/analytics.dart`) is the only way the app records usage; `analyticsProvider` gives `FirebaseAppAnalytics`, and tests give `NoAnalytics` or a recording fake.
- Firebase starts in `bootstrap`, before the first frame; the app runs on if it cannot.
- The router reports each screen as its route pattern (`routerDelegate.currentConfiguration.fullPath`), so ids never leave the device.
- Feature events are logged where the work succeeds: `ImportController.createProject`, `EditorController` (text, overlays, freeze), `CaptionGeneration`, and `ExportController`.
- Consent starts denied on both platforms. `StitchApp` starts the ads at launch, which runs Google's consent check; when the form is not needed where the user is, `AdMobAds` tells analytics to grant consent.

## Errors

Failures are subclasses of the sealed `Failure` in `core/errors`. They carry no user-facing text. Presentation maps each subclass to a localized message.

## Time

Timeline times are integer microseconds everywhere. Helpers live in `core/time`.

## Routing

`go_router` from `routerProvider`. The router is built once. Onboarding state triggers `redirect` through a refresh listenable, so completing onboarding does not reset navigation. The design gallery route exists only in debug and profile builds.

## Rules enforced by tests

See `test/architecture/rules_test.dart`.
