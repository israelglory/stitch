// Contract between Dart and the native media engines (iOS: AVFoundation,
// Android: Media3). Regenerate after editing:
//
//   dart run pigeon --input pigeons/engine_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/engine/pigeon/engine_api.g.dart',
    dartPackageName: 'stitch',
    swiftOut: 'ios/Runner/Engine/EngineApi.g.swift',
    kotlinOut:
        'android/app/src/main/kotlin/xyz/gloryolaifa/stitch/engine/EngineApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'xyz.gloryolaifa.stitch.engine'),
  ),
)
/// What a media file contains, from the file itself.
class MediaInfoMessage {
  MediaInfoMessage({
    required this.durationUs,
    required this.width,
    required this.height,
    required this.rotationDeg,
    required this.frameRate,
    required this.hasVideo,
    required this.hasAudio,
    required this.isHdr,
  });

  /// Null for still images.
  int? durationUs;

  /// Display size, after applying [rotationDeg].
  int width;
  int height;
  int rotationDeg;

  /// Nominal frame rate; zero for stills and audio.
  double frameRate;
  bool hasVideo;
  bool hasAudio;
  bool isHdr;
}

class CapabilitiesMessage {
  CapabilitiesMessage({required this.hevc, required this.max4k});

  bool hevc;
  bool max4k;
}

class ExportRequestMessage {
  ExportRequestMessage({
    required this.outputPath,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.videoBitrate,
    required this.hevc,
  });

  String outputPath;
  int width;
  int height;
  int frameRate;
  int videoBitrate;
  bool hevc;
}

class PlaybackStateMessage {
  PlaybackStateMessage({
    required this.positionUs,
    required this.durationUs,
    required this.isPlaying,
    required this.isBuffering,
  });

  int positionUs;
  int durationUs;
  bool isPlaying;
  bool isBuffering;
}

@HostApi()
abstract class EngineHostApi {
  /// Creates the preview surface; returns the Flutter texture id.
  int createPreview();

  /// Replaces the document being previewed. See `EngineDocument` in Dart.
  void setDocument(String json);

  void play();

  void pause();

  /// [exact] false allows landing near the time, for fast scrubbing.
  void seek(int positionUs, bool exact);

  /// Releases players, decoders, and caches. Safe to call repeatedly.
  void release();

  @async
  MediaInfoMessage probe(String path);

  /// Writes a JPEG per time into [outDir], each at most [maxSize] pixels on
  /// its longest side, and returns their paths in order (null on failure).
  @async
  List<String?> thumbnails(
    String path,
    List<int> timesUs,
    int maxSize,
    String outDir,
  );

  /// Writes a 720p copy of [path] to [outPath] for smooth preview.
  @async
  void createProxy(String path, String outPath);

  CapabilitiesMessage capabilities();

  /// Starts exporting the current document; progress arrives through
  /// [EngineFlutterApi]. Returns a job id.
  String startExport(ExportRequestMessage request);

  void cancelExport(String jobId);
}

@FlutterApi()
abstract class EngineFlutterApi {
  void onPlaybackState(PlaybackStateMessage state);

  void onExportProgress(String jobId, double fraction);

  void onExportCompleted(String jobId, String outputPath);

  /// [code] is stable (for mapping to a message); [message] is for logs.
  void onExportFailed(String jobId, String code, String message);
}
