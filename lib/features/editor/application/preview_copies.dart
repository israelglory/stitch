import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/core/logging/logger.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';

part 'preview_copies.g.dart';

const _log = Logger('preview-copies');

/// Makes the missing preview copies of the open project, one at a time,
/// in the background. The state is how many are still to make.
///
/// Import makes a copy only when the device decodes the source in
/// hardware; others (4K at 60 fps on a mid-range phone, say) need a
/// software decoder and take minutes, so they are made here instead, as
/// are copies an older import could not make. Until a copy is ready,
/// preview reads the original, which such a device may not play.
///
/// A copy that could not be made is recorded on the media
/// ([MediaAsset.previewCopyFailed]) and not tried again until [retry].
@riverpod
class PreviewCopies extends _$PreviewCopies {
  bool _running = false;

  /// Media tried this session, so a failure is not retried in a loop.
  final _tried = <String>{};

  @override
  int build(String projectId) {
    ref.listen(editorControllerProvider(projectId), (_, next) {
      if (next.hasValue) _start();
    }, fireImmediately: true);
    return 0;
  }

  /// Tries again the copies that failed.
  void retry() {
    final editor = ref.read(editorControllerProvider(projectId));
    final project = editor.value?.project;
    if (project == null) return;
    final controller = ref.read(editorControllerProvider(projectId).notifier);
    for (final asset in project.media.values) {
      if (asset.previewCopyFailed) {
        _tried.remove(asset.id);
        controller.setPreviewCopy(asset.id);
      }
    }
    _start();
  }

  void _start() {
    if (_running) return;
    _running = true;
    // On the next event, not now: this can run while a provider builds,
    // and attaching a copy updates the editor.
    unawaited(Future<void>(_run));
  }

  Future<void> _run() async {
    final store = ref.read(projectStoreProvider);
    final engine = ref.read(editorEngineProvider);
    try {
      while (ref.mounted) {
        final missing = _missing();
        state = missing.length;
        if (missing.isEmpty) return;
        final asset = missing.first;
        _tried.add(asset.id);
        final relative = asset.previewCopyPath;
        final out = File(store.resolve(projectId, relative));
        var made = false;
        try {
          // A copy finished after the editor last closed is already there
          // (it is written under another name, then renamed).
          if (!out.existsSync()) {
            await out.parent.create(recursive: true);
            await engine.createProxy(
              store.resolve(projectId, asset.path),
              out.path,
            );
          }
          made = out.existsSync();
        } on Failure catch (e) {
          _log.warning('No preview copy for ${asset.id}', e);
        }
        if (!ref.mounted) return;
        ref
            .read(editorControllerProvider(projectId).notifier)
            .setPreviewCopy(
              asset.id,
              proxyPath: made ? relative : null,
              failed: !made,
            );
      }
    } finally {
      _running = false;
    }
  }

  /// Media in use that wants a copy and has none (or lost it), not yet
  /// tried this session.
  List<MediaAsset> _missing() {
    final state = ref.read(editorControllerProvider(projectId)).value;
    if (state == null) return const [];
    final project = state.project;
    final store = ref.read(projectStoreProvider);
    final inUse = {for (final c in project.timeline.videoClips) c.mediaId};
    return [
      for (final asset in project.media.values)
        if (inUse.contains(asset.id) &&
            asset.wantsPreviewCopy &&
            !asset.previewCopyFailed &&
            !_tried.contains(asset.id) &&
            !state.missingMedia.contains(asset.id) &&
            (asset.proxyPath == null ||
                !File(store.resolve(projectId, asset.proxyPath!)).existsSync()))
          asset,
    ];
  }
}
