// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_frame_preview.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The preview while an overlay is moved, zoomed, turned, or faded by
/// hand. The engine is sent the edit only when it ends, and its picture
/// still has the overlay where it was, so the editor draws the whole
/// moment itself: the clip and every overlay, each placed by its values
/// as they change.
///
/// Frames come from the engine straight from the files (preview copies
/// when there are any), once per moment: the playhead stays put while
/// something is edited by hand.

@ProviderFor(CanvasFramePreview)
final canvasFramePreviewProvider = CanvasFramePreviewFamily._();

/// The preview while an overlay is moved, zoomed, turned, or faded by
/// hand. The engine is sent the edit only when it ends, and its picture
/// still has the overlay where it was, so the editor draws the whole
/// moment itself: the clip and every overlay, each placed by its values
/// as they change.
///
/// Frames come from the engine straight from the files (preview copies
/// when there are any), once per moment: the playhead stays put while
/// something is edited by hand.
final class CanvasFramePreviewProvider
    extends $NotifierProvider<CanvasFramePreview, CanvasFrames?> {
  /// The preview while an overlay is moved, zoomed, turned, or faded by
  /// hand. The engine is sent the edit only when it ends, and its picture
  /// still has the overlay where it was, so the editor draws the whole
  /// moment itself: the clip and every overlay, each placed by its values
  /// as they change.
  ///
  /// Frames come from the engine straight from the files (preview copies
  /// when there are any), once per moment: the playhead stays put while
  /// something is edited by hand.
  CanvasFramePreviewProvider._({
    required CanvasFramePreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'canvasFramePreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canvasFramePreviewHash();

  @override
  String toString() {
    return r'canvasFramePreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CanvasFramePreview create() => CanvasFramePreview();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CanvasFrames? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CanvasFrames?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CanvasFramePreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canvasFramePreviewHash() =>
    r'80c98cc8e90e4f684b27c6e94b15524bceba96fc';

/// The preview while an overlay is moved, zoomed, turned, or faded by
/// hand. The engine is sent the edit only when it ends, and its picture
/// still has the overlay where it was, so the editor draws the whole
/// moment itself: the clip and every overlay, each placed by its values
/// as they change.
///
/// Frames come from the engine straight from the files (preview copies
/// when there are any), once per moment: the playhead stays put while
/// something is edited by hand.

final class CanvasFramePreviewFamily extends $Family
    with
        $ClassFamilyOverride<
          CanvasFramePreview,
          CanvasFrames?,
          CanvasFrames?,
          CanvasFrames?,
          String
        > {
  CanvasFramePreviewFamily._()
    : super(
        retry: null,
        name: r'canvasFramePreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The preview while an overlay is moved, zoomed, turned, or faded by
  /// hand. The engine is sent the edit only when it ends, and its picture
  /// still has the overlay where it was, so the editor draws the whole
  /// moment itself: the clip and every overlay, each placed by its values
  /// as they change.
  ///
  /// Frames come from the engine straight from the files (preview copies
  /// when there are any), once per moment: the playhead stays put while
  /// something is edited by hand.

  CanvasFramePreviewProvider call(String projectId) =>
      CanvasFramePreviewProvider._(argument: projectId, from: this);

  @override
  String toString() => r'canvasFramePreviewProvider';
}

/// The preview while an overlay is moved, zoomed, turned, or faded by
/// hand. The engine is sent the edit only when it ends, and its picture
/// still has the overlay where it was, so the editor draws the whole
/// moment itself: the clip and every overlay, each placed by its values
/// as they change.
///
/// Frames come from the engine straight from the files (preview copies
/// when there are any), once per moment: the playhead stays put while
/// something is edited by hand.

abstract class _$CanvasFramePreview extends $Notifier<CanvasFrames?> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  CanvasFrames? build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CanvasFrames?, CanvasFrames?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CanvasFrames?, CanvasFrames?>,
              CanvasFrames?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
