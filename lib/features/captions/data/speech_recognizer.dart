import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/features/captions/data/whisper_bindings.dart';
import 'package:stitch/features/captions/domain/transcript.dart';

/// A running recognition. [result] fails with [CancelledFailure] after
/// [cancel], and with [CaptionFailure] when recognition fails.
final class RecognitionJob {
  const new({
    required this.progress,
    required this.result,
    required this.cancel,
  });

  /// 0 to 1, a few times a second; closes when done.
  final Stream<double> progress;
  final Future<Transcript> result;
  final void Function() cancel;
}

/// Turns speech into a [Transcript], on the device.
abstract interface class SpeechRecognizer {
  /// Whether recognition is built for this device.
  bool get isAvailable;

  /// Recognizes [audioPath] (16 kHz mono float PCM, raw) with the model at
  /// [modelPath]. [language] is a whisper code, or null to detect it.
  RecognitionJob recognize({
    required String audioPath,
    required String modelPath,
    String? language,
  });
}

/// Samples per second recognition expects.
const speechSampleRate = 16000;

/// whisper.cpp through FFI (see native/whisper), on a background isolate.
/// Progress and cancellation go through native memory both isolates see.
class WhisperRecognizer implements SpeechRecognizer {
  const new();

  static final bool _available = () {
    try {
      // free(NULL) does nothing; it fails only when the library is missing.
      whisperFree(nullptr);
      return true;
      // Resolving a missing native function throws an Error.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return false;
    }
  }();

  @override
  bool get isAvailable => _available;

  @override
  RecognitionJob recognize({
    required String audioPath,
    required String modelPath,
    String? language,
  }) {
    if (!isAvailable) {
      return RecognitionJob(
        progress: const Stream.empty(),
        result: Future.error(const CaptionFailure(CaptionProblem.unavailable)),
        cancel: () {},
      );
    }
    final flags = calloc<Int32>(2);
    final progressAddress = flags.address;
    final cancelAddress = (flags + 1).address;
    final progress = StreamController<double>();
    final timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      progress.add(flags.value / 100);
    });
    // Phones have two to four fast cores; more threads do not help.
    final threads = math.max(1, math.min(4, Platform.numberOfProcessors));
    final result =
        _runIsolate(
          audioPath: audioPath,
          modelPath: modelPath,
          language: language ?? 'auto',
          threads: threads,
          progressAddress: progressAddress,
          cancelAddress: cancelAddress,
        ).then((json) => _parse(json, language)).whenComplete(() {
          // Freed only once whisper is done with it.
          timer.cancel();
          unawaited(progress.close());
          calloc.free(flags);
        });
    return RecognitionJob(
      progress: progress.stream,
      result: result,
      cancel: () {
        if (!progress.isClosed) (flags + 1).value = 1;
      },
    );
  }

  static Transcript _parse(String? json, String? language) {
    // Too short to hold speech.
    if (json == null) {
      return Transcript(language: language ?? '', segments: const []);
    }
    final Map<String, dynamic> map;
    try {
      map = jsonDecode(json) as Map<String, dynamic>;
    } on FormatException catch (e, st) {
      throw CaptionFailure(CaptionProblem.failed, cause: e, stackTrace: st);
    }
    return switch (map['error']) {
      null => Transcript.fromWhisperJson(map),
      'cancelled' => throw const CancelledFailure(),
      'model' => throw const CaptionFailure(CaptionProblem.modelDamaged),
      final other => throw CaptionFailure(CaptionProblem.failed, cause: other),
    };
  }
}

/// [_transcribe] on a new isolate. A function of its own, so the closure
/// sent to the isolate holds only these values.
Future<String?> _runIsolate({
  required String audioPath,
  required String modelPath,
  required String language,
  required int threads,
  required int progressAddress,
  required int cancelAddress,
}) => Isolate.run(
  () => _transcribe(
    audioPath: audioPath,
    modelPath: modelPath,
    language: language,
    threads: threads,
    progressAddress: progressAddress,
    cancelAddress: cancelAddress,
  ),
);

/// Runs on a background isolate: reads the samples and calls whisper.
/// Returns its JSON, or null when there is too little sound.
String? _transcribe({
  required String audioPath,
  required String modelPath,
  required String language,
  required int threads,
  required int progressAddress,
  required int cancelAddress,
}) {
  final file = File(audioPath).openSync();
  final int count;
  try {
    count = file.lengthSync() ~/ 4;
  } on Object {
    file.closeSync();
    rethrow;
  }
  if (count < speechSampleRate ~/ 10) {
    file.closeSync();
    return null;
  }
  return using((arena) {
    // Read straight into native memory: one copy of the sound, not two
    // (an hour is about 230 MB).
    final samples = arena<Float>(count);
    final view = samples.cast<Uint8>().asTypedList(count * 4);
    try {
      var read = 0;
      while (read < view.length) {
        final n = file.readIntoSync(view, read);
        if (n == 0) break;
        read += n;
      }
    } finally {
      file.closeSync();
    }
    final out = whisperTranscribe(
      modelPath.toNativeUtf8(allocator: arena),
      samples,
      count,
      language.toNativeUtf8(allocator: arena),
      threads,
      Pointer<Int32>.fromAddress(progressAddress),
      Pointer<Int32>.fromAddress(cancelAddress),
    );
    try {
      return out.toDartString();
    } finally {
      whisperFree(out);
    }
  });
}
