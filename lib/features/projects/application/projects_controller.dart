import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/features/projects/domain/project.dart';

part 'projects_controller.g.dart';

/// Projects on the home grid, most recently edited first.
@Riverpod(keepAlive: true)
class ProjectsController extends _$ProjectsController {
  @override
  Future<List<ProjectSummary>> build() =>
      ref.watch(projectStoreProvider).list();

  /// Reloads the list, keeping the current grid on screen meanwhile.
  Future<void> refresh() async {
    state = await AsyncValue.guard<List<ProjectSummary>>(
      ref.read(projectStoreProvider).list,
    );
  }

  Future<void> rename(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await ref.read(projectStoreProvider).rename(id, trimmed);
    await refresh();
  }

  Future<void> duplicate(String id, {required String name}) async {
    await ref.read(projectStoreProvider).duplicate(id, name: name);
    await refresh();
  }

  Future<void> delete(String id) async {
    // Remove from the grid immediately; the files follow.
    final current = state.value;
    if (current != null) {
      state = AsyncData([
        for (final p in current)
          if (p.id != id) p,
      ]);
    }
    await ref.read(projectStoreProvider).delete(id);
  }
}
