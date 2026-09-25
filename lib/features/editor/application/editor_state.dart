import 'package:meta/meta.dart';
import 'package:stitch/features/editor/domain/edit_history.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// What is selected on the timeline. Decides the context toolbar.
@immutable
sealed class Selection {
  const new();
}

final class NoSelection extends Selection {
  const new();

  @override
  bool operator ==(Object other) => other is NoSelection;

  @override
  int get hashCode => 0;
}

/// Something with an id: a clip, text, caption, or audio item.
sealed class ItemSelection extends Selection {
  const new(this.id);

  final String id;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is ItemSelection &&
      other.id == id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}

final class ClipSelected extends ItemSelection {
  const new(super.id);
}

final class TextSelected extends ItemSelection {
  const new(super.id);
}

final class CaptionSelected extends ItemSelection {
  const new(super.id);
}

final class AudioSelected extends ItemSelection {
  const new(super.id);
}

/// Everything the editor screen shows except the playhead, which lives in
/// the playback controller so it can change every frame without rebuilding
/// this state.
final class EditorState {
  new({
    required this.history,
    this.selection = const NoSelection(),
    this.missingMedia = const {},
    this.liveTexts = const {},
    this.saveFailed = false,
  });

  /// Project snapshots. Every edit, including canvas and background
  /// changes, is one undoable step.
  final EditHistory<Project> history;
  final Selection selection;

  /// Media whose imported file was gone when last checked (on opening
  /// and after a relink). Kept through edits and undo, so a clip that
  /// comes back with an undo still shows as missing.
  final Set<String> missingMedia;

  /// Of [missingMedia], what the timeline uses now: a missing clip that
  /// was deleted no longer counts.
  late final Set<String> missingInUse = {
    for (final id in missingMedia)
      if (timeline.videoClips.any((c) => c.mediaId == id) ||
          timeline.audioItems.any((a) => a.mediaId == id))
        id,
  };

  /// Text items the editor draws over the preview itself instead of the
  /// engine: the selected one, so editing is instant, and any just
  /// deselected until the engine shows them.
  final Set<String> liveTexts;

  /// The last save failed (a full disk, say); edits are kept in memory
  /// and saved again on the next change or Retry.
  final bool saveFailed;

  Project get project => history.present;
  Timeline get timeline => project.timeline;

  /// Computed once per state; many widgets read it.
  late final TimelineLayout layout = TimelineLayout.of(timeline);

  bool get canUndo => history.canUndo;
  bool get canRedo => history.canRedo;

  EditorState copyWith({
    EditHistory<Project>? history,
    Selection? selection,
    Set<String>? missingMedia,
    Set<String>? liveTexts,
    bool? saveFailed,
  }) => EditorState(
    history: history ?? this.history,
    selection: selection ?? this.selection,
    missingMedia: missingMedia ?? this.missingMedia,
    liveTexts: liveTexts ?? this.liveTexts,
    saveFailed: saveFailed ?? this.saveFailed,
  );
}
