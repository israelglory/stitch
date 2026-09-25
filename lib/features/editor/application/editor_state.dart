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
  });

  /// Project snapshots. Every edit, including canvas and background
  /// changes, is one undoable step.
  final EditHistory<Project> history;
  final Selection selection;

  /// Media whose imported file is gone (shown as missing clips).
  final Set<String> missingMedia;

  /// Text items the editor draws over the preview itself instead of the
  /// engine: the selected one, so editing is instant, and any just
  /// deselected until the engine shows them.
  final Set<String> liveTexts;

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
  }) => EditorState(
    history: history ?? this.history,
    selection: selection ?? this.selection,
    missingMedia: missingMedia ?? this.missingMedia,
    liveTexts: liveTexts ?? this.liveTexts,
  );
}
