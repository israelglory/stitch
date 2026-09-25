// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns an open project. All edits go through [apply] (or a gesture),
/// which records undo history, autosaves, and keeps the engine in sync.

@ProviderFor(EditorController)
final editorControllerProvider = EditorControllerFamily._();

/// Owns an open project. All edits go through [apply] (or a gesture),
/// which records undo history, autosaves, and keeps the engine in sync.
final class EditorControllerProvider
    extends $AsyncNotifierProvider<EditorController, EditorState> {
  /// Owns an open project. All edits go through [apply] (or a gesture),
  /// which records undo history, autosaves, and keeps the engine in sync.
  EditorControllerProvider._({
    required EditorControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'editorControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$editorControllerHash();

  @override
  String toString() {
    return r'editorControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EditorController create() => EditorController();

  @override
  bool operator ==(Object other) {
    return other is EditorControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$editorControllerHash() => r'9146a5d5d16eb399e30f502d9b6e78e16065d860';

/// Owns an open project. All edits go through [apply] (or a gesture),
/// which records undo history, autosaves, and keeps the engine in sync.

final class EditorControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          EditorController,
          AsyncValue<EditorState>,
          EditorState,
          FutureOr<EditorState>,
          String
        > {
  EditorControllerFamily._()
    : super(
        retry: null,
        name: r'editorControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Owns an open project. All edits go through [apply] (or a gesture),
  /// which records undo history, autosaves, and keeps the engine in sync.

  EditorControllerProvider call(String projectId) =>
      EditorControllerProvider._(argument: projectId, from: this);

  @override
  String toString() => r'editorControllerProvider';
}

/// Owns an open project. All edits go through [apply] (or a gesture),
/// which records undo history, autosaves, and keeps the engine in sync.

abstract class _$EditorController extends $AsyncNotifier<EditorState> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  FutureOr<EditorState> build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<EditorState>, EditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EditorState>, EditorState>,
              AsyncValue<EditorState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
