import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/logging/logger.dart';
import 'package:stitch/core/time/clock.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/engine_document.dart';
import 'package:stitch/features/editor/domain/edit_history.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/application/projects_controller.dart';
import 'package:stitch/features/projects/data/project_store.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

part 'editor_controller.g.dart';

const _log = Logger('editor');

/// Delay before saving after the last edit.
const autosaveDelay = Duration(milliseconds: 500);

/// Delay before sending the composition to the engine; coalesces the many
/// updates of a drag.
const engineSyncDelay = Duration(milliseconds: 32);

/// Owns an open project. All edits go through [apply] (or a gesture),
/// which records undo history, autosaves, and keeps the engine in sync.
@riverpod
class EditorController extends _$EditorController {
  Timer? _saveTimer;
  Timer? _syncTimer;
  bool _dirty = false;

  /// Snapshot at the start of the current gesture, or null.
  Project? _gestureBase;

  // Captured in build: `ref` must not be used after disposal, but the
  // final save and engine release happen then.
  late ProjectStore _store;
  late Clock _clock;
  late EditorEngine _engine;
  EditorState? _latest;

  @override
  Future<EditorState> build(String projectId) async {
    _store = ref.watch(projectStoreProvider);
    _clock = ref.watch(clockProvider);
    _engine = ref.watch(editorEngineProvider);
    ref.onDispose(() {
      _syncTimer?.cancel();
      unawaited(flush().whenComplete(_engine.release));
    });
    final project = await _store.load(projectId);
    final initial = _latest = EditorState(
      history: EditHistory(project),
      missingMedia: _store.missingMedia(project),
    );
    _syncEngine(project, immediate: true);
    return initial;
  }

  EditorState get _current => state.requireValue;

  void _emit(EditorState value) {
    _latest = value;
    state = AsyncData(value);
  }

  /// Applies a timeline edit as one undoable step. Edits that change
  /// nothing (an operation that did not apply) add no step.
  void apply(Timeline Function(Timeline timeline) edit) =>
      applyProject((p) => _withTimeline(p, edit(p.timeline)));

  /// Applies a project-level edit (canvas, background, media) as one step.
  void applyProject(Project Function(Project project) edit) {
    final current = _current;
    final next = edit(current.project);
    if (identical(next, current.project)) return;
    _commit(current.copyWith(history: current.history.push(next)));
  }

  /// Starts a continuous edit (a drag). Updates are applied to the
  /// snapshot at the start, and the whole gesture undoes in one step.
  void beginGesture() {
    _gestureBase = _current.project;
  }

  void updateGesture(Timeline Function(Timeline base) edit) {
    final base = _gestureBase;
    if (base == null) return;
    final next = _withTimeline(base, edit(base.timeline));
    final current = _current;
    final history = identical(current.history.present, base)
        ? current.history.push(next)
        : current.history.replace(next);
    _commit(current.copyWith(history: history), duringGesture: true);
  }

  void endGesture() {
    _gestureBase = null;
    _scheduleSave();
  }

  void undo() => _restore(_current.history.undo());

  void redo() => _restore(_current.history.redo());

  void select(Selection selection) {
    final current = _current;
    if (current.selection == selection) return;
    _emit(current.copyWith(selection: selection));
  }

  void setCanvas(AspectPreset preset) => applyProject((p) {
    if (p.canvas.preset == preset) return p;
    final firstMedia = p.timeline.videoClips.isEmpty
        ? null
        : p.media[p.timeline.videoClips.first.mediaId];
    return p.copyWith(
      canvas: ProjectCanvas.forPreset(
        preset,
        original: firstMedia == null || firstMedia.width == 0
            ? null
            : (firstMedia.width, firstMedia.height),
      ),
    );
  });

  void setBackground(CanvasBackground background) => applyProject(
    (p) => p.background == background ? p : p.copyWith(background: background),
  );

