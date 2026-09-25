// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exports a project: checks space, keeps the screen on, renders, writes
/// the captions file if asked, then saves to the photo library. Lives
/// while the export screen shows it; leaving cancels.

@ProviderFor(ExportController)
final exportControllerProvider = ExportControllerFamily._();

/// Exports a project: checks space, keeps the screen on, renders, writes
/// the captions file if asked, then saves to the photo library. Lives
/// while the export screen shows it; leaving cancels.
final class ExportControllerProvider
    extends $NotifierProvider<ExportController, ExportState> {
  /// Exports a project: checks space, keeps the screen on, renders, writes
  /// the captions file if asked, then saves to the photo library. Lives
  /// while the export screen shows it; leaving cancels.
  ExportControllerProvider._({
    required ExportControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exportControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exportControllerHash();

  @override
  String toString() {
    return r'exportControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ExportController create() => ExportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExportControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exportControllerHash() => r'877fe9f581b0621623980680104bcda45ee0b60c';

/// Exports a project: checks space, keeps the screen on, renders, writes
/// the captions file if asked, then saves to the photo library. Lives
/// while the export screen shows it; leaving cancels.

final class ExportControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ExportController,
          ExportState,
          ExportState,
          ExportState,
          String
        > {
  ExportControllerFamily._()
    : super(
        retry: null,
        name: r'exportControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Exports a project: checks space, keeps the screen on, renders, writes
  /// the captions file if asked, then saves to the photo library. Lives
  /// while the export screen shows it; leaving cancels.

  ExportControllerProvider call(String projectId) =>
      ExportControllerProvider._(argument: projectId, from: this);

  @override
  String toString() => r'exportControllerProvider';
}

/// Exports a project: checks space, keeps the screen on, renders, writes
/// the captions file if asked, then saves to the photo library. Lives
/// while the export screen shows it; leaving cancels.

abstract class _$ExportController extends $Notifier<ExportState> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  ExportState build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ExportState, ExportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExportState, ExportState>,
              ExportState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
