import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/engine/pigeon/engine_api.g.dart';

/// Access to the microphone: never asked, allowed, refused (can ask again,
/// Android only), or refused for good (only system settings can change it).
enum MicAccess { undetermined, granted, denied, permanentlyDenied }

/// A file the user picked, copied into the app.
final class PickedAudio {
  const new({required this.path, required this.name});

  final String path;

  /// The name the user knows it by.
  final String name;
}

/// A finished recording.
final class Recording {
  const new({required this.path, required this.durationUs});

  final String path;
  final int durationUs;
}

/// Playback of a sound tried before adding it.
final class AudioPreviewState {
  const new({
    this.path,
    this.positionUs = 0,
    this.durationUs = 0,
    this.isPlaying = false,
  });

  static const stopped = AudioPreviewState();

  /// What is playing (or was, when stopped at its end); null when stopped.
  final String? path;
  final int positionUs;
  final int durationUs;
  final bool isPlaying;
}

/// Device features the audio tools need: file picking, trying sounds,
/// the microphone, and recording. Native on iOS and Android; a fake in
/// tests.
abstract interface class AudioDevice {
  /// Lets the user pick an audio file; copies it into [outDir]. Null when
  /// they cancel.
  Future<PickedAudio?> pickFile(String outDir);

  Future<void> startPreview(String path);

  Future<void> stopPreview();

  /// The latest preview state first, then every change.
  Stream<AudioPreviewState> get previewState;

  Future<MicAccess> micAccess();

  /// Asks for the microphone if it has not been asked yet.
  Future<MicAccess> requestMic();

  Future<void> openSettings();

  /// Records the microphone to [outPath] (AAC, 48 kHz).
  Future<void> startRecording(String outPath);

  Future<Recording> stopRecording();

  /// Stops and deletes the recording.
  Future<void> cancelRecording();

  /// Microphone level, 0 to 1, about 20 times a second while recording.
  Stream<double> get levels;

  /// A call or another app ended the recording. Carries what was kept, or
  /// null when nothing was.
  Stream<Recording?> get interruptions;
}

/// [AudioDevice] over the native `DeviceHostApi`.
class NativeAudioDevice implements AudioDevice, DeviceFlutterApi {
  new({DeviceHostApi? host}) : _host = host ?? DeviceHostApi() {
    DeviceFlutterApi.setUp(this);
  }

  final DeviceHostApi _host;
  final _preview = StreamController<AudioPreviewState>.broadcast();
  final _levels = StreamController<double>.broadcast();
  final _interruptions = StreamController<Recording?>.broadcast();
  AudioPreviewState _previewNow = AudioPreviewState.stopped;

  @override
  Future<PickedAudio?> pickFile(String outDir) => _guard(() async {
    final picked = await _host.pickAudioFile(outDir);
    return picked == null
        ? null
        : PickedAudio(path: picked.path, name: picked.name);
  });

  @override
  Future<void> startPreview(String path) =>
      _guard(() => _host.startAudioPreview(path));

  @override
  Future<void> stopPreview() => _guard(_host.stopAudioPreview);

  @override
  Stream<AudioPreviewState> get previewState async* {
    yield _previewNow;
    yield* _preview.stream;
  }

  @override
  Future<MicAccess> micAccess() =>
      _guard(() async => _access(await _host.microphonePermission()));

  @override
  Future<MicAccess> requestMic() =>
      _guard(() async => _access(await _host.requestMicrophone()));

  @override
  Future<void> openSettings() => _guard(_host.openAppSettings);

  @override
  Future<void> startRecording(String outPath) =>
      _guard(() => _host.startRecording(outPath));

  @override
  Future<Recording> stopRecording() => _guard(() async {
    final r = await _host.stopRecording();
    return Recording(path: r.path, durationUs: r.durationUs);
  });

  @override
  Future<void> cancelRecording() => _guard(_host.cancelRecording);

  @override
  Stream<double> get levels => _levels.stream;

  @override
  Stream<Recording?> get interruptions => _interruptions.stream;

