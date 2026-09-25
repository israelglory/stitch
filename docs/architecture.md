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

## Engine boundary

`EditorEngine` receives the whole serialized composition. The same document drives preview and export, so they cannot drift apart. Updates are debounced while dragging. Native implementations use AVFoundation and Metal on iOS, and Media3 and OpenGL ES on Android. Both sit behind Pigeon. `FakeEditorEngine` backs tests and UI work.

## Storage

Everything is on the device, under the app's documents folder:

```text
projects/index.json          summaries for the home grid (a cache)
projects/<id>/project.json   the project document (versioned, see docs/timeline.md)
projects/<id>/media/         imported copies of picked photos and videos
projects/<id>/posters/       one still per media item
```

- Every write is atomic: the app writes a temp file, then renames it over the old one.
- The index is rebuilt from the project documents when it is missing or unreadable. An unreadable project is skipped, not fatal.
- Media is copied on import, so projects keep working when the gallery changes.
- The editor autosaves 500 ms after the last edit. It also saves when you leave the editor or the app goes to the background.
- A clip whose copy has gone missing shows a banner with Relink: a new pick replaces the file for every clip that used it, as one undo step.

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

## Errors

Failures are subclasses of the sealed `Failure` in `core/errors`. They carry no user-facing text. Presentation maps each subclass to a localized message.

## Time

Timeline times are integer microseconds everywhere. Helpers live in `core/time`.

## Routing

`go_router` from `routerProvider`. The router is built once. Onboarding state triggers `redirect` through a refresh listenable, so completing onboarding does not reset navigation. The design gallery route exists only in debug and profile builds.

## Rules enforced by tests

See `test/architecture/rules_test.dart`.
