import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/timeline/domain/composition.dart';

part 'resolved_texts.g.dart';

/// The project's timeline resolved to absolute times. Recomputed when the
/// timeline changes, not with the playhead.
@riverpod
ResolvedComposition? resolvedComposition(Ref ref, String projectId) {
  final timeline = ref.watch(
    editorControllerProvider(projectId).select((s) => s.value?.timeline),
  );
  return timeline == null ? null : ResolvedComposition.resolve(timeline);
}

/// The project's text items at their times on the timeline.
@riverpod
List<ResolvedText> resolvedTexts(Ref ref, String projectId) =>
    ref.watch(resolvedCompositionProvider(projectId))?.texts ?? const [];
