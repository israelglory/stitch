import 'dart:async';

import 'package:meta/meta.dart';

/// Boundary between Dart and the native media engines.
///
/// Implemented natively on iOS (AVFoundation + Metal) and Android (Media3 +
/// GL) behind Pigeon, and by FakeEditorEngine for tests and UI work.
///
/// The engine is stateless with respect to editing: it receives the whole
/// document (canvas, media files, and the resolved composition), which is
/// the single source of truth for both preview and export. Callers
/// debounce updates during drags.
abstract interface class EditorEngine {
  /// Creates the preview surface and returns its Flutter texture id, or
  /// null when this engine has no native preview (the fake).
  Future<int?> createPreview();

  /// Replaces the document. See `engineDocumentJson`.
  Future<void> setDocument(String documentJson);

  Future<void> play();

  Future<void> pause();

  /// Seeks the preview to [positionUs]. When [exact] is false the engine
  /// may land on a nearby keyframe, which is faster while scrubbing.
  Future<void> seek(int positionUs, {bool exact = true});

  /// Playback position and state. Each listener first receives the current
  /// state, then every change; emits at display rate while playing, so
  /// consumers must `select` the fields they need.
  Stream<PlaybackState> get playbackState;

  /// Starts exporting the current document. Progress streams on the
  /// returned [ExportJob]; call [ExportJob.cancel] to stop it.
  ExportJob export(ExportSettings settings);

  /// Renders the sound of [documentJson] (not the previewed document) for
  /// speech recognition: 16 kHz mono float PCM, raw and little endian, at
  /// [outputPath]. A document with no sound gives an empty file.
  ExportJob speechAudio(String documentJson, String outputPath);

  /// Reads what a media file contains.
  Future<MediaInfo> probe(String path);

  /// Filmstrip frames of [path] at [timesUs], as JPEG paths in [outDir]
  /// (null where a frame could not be made).
  Future<List<String?>> thumbnails(
    String path,
    List<int> timesUs, {
    required int maxSize,
    required String outDir,
  });

  /// Writes a 720p copy of [path] for smooth preview.
  Future<void> createProxy(String path, String outPath);

  /// What this device can encode.
  Future<EngineCapabilities> capabilities();

  /// Loudness of [path]'s sound: the peak, 0 to 1, of every
  /// 1 / [peaksPerSecond] of a second.
  Future<List<double>> waveform(String path, {required int peaksPerSecond});

  /// Volume of the preview, 0 to 1. Muted while recording a voiceover.
  Future<void> setPreviewVolume(double volume);

  /// Releases decoders, textures, and audio sessions. Called when leaving
  /// the editor. The engine can be used again after a new [setDocument].
  Future<void> release();
}

/// What a media file contains, read from the file itself.
@immutable
final class MediaInfo {
  const new({
    required this.width,
    required this.height,
    required this.hasVideo,
    required this.hasAudio,
    this.durationUs,
    this.rotationDeg = 0,
    this.frameRate = 0,
    this.isHdr = false,
  });

  /// Null for still images.
  final int? durationUs;

  /// Display size, after rotation.
  final int width;
  final int height;
  final int rotationDeg;
  final double frameRate;
  final bool hasVideo;
  final bool hasAudio;
  final bool isHdr;
}

@immutable
final class EngineCapabilities {
  const new({required this.hevc, required this.max4k});

  static const basic = EngineCapabilities(hevc: false, max4k: false);

  final bool hevc;
  final bool max4k;
}

/// Snapshot of the preview player.
@immutable
final class PlaybackState {
  const new({
    required this.positionUs,
    required this.durationUs,
    required this.isPlaying,
    this.isBuffering = false,
    this.documentVersion = 0,
  });

  static const idle = PlaybackState(
    positionUs: 0,
    durationUs: 0,
    isPlaying: false,
  );

  final int positionUs;
  final int durationUs;
  final bool isPlaying;
  final bool isBuffering;

  /// The `version` of the document the preview shows.
  final int documentVersion;

  PlaybackState copyWith({
    int? positionUs,
    int? durationUs,
    bool? isPlaying,
    bool? isBuffering,
    int? documentVersion,
  }) => PlaybackState(
    positionUs: positionUs ?? this.positionUs,
    durationUs: durationUs ?? this.durationUs,
    isPlaying: isPlaying ?? this.isPlaying,
    isBuffering: isBuffering ?? this.isBuffering,
    documentVersion: documentVersion ?? this.documentVersion,
  );

  @override
  bool operator ==(Object other) =>
      other is PlaybackState &&
      other.positionUs == positionUs &&
      other.durationUs == durationUs &&
      other.isPlaying == isPlaying &&
      other.isBuffering == isBuffering &&
      other.documentVersion == documentVersion;

  @override
  int get hashCode => Object.hash(
    positionUs,
    durationUs,
    isPlaying,
    isBuffering,
    documentVersion,
  );
}

enum VideoCodec { h264, hevc }

/// Export parameters chosen in the export sheet.
final class ExportSettings {
  const new({
    required this.outputPath,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.bitrate,
    this.codec = VideoCodec.h264,
    this.progressTitle = '',
  });

  final String outputPath;

  /// Output size in pixels, even, in the canvas's aspect ratio.
  final int width;
  final int height;
  final int frameRate;

  /// Target video bitrate in bits per second.
  final int bitrate;
  final VideoCodec codec;

  /// Shown with the progress where the system shows it (Android's export
  /// notification).
  final String progressTitle;
}

/// Progress of a running export.
sealed class ExportEvent {
  const new();
}

final class ExportProgress extends ExportEvent {
  const new(this.fraction);

  /// 0.0 to 1.0.
  final double fraction;
}

final class ExportCompleted extends ExportEvent {
  const new(this.outputPath);

  final String outputPath;
}

/// A running, cancellable export (or speech audio).
abstract interface class ExportJob {
  /// Emits progress, then exactly one [ExportCompleted], then closes. Errors
  /// are delivered as Failure subclasses.
  Stream<ExportEvent> get events;

  Future<void> cancel();
}
