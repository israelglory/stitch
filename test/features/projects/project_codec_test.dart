import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/projects/domain/project_codec.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/features/timeline/domain/transition_ops.dart';

import '../timeline/fixtures.dart';

Project sampleProject() {
  final timeline = track([3, 4])
      .setTransition('a', TransitionType.crossfade)
      .addText(id: 't', text: 'Hi', atUs: s(1))
      .addAudio(
        id: 'm',
        mediaId: 'song',
        kind: AudioKind.music,
        name: 'Song',
        mediaDurationUs: s(30),
        atUs: 0,
      )
      .setCaptions([
        (
          id: 'c',
          text: 'Hello there',
          startUs: s(0.5),
          endUs: s(1.5),
          words: [
            (text: 'Hello', startUs: s(0.5), endUs: s(1)),
            (text: 'there', startUs: s(1), endUs: s(1.5)),
          ],
        ),
      ]);
  return Project(
    schemaVersion: ProjectCodec.currentSchemaVersion,
    id: 'p1',
    name: 'Beach day',
    createdAt: DateTime.utc(2026, 9, 1, 12),
    updatedAt: DateTime.utc(2026, 9, 2, 8, 30),
    canvas: ProjectCanvas.forPreset(AspectPreset.portrait9x16),
    background: const CanvasBackground.blur(),
    timeline: timeline,
  );
}

void main() {
  const codec = ProjectCodec();

  test('round-trips a full project', () {
    final project = sampleProject();
    expect(codec.decode(codec.encode(project), projectId: 'p1'), project);
  });

  test('encode stamps the current schema version', () {
    final json = jsonDecode(
      codec.encode(sampleProject().copyWith(schemaVersion: 0)),
    ) as Map<String, dynamic>;
    expect(json['schemaVersion'], ProjectCodec.currentSchemaVersion);
  });

  test('unreadable documents become ProjectCorruptedFailure', () {
    for (final bad in [
      'not json',
      '[]',
      '{"schemaVersion": 1}',
      '{"schemaVersion": "one"}',
      '{"schemaVersion": 0}',
    ]) {
      expect(
        () => codec.decode(bad, projectId: 'p1'),
        throwsA(
          isA<ProjectCorruptedFailure>().having(
            (f) => f.projectId,
            'projectId',
            'p1',
          ),
        ),
      );
    }
  });

  test('documents from a newer app version are refused', () {
    final json =
        jsonDecode(codec.encode(sampleProject())) as Map<String, dynamic>;
    json['schemaVersion'] = ProjectCodec.currentSchemaVersion + 1;
    expect(
      () => codec.decode(jsonEncode(json), projectId: 'p1'),
      throwsA(isA<ProjectCorruptedFailure>()),
    );
  });

  group('migrations', () {
    // A hypothetical v1 -> v2 -> v3 history: v2 renamed "title" to "name",
    // v3 added "frameRate".
    final codec3 = ProjectCodec(
      currentVersion: 3,
      migrations: {
        1: (doc) => {...doc, 'name': doc['title']}..remove('title'),
        2: (doc) => {...doc, 'frameRate': 24},
      },
    );

    test('run in order, one version at a time', () {
      final v1 = {'schemaVersion': 1, 'title': 'Old', 'other': true};
      final migrated = codec3.migrate(v1);
      expect(migrated['schemaVersion'], 3);
      expect(migrated['name'], 'Old');
      expect(migrated.containsKey('title'), isFalse);
      expect(migrated['frameRate'], 24);
      expect(migrated['other'], isTrue);
    });

    test('a missing step fails loudly', () {
      const gap = ProjectCodec(currentVersion: 2);
      expect(
        () => gap.migrate({'schemaVersion': 1}),
        throwsA(isA<StateError>()),
      );
    });

    test('the current version needs no migration', () {
      final doc = {'schemaVersion': 3, 'name': 'x'};
      expect(codec3.migrate(doc), doc);
    });
  });

  group('canvas', () {
    test('presets match the spec', () {
      ProjectCanvas c(AspectPreset p) => ProjectCanvas.forPreset(p);
      expect(
        (
          c(AspectPreset.portrait9x16).width,
          c(AspectPreset.portrait9x16).height,
        ),
        (1080, 1920),
      );
      expect(
        (
          c(AspectPreset.landscape16x9).width,
          c(AspectPreset.landscape16x9).height,
        ),
        (1920, 1080),
      );
      expect(
        (c(AspectPreset.square).width, c(AspectPreset.square).height),
        (1080, 1080),
      );
      expect(
        (c(AspectPreset.portrait4x5).width, c(AspectPreset.portrait4x5).height),
        (1080, 1350),
      );
    });

    test('aspect ratio', () {
      expect(
        ProjectCanvas.forPreset(AspectPreset.landscape16x9).aspectRatio,
        closeTo(16 / 9, 1e-9),
      );
    });

    test('original uses the first clip size, rounded to even', () {
      final c = ProjectCanvas.forPreset(
        AspectPreset.original,
        original: (1079, 1917),
      );
      expect((c.width, c.height), (1080, 1918));
    });
  });
}
