import 'dart:async';

import 'package:flutter/services.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/pigeon/engine_api.g.dart';

/// [EditorEngine] backed by the native engine (AVFoundation on iOS; Media3
/// on Android) through Pigeon.
class NativeEditorEngine implements EditorEngine, EngineFlutterApi {
  new({EngineHostApi? host}) : _host = host ?? EngineHostApi() {
    EngineFlutterApi.setUp(this);
  }

  final EngineHostApi _host;
  final _state = StreamController<PlaybackState>.broadcast();
  PlaybackState _current = PlaybackState.idle;
  final _jobs = <String, _NativeExportJob>{};

  /// Events ([ExportEvent] or [Failure]) for jobs whose id the start call
  /// has not returned yet; replayed when it does.
  final _early = <String, List<Object>>{};

  @override
  Future<int?> createPreview() => _guard(_host.createPreview);

  @override
  Future<void> setDocument(String documentJson) =>
      _guard(() => _host.setDocument(documentJson));

  @override
  Future<void> play() => _guard(_host.play);

  @override
  Future<void> pause() => _guard(_host.pause);

  @override
  Future<void> seek(int positionUs, {bool exact = true}) =>
      _guard(() => _host.seek(positionUs, exact));

  @override
  Stream<PlaybackState> get playbackState {
    // Each listener gets the current state first, then changes.
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
  Future<MediaInfo> probe(String path) => _guard(() async {
    final m = await _host.probe(path);
    return MediaInfo(
      durationUs: m.durationUs,
      width: m.width,
      height: m.height,
      rotationDeg: m.rotationDeg,
      frameRate: m.frameRate,
      hasVideo: m.hasVideo,
      hasAudio: m.hasAudio,
      isHdr: m.isHdr,
    );
  });

  @override
  Future<List<String?>> thumbnails(
    String path,
    List<int> timesUs, {
    required int maxSize,
    required String outDir,
  }) => _guard(() => _host.thumbnails(path, timesUs, maxSize, outDir));

  @override
  Future<void> createProxy(String path, String outPath) =>
      _guard(() => _host.createProxy(path, outPath));

  @override
  Future<EngineCapabilities> capabilities() => _guard(() async {
    final c = await _host.capabilities();
    return EngineCapabilities(hevc: c.hevc, max4k: c.max4k);
  });

  @override
  Future<List<double>> waveform(String path, {required int peaksPerSecond}) =>
      _guard(() => _host.waveform(path, peaksPerSecond));

  @override
  Future<void> setPreviewVolume(double volume) =>
      _guard(() => _host.setPreviewVolume(volume));

  @override
  ExportJob export(ExportSettings settings) => _startJob(
    () => _host.startExport(
      ExportRequestMessage(
        outputPath: settings.outputPath,
        width: settings.width,
        height: settings.height,
        frameRate: settings.frameRate,
        videoBitrate: settings.bitrate,
        hevc: settings.codec == VideoCodec.hevc,
        progressTitle: settings.progressTitle,
      ),
    ),
  );

  @override
  ExportJob speechAudio(String documentJson, String outputPath) =>
      _startJob(() => _host.startSpeechAudio(documentJson, outputPath));

  /// A job reporting through the export callbacks, started by [start].
  ExportJob _startJob(Future<String> Function() start) {
    final job = _NativeExportJob(_host);
    unawaited(() async {
      try {
        final id = await start();
        _jobs[id] = job;
        await job.attach(id);
        for (final event in _early.remove(id) ?? const <Object>[]) {
          _deliver(id, job, event);
        }
      } on PlatformException catch (e, st) {
        job.fail(_failure(e, st));
      }
    }());
    return job;
  }

  @override
  Future<void> release() => _guard(_host.release);

  // EngineFlutterApi: callbacks from the native side.

  @override
  void onPlaybackState(PlaybackStateMessage state) {
    _current = PlaybackState(
      positionUs: state.positionUs,
      durationUs: state.durationUs,
      isPlaying: state.isPlaying,
      isBuffering: state.isBuffering,
      documentVersion: state.documentVersion,
    );
    _state.add(_current);
  }

  @override
  void onExportProgress(String jobId, double fraction) =>
      _route(jobId, ExportProgress(fraction));

  @override
  void onExportCompleted(String jobId, String outputPath) =>
      _route(jobId, ExportCompleted(outputPath));

  @override
  void onExportFailed(String jobId, String code, String message) =>
      _route(jobId, _failureFor(code, message));

  void _route(String jobId, Object event) {
    final job = _jobs[jobId];
    if (job == null) {
      (_early[jobId] ??= []).add(event);
    } else {
      _deliver(jobId, job, event);
    }
  }

  void _deliver(String jobId, _NativeExportJob job, Object event) {
    switch (event) {
      case final Failure failure:
        _jobs.remove(jobId);
        job.fail(failure);
      case final ExportCompleted done:
        _jobs.remove(jobId);
        job.emit(done);
      case final ExportEvent other:
        job.emit(other);
    }
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e, st) {
      throw _failure(e, st);
    }
  }

  static Failure _failure(PlatformException e, StackTrace st) =>
      _failureFor(e.code, e.message ?? '', stackTrace: st);

  static Failure _failureFor(
    String code,
    String message, {
    StackTrace? stackTrace,
  }) => switch (code) {
    'missing_file' => MissingSourceFailure(message, stackTrace: stackTrace),
    'unsupported_media' => UnsupportedMediaFailure(
      message,
      stackTrace: stackTrace,
    ),
    'cancelled' => const CancelledFailure(),
    _ => EngineFailure(code, cause: message, stackTrace: stackTrace),
  };
}

class _NativeExportJob implements ExportJob {
  new(this._host);

  final EngineHostApi _host;
  final _events = StreamController<ExportEvent>();
  String? _id;
  bool _cancelRequested = false;

  /// Called once the native side has returned the job id. A cancel
  /// requested before then is sent now.
  Future<void> attach(String id) async {
    _id = id;
    if (_cancelRequested) await _host.cancelExport(id);
  }

  @override
  Stream<ExportEvent> get events => _events.stream;

  void emit(ExportEvent event) {
    if (_events.isClosed) return;
    _events.add(event);
    if (event is ExportCompleted) unawaited(_events.close());
  }

  void fail(Failure failure) {
    if (_events.isClosed) return;
    _events.addError(failure);
    unawaited(_events.close());
  }

  @override
  Future<void> cancel() async {
    if (_cancelRequested) return;
    _cancelRequested = true;
    final id = _id;
    if (id != null) await _host.cancelExport(id);
  }
}
