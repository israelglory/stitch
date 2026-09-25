// Real speech recognition: whisper.cpp built for this machine by the
// build hook. The tests that need the model skip until
// tool/fetch_test_model.sh has downloaded it.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/features/captions/data/speech_recognizer.dart';

const _model = '.cache/models/ggml-tiny-q8_0.bin';
const _speech = 'test_media/speech_16k.f32';

void main() {
  const recognizer = WhisperRecognizer();
  final noModel = File(_model).existsSync()
      ? null
      : 'Run tool/fetch_test_model.sh first';

  test('the library is built for this machine', () {
    expect(recognizer.isAvailable, isTrue);
  });

  test('hears the words and their times', () async {
    final job = recognizer.recognize(audioPath: _speech, modelPath: _model);
    final progress = <double>[];
    job.progress.listen(progress.add);
    final transcript = await job.result;
    expect(transcript.language, 'en');
    final words = transcript.words();
    expect(
      words.map((w) => w.text.toLowerCase()).join(' '),
      contains('captions on your phone'),
    );
    final captions = words.firstWhere((w) => w.text == 'captions');
    // Spoken at about 0.8 s.
    expect(captions.startUs, inInclusiveRange(500000, 1100000));
    expect(progress, isNotEmpty);
  }, skip: noModel);

  test('recognizes in the language asked for', () async {
    final job = recognizer.recognize(
      audioPath: _speech,
      modelPath: _model,
      language: 'en',
    );
    expect((await job.result).language, 'en');
  }, skip: noModel);

  test('cancel stops it', () async {
    // Long enough (a minute of the sample) to cancel in the middle.
    final one = File(_speech).readAsBytesSync();
    final long = File('${Directory.systemTemp.createTempSync().path}/l.f32')
      ..writeAsBytesSync([for (var i = 0; i < 15; i++) ...one]);
    final job = recognizer.recognize(audioPath: long.path, modelPath: _model);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    job.cancel();
    await expectLater(job.result, throwsA(isA<CancelledFailure>()));
  }, skip: noModel);

  test('a file that is not a model reports a damaged model', () async {
    final dir = Directory.systemTemp.createTempSync();
    final bad = File('${dir.path}/bad.bin')..writeAsStringSync('not a model');
    final job = recognizer.recognize(audioPath: _speech, modelPath: bad.path);
    await expectLater(
      job.result,
      throwsA(
        isA<CaptionFailure>().having(
          (f) => f.problem,
          'problem',
          CaptionProblem.modelDamaged,
        ),
      ),
    );
  });

  test('too little sound is no speech, without loading a model', () async {
    final dir = Directory.systemTemp.createTempSync();
    final short = File('${dir.path}/s.f32')
      ..writeAsBytesSync(Float32List(100).buffer.asUint8List());
    final job = recognizer.recognize(
      audioPath: short.path,
      modelPath: '/nowhere.bin',
    );
    expect((await job.result).segments, isEmpty);
  });
}
