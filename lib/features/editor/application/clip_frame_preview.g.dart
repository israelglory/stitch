// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_frame_preview.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The preview while a clip is edited by hand: while its trim handle is
/// dragged, as in CapCut, the frame at the handle (the clip's new first
/// frame, or its new last one); while it is moved, zoomed, or turned on
/// the canvas, its frame at the playhead, drawn where it now is.
///
/// Frames come from the engine straight from the file (its preview copy
/// when there is one), not through the composition, which would be rebuilt
/// for every step of the drag. While the finger moves they are the nearest
/// quick frames; once it rests, the exact one. Only the newest position is
/// asked for: steps that arrive during a request are skipped.

@ProviderFor(ClipFramePreview)
final clipFramePreviewProvider = ClipFramePreviewFamily._();

/// The preview while a clip is edited by hand: while its trim handle is
/// dragged, as in CapCut, the frame at the handle (the clip's new first
/// frame, or its new last one); while it is moved, zoomed, or turned on
/// the canvas, its frame at the playhead, drawn where it now is.
///
/// Frames come from the engine straight from the file (its preview copy
/// when there is one), not through the composition, which would be rebuilt
/// for every step of the drag. While the finger moves they are the nearest
/// quick frames; once it rests, the exact one. Only the newest position is
/// asked for: steps that arrive during a request are skipped.
final class ClipFramePreviewProvider
    extends $NotifierProvider<ClipFramePreview, ClipFrameImage?> {
  /// The preview while a clip is edited by hand: while its trim handle is
  /// dragged, as in CapCut, the frame at the handle (the clip's new first
  /// frame, or its new last one); while it is moved, zoomed, or turned on
  /// the canvas, its frame at the playhead, drawn where it now is.
  ///
  /// Frames come from the engine straight from the file (its preview copy
  /// when there is one), not through the composition, which would be rebuilt
  /// for every step of the drag. While the finger moves they are the nearest
  /// quick frames; once it rests, the exact one. Only the newest position is
  /// asked for: steps that arrive during a request are skipped.
  ClipFramePreviewProvider._({
    required ClipFramePreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clipFramePreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clipFramePreviewHash();

  @override
  String toString() {
    return r'clipFramePreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ClipFramePreview create() => ClipFramePreview();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClipFrameImage? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClipFrameImage?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClipFramePreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clipFramePreviewHash() => r'4e7a2518c7fad535095b70bb32285608dc71fd40';

/// The preview while a clip is edited by hand: while its trim handle is
/// dragged, as in CapCut, the frame at the handle (the clip's new first
/// frame, or its new last one); while it is moved, zoomed, or turned on
/// the canvas, its frame at the playhead, drawn where it now is.
///
/// Frames come from the engine straight from the file (its preview copy
/// when there is one), not through the composition, which would be rebuilt
/// for every step of the drag. While the finger moves they are the nearest
/// quick frames; once it rests, the exact one. Only the newest position is
/// asked for: steps that arrive during a request are skipped.

final class ClipFramePreviewFamily extends $Family
    with
        $ClassFamilyOverride<
          ClipFramePreview,
          ClipFrameImage?,
          ClipFrameImage?,
          ClipFrameImage?,
          String
        > {
  ClipFramePreviewFamily._()
    : super(
        retry: null,
        name: r'clipFramePreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The preview while a clip is edited by hand: while its trim handle is
  /// dragged, as in CapCut, the frame at the handle (the clip's new first
  /// frame, or its new last one); while it is moved, zoomed, or turned on
  /// the canvas, its frame at the playhead, drawn where it now is.
  ///
  /// Frames come from the engine straight from the file (its preview copy
  /// when there is one), not through the composition, which would be rebuilt
  /// for every step of the drag. While the finger moves they are the nearest
  /// quick frames; once it rests, the exact one. Only the newest position is
  /// asked for: steps that arrive during a request are skipped.

  ClipFramePreviewProvider call(String projectId) =>
      ClipFramePreviewProvider._(argument: projectId, from: this);

  @override
  String toString() => r'clipFramePreviewProvider';
}

/// The preview while a clip is edited by hand: while its trim handle is
/// dragged, as in CapCut, the frame at the handle (the clip's new first
/// frame, or its new last one); while it is moved, zoomed, or turned on
/// the canvas, its frame at the playhead, drawn where it now is.
///
/// Frames come from the engine straight from the file (its preview copy
/// when there is one), not through the composition, which would be rebuilt
/// for every step of the drag. While the finger moves they are the nearest
/// quick frames; once it rests, the exact one. Only the newest position is
/// asked for: steps that arrive during a request are skipped.

abstract class _$ClipFramePreview extends $Notifier<ClipFrameImage?> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  ClipFrameImage? build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ClipFrameImage?, ClipFrameImage?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClipFrameImage?, ClipFrameImage?>,
              ClipFrameImage?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
