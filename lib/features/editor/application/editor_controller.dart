import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/logging/logger.dart';
import 'package:stitch/core/time/clock.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/captions/application/caption_rendering.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/engine_document.dart';
import 'package:stitch/features/editor/domain/edit_history.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/application/projects_controller.dart';
import 'package:stitch/features/projects/data/project_store.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/text/application/text_providers.dart';
import 'package:stitch/features/text/application/text_rendering.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
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
  late TextRasterizer _rasterizer;
  EditorState? _latest;

  /// Version of the last document sent to the engine.
  int _version = 0;

  /// Texts handed back to the engine, by the document version that first
  /// includes them; [_awaitingDocument] until that document is sent.
  final _handoffs = <String, int>{};
  static const _awaitingDocument = -1;

  @override
  Future<EditorState> build(String projectId) async {
    _store = ref.watch(projectStoreProvider);
    _clock = ref.watch(clockProvider);
    _engine = ref.watch(editorEngineProvider);
    _rasterizer = ref.watch(textRasterizerProvider);
    final shown = _engine.playbackState
        .map((s) => s.documentVersion)
        .distinct()
        .listen(_onDocumentShown);
    ref.onDispose(() {
      _syncTimer?.cancel();
      unawaited(shown.cancel());
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
    final waiting = [..._afterGesture];
    _afterGesture.clear();
    for (final edit in waiting) {
      edit();
    }
  }

  /// Edits that arrived during a gesture, applied when it ends.
  final _afterGesture = <void Function()>[];

  /// Replaces the captions with [segments], recognized from the sound of
  /// [heard]: the timeline as it was when recognition started. Anchored
  /// in that timeline, they land on the same speech in this one, even
  /// after edits made meanwhile. Keeps the caption style. One undo step.
  void setRecognizedCaptions(
    Timeline heard,
    List<RecognizedSegment> segments, {
    String? language,
  }) {
    final track = heard.setCaptions(segments, language: language).captionTrack;
    void edit() => apply(
      (t) => t.copyWith(
        captionTrack: track.copyWith(
          preset: t.captionTrack.preset,
          position: t.captionTrack.position,
        ),
      ),
    );
    if (_gestureBase != null) {
      _afterGesture.add(edit);
    } else {
      edit();
    }
  }

  /// Gets the engine ready to export: every text drawn by the engine
  /// (nothing selected, so nothing drawn live) and the latest document
  /// sent. Returns the project as sent.
  Future<Project> prepareForExport() async {
    final current = _current;
    if (current.selection is! NoSelection) {
      _setSelection(current, const NoSelection());
    }
    _syncTimer?.cancel();
    final project = _current.project;
    await _send(project);
    return project;
  }

  /// Sends the document again, after another screen used the preview.
  void resync() => _syncEngine(_current.project, immediate: true);

  void undo() => _restore(_current.history.undo());

  void redo() => _restore(_current.history.redo());

  void select(Selection selection) {
    final current = _current;
    if (current.selection == selection) return;
    _setSelection(current, selection);
  }

  void _setSelection(EditorState current, Selection selection) {
    final before = current.selection;
    // The selected text is drawn live by the editor, not the engine.
    if (before is TextSelected && selection != before) {
      _handoffs[before.id] = _awaitingDocument;
    }
    if (selection is TextSelected) _handoffs.remove(selection.id);
    _emit(
      current.copyWith(selection: selection, liveTexts: _liveTexts(selection)),
    );
    if (before is TextSelected || selection is TextSelected) {
      _syncEngine(current.project, immediate: true);
    }
  }

  Set<String> _liveTexts(Selection selection) => {
    if (selection is TextSelected) selection.id,
    ..._handoffs.keys,
  };

  void _onDocumentShown(int version) {
    final before = _handoffs.length;
    _handoffs.removeWhere((_, v) => v != _awaitingDocument && v <= version);
    final latest = _latest;
    if (_handoffs.length != before && latest != null && ref.mounted) {
      _emit(latest.copyWith(liveTexts: _liveTexts(latest.selection)));
    }
  }

  /// Adds [text] at [atUs] and selects it for editing.
  String addText(String text, {required int atUs}) {
    final id = ref.read(idGeneratorProvider).next();
    apply((t) => t.addText(id: id, text: text, atUs: atUs));
    select(TextSelected(id));
    return id;
  }

  /// Imports the audio file [source] as [name] and adds it at [atUs] as a
  /// [kind] item. A file the app made for this ([move]) is moved in.
  Future<void> addAudioFile(
    File source, {
    required String name,
    required AudioKind kind,
    required int atUs,
    bool move = false,
  }) async {
    final asset = await ref
        .read(mediaImporterProvider)
        .importAudio(
          _current.project.id,
          source: source,
          name: name,
          move: move,
        );
    if (!ref.mounted) return;
    addAudioAsset(asset, kind, atUs: atUs);
  }

  /// Adds [asset] (imported audio) at [atUs] as a [kind] item and selects
  /// it.
  void addAudioAsset(MediaAsset asset, AudioKind kind, {required int atUs}) {
    final id = ref.read(idGeneratorProvider).next();
    applyProject(
      (p) => p.copyWith(
        media: {...p.media, asset.id: asset},
        timeline: p.timeline.addAudio(
          id: id,
          mediaId: asset.id,
          kind: kind,
          name: asset.displayName,
          mediaDurationUs: asset.durationUs ?? 0,
          atUs: atUs,
        ),
      ),
    );
    select(AudioSelected(id));
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

  /// Clips whose media file is missing, by media id; the first can be
  /// relinked.
  String? get relinkableMedia {
    final current = _current;
    for (final c in current.timeline.videoClips) {
      if (current.missingMedia.contains(c.mediaId)) return c.mediaId;
    }
    return null;
  }

  /// Points every clip that used the missing [mediaId] at [item], imported
  /// now. One undo step. Returns false when the import was cancelled or
  /// failed.
  Future<bool> relinkMedia(String mediaId, LibraryItem item) async {
    final projectId = _current.project.id;
    final assets = await ref.read(importControllerProvider.notifier).importInto(
      projectId,
      [item],
    );
    if (assets == null || assets.isEmpty || !ref.mounted) return false;
    final asset = assets.single;
    applyProject((p) {
      var timeline = p.timeline;
      for (final clip in p.timeline.videoClips) {
        if (clip.mediaId != mediaId) continue;
        timeline = timeline.replaceClipMedia(
          clip.id,
          mediaId: asset.id,
          kind: asset.kind,
          mediaDurationUs: asset.durationUs,
        );
      }
      // The missing file goes, unless sound on an audio lane still uses it.
      final stillUsed = timeline.audioItems.any((a) => a.mediaId == mediaId);
      return p.copyWith(
        media: {
          for (final MapEntry(:key, :value) in p.media.entries)
            if (key != mediaId || stillUsed) key: value,
          asset.id: asset,
        },
        timeline: timeline,
      );
    });
    final current = _current;
    _commit(
      current.copyWith(missingMedia: _store.missingMedia(current.project)),
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
  EditorState _keepSelectionValid(EditorState s) {
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
    if (exists) return s;
    // A deleted text needs no handoff.
    final selection = s.selection;
    if (selection is TextSelected) _handoffs.remove(selection.id);
    return s.copyWith(
      selection: const NoSelection(),
      liveTexts: _liveTexts(const NoSelection()),
    );
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(autosaveDelay, () => unawaited(flush()));
  }

  void _syncEngine(Project project, {bool immediate = false}) {
    _syncTimer?.cancel();
    if (immediate) {
      unawaited(_send(project));
    } else {
      _syncTimer = Timer(engineSyncDelay, () => unawaited(_send(project)));
    }
  }

  /// Draws the text items the engine shows, then sends the document. A
  /// newer send supersedes this one while its text is still being drawn.
  Future<void> _send(Project project) async {
    final version = ++_version;
    final composition = ResolvedComposition.resolve(project.timeline);
    final selection = _latest?.selection;
    final live = selection is TextSelected ? selection.id : null;
    final canvas = project.canvas;
    // Drawn alongside the text; without captions, nothing to wait for.
    final captionsDrawn = composition.captions.isEmpty
        ? null
        : renderCaptions(
            _rasterizer,
            composition,
            canvasWidth: canvas.width,
            canvasHeight: canvas.height,
          ).catchError((Object e, StackTrace st) {
            _log.error('Could not draw captions', e, st);
            return <CaptionImage>[];
          });
    final drawn = await Future.wait([
      for (final t in composition.texts)
        if (t.id != live)
          _rasterizer
              .render(
                text: t.text,
                style: t.style,
                typewriter:
                    t.animationIn == TextAnimation.typewriter ||
                    t.animationOut == TextAnimation.typewriter,
                canvasWidth: canvas.width,
                canvasHeight: canvas.height,
              )
              .then<MapEntry<String, TextRaster>?>(
                (raster) => MapEntry(t.id, raster),
                onError: (Object e, StackTrace st) {
                  _log.error('Could not draw text ${t.id}', e, st);
                  return null;
                },
              ),
    ]);
    final captions = captionsDrawn == null
        ? const <CaptionImage>[]
        : await captionsDrawn;
    if (version != _version || !ref.mounted) return;
    final texts = Map.fromEntries(drawn.nonNulls);
    // Texts handed back to the engine are in this document: keep drawing
    // them live until the engine shows it.
    for (final id in _handoffs.keys.toList()) {
      if (_handoffs[id] == _awaitingDocument) {
        if (texts.containsKey(id)) {
          _handoffs[id] = version;
        } else if (!composition.texts.any((t) => t.id == id)) {
          _handoffs.remove(id);
        }
      }
    }
    await _engine.setDocument(
      engineDocumentJson(
        project,
        resolve: (relative) => _store.resolve(project.id, relative),
        texts: texts,
        captions: captions,
        version: version,
        composition: composition,
      ),
    );
  }
}
