// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Playhead and play state, mirrored from the engine. Updates at display
/// rate while playing, so widgets must `select` what they need; the
/// timeline listens instead of rebuilding.

@ProviderFor(PlaybackController)
final playbackControllerProvider = PlaybackControllerProvider._();

/// Playhead and play state, mirrored from the engine. Updates at display
/// rate while playing, so widgets must `select` what they need; the
/// timeline listens instead of rebuilding.
final class PlaybackControllerProvider
    extends $NotifierProvider<PlaybackController, PlaybackState> {
  /// Playhead and play state, mirrored from the engine. Updates at display
  /// rate while playing, so widgets must `select` what they need; the
  /// timeline listens instead of rebuilding.
  PlaybackControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playbackControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playbackControllerHash();

  @$internal
  @override
  PlaybackController create() => PlaybackController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaybackState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaybackState>(value),
    );
  }
}

String _$playbackControllerHash() =>
    r'b185767f824f02c1db986a7dd9dfa7afe7dfffe6';

/// Playhead and play state, mirrored from the engine. Updates at display
/// rate while playing, so widgets must `select` what they need; the
/// timeline listens instead of rebuilding.

abstract class _$PlaybackController extends $Notifier<PlaybackState> {
  PlaybackState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlaybackState, PlaybackState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlaybackState, PlaybackState>,
              PlaybackState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
