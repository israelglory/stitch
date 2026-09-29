// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trim_preview.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The preview while a clip's trim handle is dragged, as in CapCut: the
/// frame at the handle (the clip's new first frame, or its new last one),
/// instead of the frame under the playhead.
///
/// Frames come from the engine straight from the file (its preview copy
/// when there is one), not through the composition, which would be rebuilt
/// for every step of the drag. While the finger moves they are the nearest
/// quick frames; once it rests, the exact one. Only the newest position is
/// asked for: steps that arrive during a request are skipped.

@ProviderFor(TrimPreview)
final trimPreviewProvider = TrimPreviewFamily._();

/// The preview while a clip's trim handle is dragged, as in CapCut: the
/// frame at the handle (the clip's new first frame, or its new last one),
/// instead of the frame under the playhead.
///
/// Frames come from the engine straight from the file (its preview copy
/// when there is one), not through the composition, which would be rebuilt
/// for every step of the drag. While the finger moves they are the nearest
/// quick frames; once it rests, the exact one. Only the newest position is
/// asked for: steps that arrive during a request are skipped.
final class TrimPreviewProvider
    extends $NotifierProvider<TrimPreview, TrimFrame?> {
  /// The preview while a clip's trim handle is dragged, as in CapCut: the
  /// frame at the handle (the clip's new first frame, or its new last one),
  /// instead of the frame under the playhead.
  ///
  /// Frames come from the engine straight from the file (its preview copy
  /// when there is one), not through the composition, which would be rebuilt
  /// for every step of the drag. While the finger moves they are the nearest
  /// quick frames; once it rests, the exact one. Only the newest position is
  /// asked for: steps that arrive during a request are skipped.
  TrimPreviewProvider._({
    required TrimPreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'trimPreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trimPreviewHash();

  @override
  String toString() {
    return r'trimPreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TrimPreview create() => TrimPreview();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrimFrame? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrimFrame?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TrimPreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trimPreviewHash() => r'46453926ae29ad69fa6a14157a94e33f92218a90';

/// The preview while a clip's trim handle is dragged, as in CapCut: the
/// frame at the handle (the clip's new first frame, or its new last one),
/// instead of the frame under the playhead.
///
/// Frames come from the engine straight from the file (its preview copy
/// when there is one), not through the composition, which would be rebuilt
/// for every step of the drag. While the finger moves they are the nearest
/// quick frames; once it rests, the exact one. Only the newest position is
/// asked for: steps that arrive during a request are skipped.

final class TrimPreviewFamily extends $Family
    with
        $ClassFamilyOverride<
          TrimPreview,
          TrimFrame?,
          TrimFrame?,
          TrimFrame?,
          String
        > {
  TrimPreviewFamily._()
    : super(
        retry: null,
        name: r'trimPreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The preview while a clip's trim handle is dragged, as in CapCut: the
  /// frame at the handle (the clip's new first frame, or its new last one),
  /// instead of the frame under the playhead.
  ///
  /// Frames come from the engine straight from the file (its preview copy
  /// when there is one), not through the composition, which would be rebuilt
  /// for every step of the drag. While the finger moves they are the nearest
  /// quick frames; once it rests, the exact one. Only the newest position is
  /// asked for: steps that arrive during a request are skipped.

  TrimPreviewProvider call(String projectId) =>
      TrimPreviewProvider._(argument: projectId, from: this);

  @override
  String toString() => r'trimPreviewProvider';
}

/// The preview while a clip's trim handle is dragged, as in CapCut: the
/// frame at the handle (the clip's new first frame, or its new last one),
/// instead of the frame under the playhead.
///
/// Frames come from the engine straight from the file (its preview copy
/// when there is one), not through the composition, which would be rebuilt
/// for every step of the drag. While the finger moves they are the nearest
/// quick frames; once it rests, the exact one. Only the newest position is
/// asked for: steps that arrive during a request are skipped.

abstract class _$TrimPreview extends $Notifier<TrimFrame?> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  TrimFrame? build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TrimFrame?, TrimFrame?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TrimFrame?, TrimFrame?>,
              TrimFrame?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
