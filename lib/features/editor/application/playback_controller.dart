import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/engine_provider.dart';

part 'playback_controller.g.dart';

/// Playhead and play state, mirrored from the engine. Updates at display
/// rate while playing, so widgets must `select` what they need; the
/// timeline listens instead of rebuilding.
@riverpod
class PlaybackController extends _$PlaybackController {
  late EditorEngine _engine;

  /// True while the user drags the timeline. Engine position updates are
  /// ignored then, so the playhead follows the finger, not the decoder.
  bool _scrubbing = false;

  @override
  PlaybackState build() {
    _engine = ref.watch(editorEngineProvider);
    final sub = _engine.playbackState.listen((s) {
      if (_scrubbing) {
        state = state.copyWith(
          durationUs: s.durationUs,
          isPlaying: s.isPlaying,
          isBuffering: s.isBuffering,
        );
      } else {
        state = s;
      }
    });
    ref.onDispose(sub.cancel);
    return PlaybackState.idle;
  }

  Future<void> toggle() => state.isPlaying ? pause() : play();

  /// Plays from the playhead; at the end, from the start again.
  Future<void> play() async {
    _scrubbing = false;
    final atEnd =
        state.durationUs > 0 &&
        state.positionUs >= state.durationUs - _endSlackUs;
    if (atEnd) await seek(0);
    await _engine.play();
  }

  /// Within this of the end counts as the end (a frame at 25 fps).
  static const _endSlackUs = 40000;

  Future<void> pause() => _engine.pause();

  /// Starts a scrub: pauses playback and takes over the playhead.
  void beginScrub() {
    _scrubbing = true;
    if (state.isPlaying) unawaited(_engine.pause());
  }

  /// Moves the playhead during a scrub, seeking fast (nearest keyframe).
  void scrubTo(int positionUs) {
    final clamped = positionUs.clamp(0, state.durationUs);
    state = state.copyWith(positionUs: clamped);
    unawaited(_engine.seek(clamped, exact: false));
  }

  /// Ends a scrub with an exact seek to where the playhead stopped.
  void endScrub() {
    _scrubbing = false;
    unawaited(_engine.seek(state.positionUs));
  }

  /// Jumps to [positionUs] (outside a scrub).
  Future<void> seek(int positionUs) {
    final clamped = positionUs.clamp(0, state.durationUs);
    state = state.copyWith(positionUs: clamped);
    return _engine.seek(clamped);
  }
}
