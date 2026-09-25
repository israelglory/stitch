// Contract between Dart and native code: the media engines (iOS:
// AVFoundation, Android: Media3) and device features the editor needs
// (file picking, the microphone, audio preview). Regenerate after editing:
//
//   dart run pigeon --input pigeons/engine_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/engine/pigeon/engine_api.g.dart',
    dartPackageName: 'stitch',
    swiftOut: 'ios/Runner/Engine/EngineApi.g.swift',
    kotlinOut: 'android/app/src/main/kotlin/xyz/gloryolaifa/stitch/engine/EngineApi.g.kt',
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
    required this.progressTitle,
  });

  String outputPath;
  int width;
  int height;
  int frameRate;
  int videoBitrate;
  bool hevc;

  /// Shown with the progress where the system shows it (Android's export
  /// notification).
  String progressTitle;
}

class PlaybackStateMessage {
  PlaybackStateMessage({
    required this.positionUs,
    required this.durationUs,
    required this.isPlaying,
    required this.isBuffering,
    required this.documentVersion,
  });

  int positionUs;
  int durationUs;
  bool isPlaying;
  bool isBuffering;

  /// The `version` of the document the preview shows.
  int documentVersion;
}

/// A file the user picked, copied into the app.
class PickedFileMessage {
  PickedFileMessage({required this.path, required this.name});

  String path;

  /// The name the user knows it by, without the extension.
  String name;
}

enum MicrophonePermission { granted, undetermined, denied, permanentlyDenied }

/// How saving to the photo library went.
enum GallerySaveResult { saved, denied, permanentlyDenied }

class AudioPreviewStateMessage {
  AudioPreviewStateMessage({
    required this.path,
    required this.positionUs,
    required this.durationUs,
    required this.isPlaying,
  });

  String path;
  int positionUs;
  int durationUs;
  bool isPlaying;
}

class RecordingMessage {
  RecordingMessage({required this.path, required this.durationUs});

  String path;
  int durationUs;
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

  /// Stops an export or speech audio job.
  void cancelExport(String jobId);

  /// Renders the sound of [documentJson] (not the previewed document) for
  /// speech recognition: 16 kHz mono float PCM, raw and little endian, at
  /// [outputPath]. Reports like an export and is cancelled the same way.
  /// A document with no sound gives an empty file.
  String startSpeechAudio(String documentJson, String outputPath);

  /// Loudness of [path]'s sound: the peak (0 to 1) of every
  /// 1 / [peaksPerSecond] of a second.
  @async
  List<double> waveform(String path, int peaksPerSecond);

  /// Volume of the preview, 0 to 1 (muted while recording a voiceover).
  void setPreviewVolume(double volume);
}

/// Device features used by the editor.
@HostApi()
abstract class DeviceHostApi {
  /// Lets the user pick an audio file and copies it into [outDir]. Null
  /// when they cancel.
  @async
  PickedFileMessage? pickAudioFile(String outDir);

  /// Plays [path] on its own (to try music before adding it). State
  /// arrives through [DeviceFlutterApi.onAudioPreviewState].
  void startAudioPreview(String path);

  void stopAudioPreview();

  MicrophonePermission microphonePermission();

  /// Asks for the microphone if it has not been asked yet.
  @async
  MicrophonePermission requestMicrophone();

  /// Opens this app's page in the system settings.
  void openAppSettings();

  /// Records the microphone to [outPath] (AAC in M4A, 48 kHz). Levels
  /// arrive through [DeviceFlutterApi.onRecordingLevel].
  void startRecording(String outPath);

  /// Stops and returns the recording.
  @async
  RecordingMessage stopRecording();

  /// Stops and deletes the recording.
  void cancelRecording();

  /// Bytes free for new files on the volume holding [path].
  int freeSpace(String path);

  /// Copies the video at [path] into the photo library: Photos on iOS
  /// (add-only access, asked for now if needed), Movies/Stitch on Android.
  @async
  GallerySaveResult saveVideoToGallery(String path);

  /// Opens the system share sheet for the file at [path].
  void shareFile(String path, String mimeType);

  /// Opens [url] in the browser.
  void openUrl(String url);

  /// Keeps the screen on, during an export.
  void setKeepScreenOn(bool on);

  /// The app's version, like "0.1.0 (1)".
  String appVersion();

  /// Asks to show notifications, for export progress (Android 13 and
  /// later; elsewhere always true). True when allowed.
  @async
  bool requestNotifications();
}

@FlutterApi()
abstract class DeviceFlutterApi {
  void onAudioPreviewState(AudioPreviewStateMessage state);

  /// Microphone level, 0 to 1, about 20 times a second while recording.
  void onRecordingLevel(double level);

  /// Recording stopped on its own (a call, another app, an error). The
  /// file so far is kept at [path], or null when there is none.
  void onRecordingInterrupted(String? path, int durationUs);
}

@FlutterApi()
abstract class EngineFlutterApi {
  void onPlaybackState(PlaybackStateMessage state);

  void onExportProgress(String jobId, double fraction);

  void onExportCompleted(String jobId, String outputPath);

  /// [code] is stable (for mapping to a message); [message] is for logs.
  void onExportFailed(String jobId, String code, String message);
}
