import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/async/cancellation.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/features/media/domain/library_item.dart';
import 'package:stitch/features/projects/application/projects_controller.dart';
import 'package:stitch/features/projects/data/media_importer.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';

part 'import_controller.g.dart';

/// State of the current import.
sealed class ImportState {
  const new();
}

final class ImportIdle extends ImportState {
  const new();
}

final class ImportRunning extends ImportState {
  const new(this.progress);

  final ImportProgress progress;
}

final class ImportFailed extends ImportState {
  const new(this.failure);

  final Failure failure;
}

/// Clips for [assets], in order. Photos get the default photo length.
List<VideoClip> clipsFor(List<MediaAsset> assets, String Function() newId) => [
  for (final a in assets)
    if (a.kind == MediaKind.photo)
      VideoClip.photo(id: newId(), mediaId: a.id)
    // Shorter than the shortest clip: nothing to edit (and it would break
    // the minimum), so it is left out.
    else if ((a.durationUs ?? 0) >= TimelineLimits.minDurationUs)
      VideoClip.video(
        id: newId(),
        mediaId: a.id,
        mediaDurationUs: a.durationUs!,
      ),
];

/// Imports picked media, either into a new project or an existing one.
/// Only one import runs at a time.
@Riverpod(keepAlive: true)
class ImportController extends _$ImportController {
  CancellationToken? _cancel;

  @override
  ImportState build() => const ImportIdle();

  void cancel() => _cancel?.cancel();

  void reset() => state = const ImportIdle();

  /// Creates a project named [name] with [items] on the main track and
  /// returns its id, or null when cancelled or failed (see [state]). A
  /// cancelled or failed project is removed.
  Future<String?> createProject({
    required String name,
    required AspectPreset preset,
    required List<LibraryItem> items,
  }) async {
    final store = ref.read(projectStoreProvider);
    final first = items.isEmpty ? null : items.first;
    final Project project;
    try {
      project = await store.create(
        name: name,
        canvas: ProjectCanvas.forPreset(
          preset,
          original: first == null ? null : (first.width, first.height),
        ),
      );
    } on Object catch (e, st) {
      state = ImportFailed(_failure(e, st));
      return null;
    }
    final assets = await importInto(project.id, items);
    if (assets == null) {
      await _discard(project.id);
      return null;
    }
    final ids = ref.read(idGeneratorProvider);
    try {
      await store.save(
        project.copyWith(
          media: {for (final a in assets) a.id: a},
          timeline: Timeline(videoClips: clipsFor(assets, ids.next)),
        ),
      );
    } on Object catch (e, st) {
      // The media fit but the project could not be written: nothing half
      // made stays behind.
      await _discard(project.id);
      state = ImportFailed(_failure(e, st));
      return null;
    }
    ref.invalidate(projectsControllerProvider);
    state = const ImportIdle();
    return project.id;
  }

  Future<void> _discard(String projectId) async {
    try {
      await ref.read(projectStoreProvider).delete(projectId);
    } on Object {
      // Already gone, or the disk refuses; the index rebuild skips it.
    }
  }

  static Failure _failure(Object e, StackTrace st) =>
      e is Failure ? e : UnexpectedFailure(cause: e, stackTrace: st);

  /// Copies [items] into project [projectId]. Returns the new assets, or
  /// null when cancelled or failed.
  Future<List<MediaAsset>?> importInto(
    String projectId,
    List<LibraryItem> items,
  ) async {
    final cancel = _cancel = CancellationToken();
    state = ImportRunning(ImportProgress(completed: 0, total: items.length));
    try {
      final assets = await ref
          .read(mediaImporterProvider)
          .import(
            projectId,
            items,
            cancel: cancel,
            onProgress: (p) => state = ImportRunning(p),
          );
      state = const ImportIdle();
      return assets;
    } on CancelledFailure {
      state = const ImportIdle();
      return null;
    } on Object catch (e, st) {
      state = ImportFailed(_failure(e, st));
      return null;
    } finally {
      if (identical(_cancel, cancel)) _cancel = null;
    }
  }
}
