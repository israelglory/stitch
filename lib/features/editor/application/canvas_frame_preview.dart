import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/overlay_ops.dart';

part 'canvas_frame_preview.g.dart';

/// Long side of the frames shown, in pixels.
const int _frameSize = 720;

/// Longest the frames stay after an edit, if the engine never reports it.
const Duration _engineWait = Duration(seconds: 2);

/// The picture at one moment, drawn by the editor: the clip under it and
/// every overlay showing then, each a frame of its own.
@immutable
final class CanvasFrames {
  const new({
    required this.atUs,
    required this.clipId,
    required this.clipImage,
    required this.overlayImages,
  });

  /// Timeline time the frames belong to.
  final int atUs;

  /// The clip under [atUs], if any, and its frame (null for photos,
  /// which show as they are).
  final String? clipId;
  final Uint8List? clipImage;

  /// Frames of the video overlays showing, by id. Photos have none.
  final Map<String, Uint8List> overlayImages;
}

/// The preview while an overlay is moved, zoomed, turned, or faded by
/// hand. The engine is sent the edit only when it ends, and its picture
/// still has the overlay where it was, so the editor draws the whole
/// moment itself: the clip and every overlay, each placed by its values
/// as they change.
///
/// Frames come from the engine straight from the files (preview copies
/// when there are any), once per moment: the playhead stays put while
/// something is edited by hand.
@riverpod
class CanvasFramePreview extends _$CanvasFramePreview {
  int? _following;
  StreamSubscription<Object>? _waitForEngine;

  @override
  CanvasFrames? build(String projectId) {
    ref.onDispose(() => unawaited(_waitForEngine?.cancel()));
    return null;
  }

  /// Shows the picture at timeline time [atUs].
  Future<void> follow(int atUs) async {
    unawaited(_waitForEngine?.cancel());
    _waitForEngine = null;
    if (_following == atUs || state?.atUs == atUs) {
      _following = atUs;
      return;
    }
    _following = atUs;
    final project = ref
        .read(editorControllerProvider(projectId))
        .value
        ?.project;
    if (project == null) return;
    final timeline = project.timeline;
    final layout = TimelineLayout.of(timeline);
    final engine = ref.read(editorEngineProvider);

    Future<Uint8List?> frame(String mediaId, int sourceUs) async {
      final path = _path(project, mediaId);
      if (path == null) return null;
      try {
        return await engine.previewFrame(
          path,
          sourceUs,
          maxSize: _frameSize,
          exact: true,
        );
      } on Failure {
        return null;
      }
    }

    final span = layout.spanAt(atUs);
    final clip = span?.clip;
    final clipImage = clip == null || clip.isPhoto
        ? null
        : await frame(
            clip.mediaId,
            timeline.keyframeTimeAt(
                  (kind: KeyframeOwnerKind.clip, id: clip.id),
                  atUs,
                  layout,
                ) ??
                clip.sourceInUs,
          );
    final overlays = <String, Uint8List>{};
    for (final o in timeline.overlayClips) {
      if (o.isPhoto || !overlayShowsAt(o, atUs, layout)) continue;
      final sourceUs = timeline.keyframeTimeAt(
        (kind: KeyframeOwnerKind.overlay, id: o.id),
        atUs,
        layout,
      );
      if (sourceUs == null) continue;
      final image = await frame(o.mediaId, sourceUs);
      if (image != null) overlays[o.id] = image;
    }
    if (!ref.mounted || _following != atUs) return;
    state = CanvasFrames(
      atUs: atUs,
      clipId: clip?.id,
      clipImage: clipImage,
      overlayImages: overlays,
    );
  }

  /// The edit ended: the preview shows the composition again once the
  /// engine shows the edit (until then the frames stay, so the old picture
  /// does not flash back). Call after the edit's document was sent.
  void end() {
    _following = null;
    if (state == null) return;
    final sent = ref
        .read(editorControllerProvider(projectId).notifier)
        .sentDocumentVersion;
    void clear() {
      unawaited(_waitForEngine?.cancel());
      _waitForEngine = null;
      if (ref.mounted && _following == null) state = null;
    }

    unawaited(_waitForEngine?.cancel());
    _waitForEngine = ref
        .read(editorEngineProvider)
        .playbackState
        .where((p) => p.documentVersion >= sent)
        .timeout(_engineWait, onTimeout: (sink) => sink.close())
        .listen((_) => clear(), onDone: clear);
  }

  /// The file to read [mediaId]'s frames from: its preview copy when there
  /// is one.
  String? _path(Project project, String mediaId) {
    final asset = project.media[mediaId];
    if (asset == null) return null;
    final store = ref.read(projectStoreProvider);
    final proxy = asset.proxyPath == null
        ? null
        : store.resolve(projectId, asset.proxyPath!);
    return proxy != null && File(proxy).existsSync()
        ? proxy
        : store.resolve(projectId, asset.path);
  }
}
