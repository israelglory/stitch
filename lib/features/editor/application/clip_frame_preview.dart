import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/models.dart';

part 'clip_frame_preview.g.dart';

/// Long side of the frames shown while trimming, in pixels.
const int _frameSize = 720;

/// Longest the frame stays after an edit, if the engine never reports it.
const Duration _engineWait = Duration(seconds: 2);

/// How long the finger rests before the exact frame replaces the quick one.
const Duration _settleDelay = Duration(milliseconds: 150);

/// A frame of the clip being edited by hand, shown in place of the
/// preview.
@immutable
final class ClipFrameImage {
  const new({required this.clipId, required this.atUs, required this.image});

  final String clipId;

  /// Timeline time the frame belongs to: the clip's values there place it.
  final int atUs;

  /// JPEG bytes.
  final Uint8List image;
}

/// The preview while a clip is edited by hand: while its trim handle is
/// dragged, as in CapCut, the frame at the handle (the clip's new first
/// frame, or its new last one); while it is moved, zoomed, or turned on
/// the canvas, its frame at the playhead, drawn where it now is.
///
/// Frames come from the engine straight from the file (its preview copy
/// when there is one), not through the composition, which would be rebuilt
/// for every step of the drag. While the finger moves they are the nearest
/// quick frames; once it rests, the exact one. Only the newest position is
/// asked for: steps that arrive during a request are skipped.
@riverpod
class ClipFramePreview extends _$ClipFramePreview {
  ({String clipId, String path, int sourceUs, int atUs})? _target;
  ({String path, int sourceUs, bool exact})? _asked;
  bool _busy = false;
  Timer? _settle;
  StreamSubscription<Object>? _waitForEngine;

  @override
  ClipFrameImage? build(String projectId) {
    ref.onDispose(() {
      _settle?.cancel();
      unawaited(_waitForEngine?.cancel());
    });
    return null;
  }

  /// Shows [clipId]'s frame at [sourceUs] (source time).
  void follow(String clipId, int sourceUs) {
    final project = ref
        .read(editorControllerProvider(projectId))
        .value
        ?.project;
    final clip = project?.timeline.clipById(clipId);
    final asset = clip == null ? null : project!.media[clip.mediaId];
    if (clip == null || asset == null || clip.kind != MediaKind.video) return;
    final store = ref.read(projectStoreProvider);
    final proxy = asset.proxyPath == null
        ? null
        : store.resolve(projectId, asset.proxyPath!);
    final path = proxy != null && File(proxy).existsSync()
        ? proxy
        : store.resolve(projectId, asset.path);
    unawaited(_waitForEngine?.cancel());
    _waitForEngine = null;
    final atUs = project!.timeline.timelineTimeOfKeyframe((
      kind: KeyframeOwnerKind.clip,
      id: clipId,
    ), sourceUs);
    if (atUs == null) return;
    _target = (clipId: clipId, path: path, sourceUs: sourceUs, atUs: atUs);
    _settle?.cancel();
    _settle = Timer(_settleDelay, () => unawaited(_fetch()));
    unawaited(_fetch());
  }

  /// The edit ended: the preview shows the composition again, once the
  /// engine shows the edit (the frame stays until then, so the old picture
  /// does not flash back). Call after the edit's document was sent.
  void end() {
    _target = null;
    _asked = null;
    _settle?.cancel();
    if (state == null) return;
    final sent = ref
        .read(editorControllerProvider(projectId).notifier)
        .sentDocumentVersion;
    void clear() {
      unawaited(_waitForEngine?.cancel());
      _waitForEngine = null;
      if (ref.mounted && _target == null) state = null;
    }

    unawaited(_waitForEngine?.cancel());
    _waitForEngine = ref
        .read(editorEngineProvider)
        .playbackState
        .where((p) => p.documentVersion >= sent)
        .timeout(_engineWait, onTimeout: (sink) => sink.close())
        .listen((_) => clear(), onDone: clear);
  }

  Future<void> _fetch() async {
    if (_busy) return;
    _busy = true;
    final engine = ref.read(editorEngineProvider);
    try {
      while (ref.mounted) {
        final target = _target;
        if (target == null) return;
        final exact = !(_settle?.isActive ?? false);
        final want = (
          path: target.path,
          sourceUs: target.sourceUs,
          exact: exact,
        );
        if (want == _asked) return;
        _asked = want;
        Uint8List? image;
        try {
          image = await engine.previewFrame(
            want.path,
            want.sourceUs,
            maxSize: _frameSize,
            exact: exact,
          );
        } on Failure {
          image = null;
        }
        if (!ref.mounted || _target == null) return;
        if (image != null) {
          state = ClipFrameImage(
            clipId: target.clipId,
            atUs: target.atUs,
            image: image,
          );
        }
      }
    } finally {
      _busy = false;
    }
  }
}