  // DeviceFlutterApi: callbacks from the native side.

  @override
  void onAudioPreviewState(AudioPreviewStateMessage state) {
    _previewNow = AudioPreviewState(
      path: state.path.isEmpty ? null : state.path,
      positionUs: state.positionUs,
      durationUs: state.durationUs,
      isPlaying: state.isPlaying,
    );
    _preview.add(_previewNow);
  }

  @override
  void onRecordingLevel(double level) => _levels.add(level);

  @override
  void onRecordingInterrupted(String? path, int durationUs) => _interruptions
      .add(path == null ? null : Recording(path: path, durationUs: durationUs));

  static MicAccess _access(MicrophonePermission p) => switch (p) {
    MicrophonePermission.granted => MicAccess.granted,
    MicrophonePermission.undetermined => MicAccess.undetermined,
    MicrophonePermission.denied => MicAccess.denied,
    MicrophonePermission.permanentlyDenied => MicAccess.permanentlyDenied,
  };

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e, st) {
      throw switch (e.code) {
        'unsupported_media' => UnsupportedMediaFailure(
          e.message ?? '',
          stackTrace: st,
        ),
        _ => EngineFailure(e.code, cause: e.message, stackTrace: st),
      };
    }
  }
}

/// In-memory [AudioDevice] for tests and platforms without the native one.
class FakeAudioDevice implements AudioDevice {
  new({this.access = MicAccess.undetermined});

  /// Microphone access; [requestMic] grants it when still undetermined,
  /// unless [grantOnRequest] is false.
  MicAccess access;
  bool grantOnRequest = true;

  /// What [pickFile] returns; a file is written at its path.
  PickedAudio? nextPick;

  /// Length [stopRecording] reports.
  int recordingUs = 2000000;

  final previews = <String>[];
  String? recordingPath;
  int settingsOpened = 0;

  final _preview = StreamController<AudioPreviewState>.broadcast();
  final _levels = StreamController<double>.broadcast();
  final _interruptions = StreamController<Recording?>.broadcast();
  AudioPreviewState _previewNow = AudioPreviewState.stopped;

  @override
  Future<PickedAudio?> pickFile(String outDir) async => nextPick;

  @override
  Future<void> startPreview(String path) async {
    previews.add(path);
    _emitPreview(
      AudioPreviewState(path: path, durationUs: 45000000, isPlaying: true),
    );
  }

  @override
  Future<void> stopPreview() async => _emitPreview(AudioPreviewState.stopped);

  @override
  Stream<AudioPreviewState> get previewState async* {
    yield _previewNow;
    yield* _preview.stream;
  }

  @override
  Future<MicAccess> micAccess() async => access;

  @override
  Future<MicAccess> requestMic() async {
    if (access == MicAccess.undetermined) {
      access = grantOnRequest ? MicAccess.granted : MicAccess.denied;
    }
    return access;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<void> startRecording(String outPath) async {
    recordingPath = outPath;
    await File(outPath).parent.create(recursive: true);
    await File(outPath).writeAsBytes([0]);
  }

  @override
  Future<Recording> stopRecording() async {
    final path = recordingPath;
    if (path == null) throw const EngineFailure('recording_failed');
    recordingPath = null;
    return Recording(path: path, durationUs: recordingUs);
  }

  @override
  Future<void> cancelRecording() async {
    final path = recordingPath;
    recordingPath = null;
    if (path != null && File(path).existsSync()) await File(path).delete();
  }

  @override
  Stream<double> get levels => _levels.stream;

  @override
  Stream<Recording?> get interruptions => _interruptions.stream;

  /// Sends a microphone level, as the device does while recording.
  void emitLevel(double level) => _levels.add(level);

  /// Simulates a call ending the recording.
  void interrupt() {
    final path = recordingPath;
    recordingPath = null;
    _interruptions.add(
      path == null ? null : Recording(path: path, durationUs: recordingUs),
    );
  }

  void _emitPreview(AudioPreviewState state) {
    _previewNow = state;
    _preview.add(state);
  }
}