  /// Renames the project. Not an undo step; saved right away.
  Future<void> rename(String name) async {
    final trimmed = name.trim();
    final current = _current;
    if (trimmed.isEmpty || trimmed == current.project.name) return;
    // Rename every snapshot so undo does not bring back the old name.
    _emit(
      current.copyWith(
        history: current.history.map((p) => p.copyWith(name: trimmed)),
      ),
    );
    _dirty = true;
    await flush();
  }

  /// Imports [items] and inserts them as clips at [index] (the end by
  /// default). Returns false when the import was cancelled or failed.
  Future<bool> addMedia(List<LibraryItem> items, {int? index}) async {
    final projectId = _current.project.id;
    final assets = await ref
        .read(importControllerProvider.notifier)
        .importInto(projectId, items);
    if (assets == null || !ref.mounted) return false;
    final ids = ref.read(idGeneratorProvider);
    final clips = clipsFor(assets, ids.next);
    applyProject(
      (p) => p.copyWith(
        media: {...p.media, for (final a in assets) a.id: a},
        timeline: p.timeline.insertClips(
          index ?? p.timeline.videoClips.length,
          clips,
        ),
      ),
    );
    if (clips.isNotEmpty) select(ClipSelected(clips.first.id));
    return true;
  }

  /// Replaces the media of [clipId] with [item].
  Future<bool> replaceClip(String clipId, LibraryItem item) async {
    final projectId = _current.project.id;
    final assets = await ref.read(importControllerProvider.notifier).importInto(
      projectId,
      [item],
    );
    if (assets == null || assets.isEmpty || !ref.mounted) return false;
    final asset = assets.single;
    applyProject(
      (p) => p.copyWith(
        media: {...p.media, asset.id: asset},
        timeline: p.timeline.replaceClipMedia(
          clipId,
          mediaId: asset.id,
          kind: asset.kind,
          mediaDurationUs: asset.durationUs,
        ),
      ),
    );
    return true;
  }

  /// Saves now if anything changed since the last save.
  Future<void> flush() async {
    _saveTimer?.cancel();
    final value = _latest;
    if (!_dirty || value == null) return;
    _dirty = false;
    try {
      await _store.save(value.project.copyWith(updatedAt: _clock()));
      if (ref.mounted) ref.invalidate(projectsControllerProvider);
    } on Object catch (e, st) {
      _dirty = true;
      _log.error('Autosave failed', e, st);
    }
  }

  static Project _withTimeline(Project p, Timeline timeline) =>
      identical(timeline, p.timeline) ? p : p.copyWith(timeline: timeline);

  void _commit(EditorState next, {bool duringGesture = false}) {
    final previous = _current;
    _emit(_keepSelectionValid(next));
    // Canvas, background, and media changes matter to the engine too.
    if (!identical(previous.project, next.project)) {
      _syncEngine(next.project);
    }
    if (!duringGesture) _scheduleSave();
    _dirty = true;
  }

  void _restore(EditHistory<Project> history) {
    final current = _current;
    if (identical(history, current.history)) return;
    _commit(current.copyWith(history: history));
  }

  /// Clears the selection when its item no longer exists (after delete or
  /// undo).
  static EditorState _keepSelectionValid(EditorState s) {
    final t = s.timeline;
    final exists = switch (s.selection) {
      NoSelection() => true,
      ClipSelected(:final id) => t.videoClips.any((c) => c.id == id),
      TextSelected(:final id) => t.textItems.any((x) => x.id == id),
      CaptionSelected(:final id) => t.captionTrack.segments.any(
        (x) => x.id == id,
      ),
      AudioSelected(:final id) => t.audioItems.any((x) => x.id == id),
    };
    return exists ? s : s.copyWith(selection: const NoSelection());
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(autosaveDelay, () => unawaited(flush()));
  }

  void _syncEngine(Project project, {bool immediate = false}) {
    _syncTimer?.cancel();
    void send() {
      final json = engineDocumentJson(
        project,
        resolve: (relative) => _store.resolve(project.id, relative),
      );
      unawaited(_engine.setDocument(json));
    }

    if (immediate) {
      send();
    } else {
      _syncTimer = Timer(engineSyncDelay, send);
    }
  }
}
