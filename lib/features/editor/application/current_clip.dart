import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/timeline/domain/models.dart';

part 'current_clip.g.dart';

/// The clip under the playhead. Recomputed as the playhead moves, but only
/// notifies when the clip changes, so the preview does not rebuild every
/// frame.
@riverpod
VideoClip? clipAtPlayhead(Ref ref, String projectId) {
  final layout = ref.watch(
    editorControllerProvider(projectId).select((s) => s.value?.layout),
  );
  final position = ref.watch(
    playbackControllerProvider.select((p) => p.positionUs),
  );
  return layout?.spanAt(position)?.clip;
}
