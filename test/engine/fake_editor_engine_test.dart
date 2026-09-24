import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/fake_editor_engine.dart';

void main() {
  late FakeEditorEngine engine;

  setUp(() => engine = FakeEditorEngine(durationUs: 1000000));
  tearDown(() => engine.dispose());

  test('setDocument reports duration and keeps the payload', () async {
    await engine.setDocument('{"composition":{"durationUs":2000000}}');
    expect(engine.lastDocument, contains('durationUs'));
    expect(engine.current.durationUs, 2000000);
  });

  test('seek clamps to the composition', () async {
    await engine.setDocument('{}');
    await engine.seek(5000000);
    expect(engine.current.positionUs, 1000000);
    await engine.seek(-1);
    expect(engine.current.positionUs, 0);
  });

  test('play advances and stops at the end', () {
    fakeAsync((async) {
      unawaited(engine.setDocument('{}'));
      async.flushMicrotasks();
      unawaited(engine.play());
      async.elapse(const Duration(milliseconds: 500));
      expect(engine.current.isPlaying, isTrue);
      expect(engine.current.positionUs, greaterThan(0));
      async.elapse(const Duration(seconds: 1));
      expect(engine.current.isPlaying, isFalse);
      expect(engine.current.positionUs, 1000000);
    });
  });

  test('pause stops position updates', () {
    fakeAsync((async) {
      unawaited(engine.setDocument('{}'));
      unawaited(engine.play());
      async.elapse(const Duration(milliseconds: 200));
      unawaited(engine.pause());
      async.flushMicrotasks();
      final paused = engine.current.positionUs;
      async.elapse(const Duration(milliseconds: 200));
      expect(engine.current.positionUs, paused);
    });
  });

  test('export streams progress then completes', () async {
    final job = engine.export(_settings);
    final events = await job.events.toList();
    expect(events.whereType<ExportProgress>(), hasLength(10));
    expect(events.last, isA<ExportCompleted>());
  });

  test('cancelled export ends with CancelledFailure', () async {
    final job = engine.export(_settings);
    final done = expectLater(
      job.events,
      emitsThrough(emitsError(isA<CancelledFailure>())),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await job.cancel();
    await done;
  });
}

const _settings = ExportSettings(
  outputPath: '/tmp/out.mp4',
  width: 1080,
  height: 1920,
  frameRate: 30,
  bitrate: 10000000,
);
