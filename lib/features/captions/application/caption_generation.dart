import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/captions/application/caption_providers.dart';
import 'package:stitch/features/captions/data/caption_models.dart';
import 'package:stitch/features/captions/domain/transcript.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/engine_document.dart';
import 'package:stitch/features/timeline/domain/models.dart';

part 'caption_generation.g.dart';

/// Which sound captions are made from.
enum CaptionSource {
  /// The clips' own sound (and sound extracted from them).
  video,

  /// Recorded voiceovers only.
  voiceover,

  /// Everything, music included.
  all,
}

/// [timeline] with only the sound [source] asks for.
Timeline timelineForSource(Timeline timeline, CaptionSource source) =>
    switch (source) {
      CaptionSource.all => timeline,
      CaptionSource.video => timeline.copyWith(
        audioItems: [
          for (final a in timeline.audioItems)
            if (a.kind == AudioKind.extracted) a,
        ],
      ),
      CaptionSource.voiceover => timeline.copyWith(
        videoClips: [
          for (final c in timeline.videoClips) c.copyWith(volume: 0),
        ],
        audioItems: [
          for (final a in timeline.audioItems)
            if (a.kind == AudioKind.voiceover) a,
        ],
      ),
    };

/// Where caption generation stands.
sealed class CaptionJob {
  const new();
}

final class CaptionJobIdle extends CaptionJob {
  const new();
}

final class CaptionJobRunning extends CaptionJob {
  const new(this.fraction);

  /// 0 to 1 over the whole job.
  final double fraction;
}

final class CaptionJobFailed extends CaptionJob {
  const new(this.failure);

  final Object failure;
}

/// Share of the progress bar for preparing the sound; recognition takes
/// the rest.
const _soundShare = 0.15;

/// Makes captions for a project in the background while editing goes on.
/// Lives while the editor shows it; closing the editor cancels it.
@riverpod
class CaptionGeneration extends _$CaptionGeneration {
  ExportJob? _sound;
  void Function()? _cancelRecognition;
  bool _cancelled = false;

  @override
  CaptionJob build(String projectId) {
    ref.onDispose(cancel);
    return const CaptionJobIdle();
  }

  bool get isRunning => state is CaptionJobRunning;

  /// Recognizes speech in the [source] sound with [model] (installed) and
  /// replaces the project's captions with it. [language] is a whisper
  /// code, or null to detect it.
  Future<void> start({
    required CaptionModel model,
    required CaptionSource source,
    String? language,
  }) async {
    if (isRunning) return;
    _cancelled = false;
    state = const CaptionJobRunning(0);
    final editor = ref.read(editorControllerProvider(projectId).notifier);
    // Read now: after the awaits below, the editor may have closed.
    final models = ref.read(captionModelsProvider.notifier);
    final project = ref
        .read(editorControllerProvider(projectId))
        .requireValue
        .project;
    final heard = project.timeline;
    final store = ref.read(projectStoreProvider);
    final audio = File(
      p.join(ref.read(cacheRootProvider).path, 'speech', '$projectId.f32'),
    );
    try {
      await audio.parent.create(recursive: true);
      // 1. The sound, as recognition takes it.
      final document = engineDocumentJson(
        project.copyWith(timeline: timelineForSource(heard, source)),
        resolve: (relative) => store.resolve(projectId, relative),
      );
      final sound = _sound = ref
          .read(editorEngineProvider)
          .speechAudio(document, audio.path);
      await for (final event in sound.events) {
        if (event is ExportProgress) _progress(event.fraction * _soundShare);
      }
      _sound = null;
      if (_cancelled) throw const CancelledFailure();

      // 2. The words.
      final job = ref
          .read(speechRecognizerProvider)
          .recognize(
            audioPath: audio.path,
            modelPath: ref
                .read(captionModelStoreProvider)
                .file(model.file)
                .path,
            language: language,
          );
      _cancelRecognition = job.cancel;
      if (_cancelled) job.cancel();
      final progress = job.progress.listen(
        (f) => _progress(_soundShare + f * (1 - _soundShare)),
      );
      final Transcript transcript;
      try {
        transcript = await job.result;
      } finally {
        _cancelRecognition = null;
        await progress.cancel();
      }

      // 3. The captions.
      final ids = ref.read(idGeneratorProvider);
      final segments = transcript.captions(newId: ids.next);
      if (segments.isEmpty) {
        throw const CaptionFailure(CaptionProblem.noSpeech);
      }
      if (!ref.mounted) return;
      editor.setRecognizedCaptions(
        heard,
        segments,
        language: transcript.language.isEmpty ? null : transcript.language,
      );
      state = const CaptionJobIdle();
    } on CancelledFailure {
      if (ref.mounted) state = const CaptionJobIdle();
    } on Object catch (e) {
      if (e case CaptionFailure(problem: CaptionProblem.modelDamaged)) {
        await models.discard(model);
      }
      if (ref.mounted) state = CaptionJobFailed(e);
    } finally {
      if (audio.existsSync()) await audio.delete();
    }
  }

  void _progress(double fraction) {
    if (ref.mounted && isRunning) state = CaptionJobRunning(fraction);
  }

  void cancel() {
    _cancelled = true;
    unawaited(_sound?.cancel());
    _cancelRecognition?.call();
  }

  /// Hides a failure.
  void dismiss() {
    if (state is CaptionJobFailed) state = const CaptionJobIdle();
  }
}
