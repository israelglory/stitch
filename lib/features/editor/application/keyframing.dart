import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/timeline/domain/keyframes.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
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
  final state = ref.watch(_timelineProvider(projectId));
  final position = ref.watch(
    playbackControllerProvider.select((p) => p.positionUs),
  );
  if (state == null) return null;
  final (timeline, layout) = state;
  if (timeline.keyframeTimeAt(owner, position, layout) == null) return null;
  return (owner: owner, current: timeline.keyframeAt(owner, position, layout));
}

/// The timeline and its layout, which changes only with the timeline, so
/// the providers above do not rebuild it at every playback tick.
@riverpod
(Timeline, TimelineLayout)? _timeline(Ref ref, String projectId) {
  final timeline = ref.watch(
    editorControllerProvider(projectId).select((s) => s.value?.timeline),
  );
  return timeline == null ? null : (timeline, TimelineLayout.of(timeline));
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
  final state = ref.watch(_timelineProvider(projectId));
  final position = ref.watch(
    playbackControllerProvider.select((p) => p.positionUs),
  );
  if (state == null) return null;
  final (timeline, layout) = state;
  return timeline.valuesAt((kind: kind, id: id), position, layout);
}
