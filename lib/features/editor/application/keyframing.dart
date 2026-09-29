import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/models.dart';

part 'keyframing.g.dart';

/// What the keyframe button acts on, when it can: the selected item, and
/// the keyframe under the playhead (null: it adds one).
typedef KeyframeTarget = ({KeyframeOwner owner, Keyframe? current});

/// The keyframe button's target; null (disabled) with nothing selected or
/// with the playhead outside the selected item. Changes only when the
/// target does, not with every playback tick.
@riverpod
KeyframeTarget? keyframeTarget(Ref ref, String projectId) {
  final owner = ref.watch(
    editorControllerProvider(projectId).select(
      (s) => s.value == null ? null : keyframeOwnerOf(s.value!.selection),
    ),
  );
  if (owner == null) return null;
  final timeline = ref.watch(
    editorControllerProvider(projectId).select((s) => s.value?.timeline),
  );
  final position = ref.watch(
    playbackControllerProvider.select((p) => p.positionUs),
  );
  if (timeline == null || timeline.keyframeTimeAt(owner, position) == null) {
    return null;
  }
  return (owner: owner, current: timeline.keyframeAt(owner, position));
}

/// Values of the selected item at the playhead: what sliders and canvas
/// gestures start from.
@riverpod
KeyframeValues? valuesAtPlayhead(
  Ref ref,
  String projectId,
  KeyframeOwnerKind kind,
  String id,
) {
  final owner = (kind: kind, id: id);
  final timeline = ref.watch(
    editorControllerProvider(projectId).select((s) => s.value?.timeline),
  );
  final position = ref.watch(
    playbackControllerProvider.select((p) => p.positionUs),
  );
  return timeline?.valuesAt(owner, position);
}
