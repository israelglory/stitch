// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'projects_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Projects on the home grid, most recently edited first.

@ProviderFor(ProjectsController)
final projectsControllerProvider = ProjectsControllerProvider._();

/// Projects on the home grid, most recently edited first.
final class ProjectsControllerProvider
    extends $AsyncNotifierProvider<ProjectsController, List<ProjectSummary>> {
  /// Projects on the home grid, most recently edited first.
  ProjectsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectsControllerHash();

  @$internal
  @override
  ProjectsController create() => ProjectsController();
}

String _$projectsControllerHash() =>
    r'79684454ddb8daad6965b5f8d9329d77d7bb9fe8';

/// Projects on the home grid, most recently edited first.

abstract class _$ProjectsController
    extends $AsyncNotifier<List<ProjectSummary>> {
  FutureOr<List<ProjectSummary>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ProjectSummary>>, List<ProjectSummary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ProjectSummary>>,
                List<ProjectSummary>
              >,
              AsyncValue<List<ProjectSummary>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
