# Timeline model

Pure Dart. The model is in `lib/features/timeline/domain/`, undo history is in `lib/features/editor/domain/`, and the project document is in `lib/features/projects/domain/`. All times are integer microseconds.

## Data

`Timeline` holds `videoClips`, `transitions`, `textItems`, `captionTrack`, `audioItems`, and `audioMix`. `audioLanes` is derived from each item's `laneIndex`. Every type is immutable (freezed) and serializes to JSON.

## Rules

**Main track.** The main track is magnetic: clips are always back to back. A clip's timeline length is `(sourceOut - sourceIn) / speed`. Photos have no source length, default to 3 s, and can be extended without limit. Clips are at least 0.1 s long, and speed ranges from 0.25x to 4x.

**Transitions.** A transition sits in the cut after `afterClipId` and overlaps the two clips around it, so a 0.5 s transition shortens the video by 0.5 s. Its length is 0.2 s to 1.5 s, capped at half the shorter neighbor. The cap is re-applied after every edit.

**Anchors.** Text, caption, and audio items store an `Anchor`, never an absolute time.
- `ClipAnchor(clipId, sourceUs)` points at a moment of content. The item's position is computed from that moment, so it follows its content through trims, speed changes, reordering, and deletion of earlier clips.
- If the anchored moment is trimmed away, the item keeps its distance to where that moment would be. This keeps extracted audio in sync with the picture. Captions in that state are left out of the composition until the moment comes back.
- `TimeAnchor(startUs)` is used only while there are no clips. As soon as clips exist again, items re-anchor to the content under them.

**Deleting an anchor clip.** When the clip an item is anchored to is deleted, the item keeps its on-screen time, anchors to whatever clip is now there, and is flagged `needsReview`.

**Lanes.** Text and audio items on one lane never overlap. After any edit, an item that would overlap moves to the next free lane. Earlier items keep their lanes.

**Audio.** Looping audio fills to the end of the video. Anything past the video end is cut at export and flagged in the composition (`cutAtVideoEnd`). Fades always fit inside the item.

## Operations

Operations are extension methods grouped by area: `VideoTrackOps`, `TransitionOps`, `TextOps`, `CaptionOps`, and `AudioOps`.
- Every operation is total. When it does not apply (an unknown id, a split too close to an edge, a value already set), it returns the same instance. The editor controller checks `identical` to skip pushing undo history.
- `can*` methods tell the UI when to disable a tool.
- New ids are passed in by the caller, so operations stay deterministic.
- Every operation ends with `normalize`, which restores the invariants above.

## Composition

`ResolvedComposition.resolve(timeline)` flattens everything to absolute times. It includes:
- clip ranges
- transition windows, with matching audio crossfades
- final gains, after the original sound and added audio levels are applied
- captions with absolute word times

The native engines receive this document as JSON. Preview and export both use it, so they cannot disagree.

## Supporting pieces

- `snapping.dart`: `TimelineScale` converts between pixels and time and handles zoom limits. `snap` uses a threshold in pixels, so it feels the same at every zoom. `snapTargets` lists the playhead, the cuts, and item edges.
- `EditHistory`: immutable undo and redo with a limit of 100 steps. A drag pushes once when it starts, then calls `replace` on every update, so the whole drag undoes in one step.
- `ProjectCodec`: reads and writes the versioned project document. Migrations run one version at a time. Unreadable documents, documents from a newer app version, and missing migrations all become `ProjectCorruptedFailure`.

## Tests

- `test/features/timeline/`: one file per area.
- `test/features/timeline/invariants_test.dart` runs 1,000 seeded random sequences of 60 edits and checks every invariant after each step: limits, caps, anchor integrity, lane overlap, contiguous clips, composition bounds, JSON round trip, and idempotent `normalize`. A failure prints the seed and the list of edits that caused it.
- Domain line coverage is 100%.
