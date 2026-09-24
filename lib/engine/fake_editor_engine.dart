import 'dart:async';
import 'dart:convert';

import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/engine/editor_engine.dart';

/// In-memory engine for tests and for building UI without native code.
///
/// Playback advances on a timer; export reports progress in ten steps.
/// The duration comes from the composition's `durationUs` when present,
/// otherwise from [durationUs].
class FakeEditorEngine implements EditorEngine {
  new({this.durationUs = 0, this.tick = const Duration(milliseconds: 33)});

  /// Total duration reported for any composition.
  int durationUs;

  /// Interval between position updates while playing.
  final Duration tick;

  /// Last document received, for assertions in tests.
  String? lastDocument;

  /// Answers [probe]; null makes probing fail, as when the engine cannot
  /// read a file. Tests set this to describe their media.
  MediaInfo? Function(String path)? probeHandler;

  /// Paths passed to [createProxy], for assertions.
  final proxies = <String>[];

  final _state = StreamController<PlaybackState>.broadcast();
  PlaybackState _current = PlaybackState.idle;
  Timer? _timer;

  PlaybackState get current => _current;

  @override
  Stream<PlaybackState> get playbackState {
    // Deliver the current state to each new listener first, like the
    // native engines do, so late subscribers never miss the duration.
    late final StreamController<PlaybackState> controller;
    StreamSubscription<PlaybackState>? sub;
    controller = StreamController<PlaybackState>(
      onListen: () {
        controller.add(_current);
        sub = _state.stream.listen(controller.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<int?> createPreview() async => null;

  @override
  Future<void> setDocument(String documentJson) async {
    lastDocument = documentJson;
    try {
      final json = jsonDecode(documentJson);
      final composition = json is Map<String, dynamic>
          ? json['composition']
          : null;
      if (composition is Map<String, dynamic> &&
          composition['durationUs'] is int) {
        durationUs = composition['durationUs'] as int;
      }
    } on FormatException {
      // Tests may pass arbitrary payloads; keep the configured duration.
    }
    _emit(
      _current.copyWith(
        durationUs: durationUs,
        positionUs: _current.positionUs.clamp(0, durationUs),
      ),
    );
  }

  @override
  Future<void> play() async {
    if (_current.isPlaying) return;
    if (_current.positionUs >= _current.durationUs) {
      _emit(_current.copyWith(positionUs: 0));
    }
    _emit(_current.copyWith(isPlaying: true));
    _timer = Timer.periodic(tick, (_) {
      final next = _current.positionUs + tick.inMicroseconds;
      if (next >= _current.durationUs) {
        _timer?.cancel();
        _emit(
          _current.copyWith(positionUs: _current.durationUs, isPlaying: false),
        );
      } else {
        _emit(_current.copyWith(positionUs: next));
      }
    });
  }

  @override
  Future<void> pause() async {
    _timer?.cancel();
    _emit(_current.copyWith(isPlaying: false));
  }

  @override
  Future<void> seek(int positionUs, {bool exact = true}) async {
    _emit(
      _current.copyWith(positionUs: positionUs.clamp(0, _current.durationUs)),
    );
  }

  @override
  ExportJob export(ExportSettings settings) => _FakeExportJob(settings);

  @override
  Future<MediaInfo> probe(String path) async {
    final info = probeHandler?.call(path);
    if (info == null) throw EngineFailure('probe_unavailable', cause: path);
    return info;
  }

  @override
  Future<List<String?>> thumbnails(
    String path,
    List<int> timesUs, {
    required int maxSize,
    required String outDir,
  }) async => [for (final _ in timesUs) null];

  @override
  Future<void> createProxy(String path, String outPath) async {
    proxies.add(path);
  }

  @override
  Future<EngineCapabilities> capabilities() async => EngineCapabilities.basic;

  @override
  Future<void> release() async {
    _timer?.cancel();
    _emit(PlaybackState.idle);
  }

  /// Closes the state stream. Only for tests; the real engines live for the
  /// app's lifetime.
  Future<void> dispose() async {
    _timer?.cancel();
    await _state.close();
  }

  void _emit(PlaybackState state) {
    _current = state;
    _state.add(state);
  }
}

class _FakeExportJob implements ExportJob {
  new(this._settings) {
    unawaited(_run());
  }

  final ExportSettings _settings;
  final _events = StreamController<ExportEvent>();
  bool _cancelled = false;

  @override
  Stream<ExportEvent> get events => _events.stream;

  Future<void> _run() async {
    for (var step = 1; step <= 10; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_cancelled) return;
      _events.add(ExportProgress(step / 10));
    }
    _events.add(ExportCompleted(_settings.outputPath));
    await _events.close();
  }

  @override
  Future<void> cancel() async {
    if (_cancelled || _events.isClosed) return;
    _cancelled = true;
    _events.addError(const CancelledFailure());
    await _events.close();
  }
}
