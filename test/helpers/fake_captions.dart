import 'dart:async';
import 'dart:io';

import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/features/captions/data/caption_models.dart';
import 'package:stitch/features/captions/data/speech_recognizer.dart';
import 'package:stitch/features/captions/domain/transcript.dart';

/// Recognizes [transcript] (or fails with [failure]) after a short delay,
/// reporting halfway first.
class FakeSpeechRecognizer implements SpeechRecognizer {
  bool available = true;
  Transcript transcript = const Transcript(language: 'en', segments: []);
  Object? failure;

  /// Arguments of each call, for assertions.
  final calls = <({String audioPath, String modelPath, String? language})>[];

  @override
  bool get isAvailable => available;

  @override
  RecognitionJob recognize({
    required String audioPath,
    required String modelPath,
    String? language,
  }) {
    calls.add((audioPath: audioPath, modelPath: modelPath, language: language));
    final progress = StreamController<double>();
    final result = Completer<Transcript>();
    var cancelled = false;
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!cancelled) progress.add(0.5);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await progress.close();
      if (result.isCompleted) return;
      if (failure case final f?) {
        result.completeError(f);
      } else {
        result.complete(transcript);
      }
    }());
    return RecognitionJob(
      progress: progress.stream,
      result: result.future,
      cancel: () {
        cancelled = true;
        if (!result.isCompleted) {
          result.completeError(const CancelledFailure());
        }
      },
    );
  }
}

/// Models "downloaded" in memory, in two steps of progress.
class FakeCaptionModelStore implements CaptionModelStore {
  final installed = <String>{};

  /// The next download fails with this.
  Object? failNext;
  final downloads = <String>[];

  @override
  Directory get directory => Directory('/models');

  @override
  File file(ModelFile model) => File('/models/${model.fileName}');

  @override
  bool isInstalled(ModelFile model) => installed.contains(model.fileName);

  @override
  int installedBytes() => [
    for (final m in CaptionModel.values)
      if (isInstalled(m.file)) m.bytes,
  ].fold(0, (a, b) => a + b);

  @override
  Future<void> delete(ModelFile model) async =>
      installed.remove(model.fileName);

  @override
  ModelDownload download(ModelFile model) {
    downloads.add(model.fileName);
    final progress = StreamController<double>();
    final done = Completer<void>();
    final failure = failNext;
    failNext = null;
    unawaited(() async {
      for (final f in [0.5, 1.0]) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (done.isCompleted) break;
        progress.add(f);
      }
      await progress.close();
      if (done.isCompleted) return;
      if (failure != null) {
        done.completeError(failure);
      } else {
        installed.add(model.fileName);
        done.complete();
      }
    }());
    return ModelDownload(
      progress: progress.stream,
      done: done.future,
      cancel: () async {
        if (!done.isCompleted) done.completeError(const CancelledFailure());
      },
    );
  }
}

/// A token as the whisper shim reports it.
SpeechToken token(String text, int startMs, int endMs) => SpeechToken(
  bytes: text.codeUnits,
  startUs: startMs * 1000,
  endUs: endMs * 1000,
);
