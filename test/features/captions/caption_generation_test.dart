import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/features/captions/application/caption_generation.dart';
import 'package:stitch/features/captions/application/caption_rendering.dart';
import 'package:stitch/features/captions/data/caption_models.dart';
import 'package:stitch/features/captions/domain/transcript.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import '../../helpers/app_scope.dart';
import '../../helpers/fake_captions.dart';

Future<(TestEnv, String)> _project(List<int> seconds) async {
  final env = await TestEnv.create();
  final id = await env.container
      .read(importControllerProvider.notifier)
      .createProject(
        name: 'Test',
        preset: AspectPreset.portrait9x16,
        items: [
          for (final (i, s) in seconds.indexed)
            env.library.addVideo('v$i', seconds: s),
        ],
      );
  final sub = env.container.listen(editorControllerProvider(id!), (_, _) {});
  addTearDown(sub.close);
  await env.container.read(editorControllerProvider(id).future);
  // Keep generation alive, as the editor screen does.
  final gen = env.container.listen(captionGenerationProvider(id), (_, _) {});
  addTearDown(gen.close);
  env.models.installed.add(CaptionModel.tiny.fileName);
  return (env, id);
}

void main() {
  group('generation', () {
    test(
      'captions land on the same speech after edits made meanwhile',
      () async {
        final (env, id) = await _project([3, 4]);
        // Speech in the second clip, at 4.0 s.
        env.speech.transcript = Transcript(
          language: 'en',
          segments: [
            [token(' Second', 4000, 4500), token(' clip', 4500, 5000)],
          ],
        );
        final editor = env.container.read(
          editorControllerProvider(id).notifier,
        );
        final generation = env.container.read(
          captionGenerationProvider(id).notifier,
        );
        final running = generation.start(
          model: CaptionModel.tiny,
          source: CaptionSource.video,
        );
        // While it listens, the first clip loses a second.
        final first = env.container
            .read(editorControllerProvider(id))
            .requireValue
            .timeline
            .videoClips
            .first;
        editor.apply((t) => t.trimClip(first.id, ClipEdge.end, -1000000));
        await running;

        final timeline = env.container
            .read(editorControllerProvider(id))
            .requireValue
            .timeline;
        final caption = timeline.captionTrack.segments.single;
        expect(caption.text, 'Second clip');
        // Still at the start of "Second": one second earlier now.
        expect(TimelineLayout.of(timeline).startOf(caption.anchor), 3000000);
        expect(
          env.container.read(captionGenerationProvider(id)),
          isA<CaptionJobIdle>(),
        );
      },
    );

    test('keeps the caption style and replaces the old captions', () async {
      final (env, id) = await _project([3]);
      final editor = env.container.read(editorControllerProvider(id).notifier)
        ..apply(
          (t) => t
              .setCaptions([
                (
                  id: 'old',
                  text: 'Old',
                  startUs: 0,
                  endUs: 1000000,
                  words: const [],
                ),
              ])
              .setCaptionStyle(
                preset: CaptionPreset.boxed,
                position: CaptionPosition.top,
              ),
        );
      env.speech.transcript = Transcript(
        language: 'fr',
        segments: [
          [token(' Bonjour', 500, 900)],
        ],
      );
      await env.container
          .read(captionGenerationProvider(id).notifier)
          .start(model: CaptionModel.tiny, source: CaptionSource.all);
      final track = env.container
          .read(editorControllerProvider(id))
          .requireValue
          .timeline
          .captionTrack;
      expect(track.segments.map((s) => s.text), ['Bonjour']);
      expect(track.preset, CaptionPreset.boxed);
      expect(track.position, CaptionPosition.top);
      expect(track.language, 'fr');
      // One step: undo brings the old ones back.
      editor.undo();
      expect(
        env.container
            .read(editorControllerProvider(id))
            .requireValue
            .timeline
            .captionTrack
            .segments
            .single
            .text,
        'Old',
      );
    });

    test('failures are reported, and the sound file is removed', () async {
      final (env, id) = await _project([3]);
      env.speech.failure = const CaptionFailure(CaptionProblem.failed);
      await env.container
          .read(captionGenerationProvider(id).notifier)
          .start(model: CaptionModel.tiny, source: CaptionSource.video);
      final state = env.container.read(captionGenerationProvider(id));
      expect(state, isA<CaptionJobFailed>());
      expect(
        env.root
            .listSync(recursive: true)
            .where((f) => f.path.endsWith('.f32')),
        isEmpty,
      );
    });
  });

  group('sound for recognition', () {
    final timeline = Timeline(
      videoClips: const [
        VideoClip(
          id: 'c',
          mediaId: 'm',
          kind: MediaKind.video,
          mediaDurationUs: 3000000,
          sourceInUs: 0,
          sourceOutUs: 3000000,
        ),
      ],
      audioItems: [
        for (final kind in AudioKind.values)
          AudioItem(
            id: kind.name,
            mediaId: 'a',
            kind: kind,
            name: kind.name,
            anchor: const Anchor.time(startUs: 0),
            mediaDurationUs: 1000000,
            sourceInUs: 0,
            sourceOutUs: 1000000,
          ),
      ],
    );

    test('video is the clips and sound taken from them', () {
      final t = timelineForSource(timeline, CaptionSource.video);
      expect(t.audioItems.map((a) => a.kind), [AudioKind.extracted]);
      expect(t.videoClips.single.volume, 1);
    });

    test('voiceover is voiceovers alone, with the clips silent', () {
      final t = timelineForSource(timeline, CaptionSource.voiceover);
      expect(t.audioItems.map((a) => a.kind), [AudioKind.voiceover]);
      expect(t.videoClips.single.volume, 0);
    });

    test('all is everything', () {
      expect(timelineForSource(timeline, CaptionSource.all), timeline);
    });
  });

  group('caption pieces', () {
    const caption = ResolvedCaption(
      id: 'c',
      text: 'Hi there you',
      startUs: 1000000,
      endUs: 3000000,
      words: [
        ResolvedWord(text: 'Hi', startUs: 1100000, endUs: 1300000),
        ResolvedWord(text: 'there', startUs: 1500000, endUs: 1900000),
        ResolvedWord(text: 'you', startUs: 2200000, endUs: 2500000),
      ],
    );

    test('one piece unless words are highlighted', () {
      expect(captionPieces(caption, CaptionPreset.plain), [
        (startUs: 1000000, endUs: 3000000, highlight: null),
      ]);
    });

    test('each word lights from its start to the next word', () {
      final pieces = captionPieces(caption, CaptionPreset.highlightWord);
      expect(pieces.map((p) => (p.startUs, p.endUs)), [
        (1000000, 1500000),
        (1500000, 2200000),
        (2200000, 3000000),
      ]);
      expect(
        pieces.map(
          (p) => caption.text.substring(p.highlight!.start, p.highlight!.end),
        ),
        ['Hi', 'there', 'you'],
      );
    });

    test('text edited out of step with its words shows plain', () {
      final edited = caption.copyWith(text: 'Something else entirely');
      expect(captionPieces(edited, CaptionPreset.highlightWord), hasLength(1));
    });

    test('captions read the same size in portrait and landscape', () {
      final portrait = captionStyle(
        CaptionPreset.plain,
        canvasWidth: 1080,
        canvasHeight: 1920,
      );
      final landscape = captionStyle(
        CaptionPreset.plain,
        canvasWidth: 1920,
        canvasHeight: 1080,
      );
      expect(portrait.size * 1920, closeTo(landscape.size * 1080, 0.001));
    });
  });
}
