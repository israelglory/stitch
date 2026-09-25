import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

  /// Answers [waveform]; by default, a gentle wave for any file.
  List<double> Function(String path, int peaksPerSecond)? waveformHandler;

  /// Last volume set with [setPreviewVolume].
  double previewVolume = 1;

  /// Settings of the last [export], for assertions.
  ExportSettings? lastExport;

  /// Makes the next [export] fail with this.
  Object? exportFailure;

  /// Time between an export's ten progress steps.
  Duration exportStep = const Duration(milliseconds: 50);

  /// Documents passed to [speechAudio], for assertions.
  final speechDocuments = <String>[];

  /// What [speechAudio] writes: 16 kHz mono samples. Empty by default.
  Float32List speechSamples = Float32List(0);

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
    var version = _current.documentVersion;
    try {
      final json = jsonDecode(documentJson);
      final composition = json is Map<String, dynamic>
          ? json['composition']
          : null;
      if (composition is Map<String, dynamic> &&
          composition['durationUs'] is int) {
        durationUs = composition['durationUs'] as int;
      }
      if (json is Map<String, dynamic> && json['version'] is int) {
        version = json['version'] as int;
      }
    } on FormatException {
      // Tests may pass arbitrary payloads; keep the configured duration.
    }
    // The fake shows every document at once.
    _emit(
      _current.copyWith(
        durationUs: durationUs,
        positionUs: _current.positionUs.clamp(0, durationUs),
        documentVersion: version,
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
  ExportJob export(ExportSettings settings) {
    lastExport = settings;
    final failure = exportFailure;
    exportFailure = null;
    return _FakeExportJob(
      settings.outputPath,
      step: exportStep,
      failure: failure,
      write: () => File(settings.outputPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(const [0, 0, 0, 24]),
    );
  }

  @override
  ExportJob speechAudio(String documentJson, String outputPath) {
    speechDocuments.add(documentJson);
    final samples = speechSamples;
    return _FakeExportJob(
      outputPath,
      write: () => File(outputPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(samples.buffer.asUint8List()),
    );
  }

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
  Future<List<double>> waveform(
    String path, {
    required int peaksPerSecond,
  }) async =>
      waveformHandler?.call(path, peaksPerSecond) ??
      [for (var i = 0; i < peaksPerSecond * 4; i++) 0.3 + 0.2 * (i % 5) / 4];

  @override
  Future<void> setPreviewVolume(double volume) async {
    previewVolume = volume;
  }

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
  new(
    this._outputPath, {
    this._write,
    this._failure,
    this._step = const Duration(milliseconds: 50),
  }) {
    unawaited(_run());
  }

  final String _outputPath;
  final void Function()? _write;
  final Object? _failure;
  final Duration _step;
  final _events = StreamController<ExportEvent>();
  bool _cancelled = false;

  @override
  Stream<ExportEvent> get events => _events.stream;

  Future<void> _run() async {
    for (var step = 1; step <= 10; step++) {
      await Future<void>.delayed(_step);
      if (_cancelled) return;
      _events.add(ExportProgress(step / 10));
    }
    if (_failure case final failure?) {
      _events.addError(failure);
      await _events.close();
      return;
    }
    _write?.call();
    _events.add(ExportCompleted(_outputPath));
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
