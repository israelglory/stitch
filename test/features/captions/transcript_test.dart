import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/captions/domain/srt.dart';
import 'package:stitch/features/captions/domain/transcript.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/composition.dart';

/// Real output of the tiny model for the synthesized sentence in
/// test_media/speech.m4a.
const _whisper = '''
{"language":"en","segments":[{"start":0,"end":3920,"tokens":[
{"text":" Stitch","start":150,"end":370,"p":0.895},
{"text":" makes","start":370,"end":560,"p":0.721},
{"text":" captions","start":770,"end":1170,"p":0.983},
{"text":" on","start":1170,"end":1290,"p":0.999},
{"text":" your","start":1290,"end":1510,"p":0.996},
{"text":" phone","start":1610,"end":1850,"p":0.998},
{"text":",","start":1850,"end":1920,"p":0.838},
{"text":" everything","start":2190,"end":2680,"p":0.959},
{"text":" stays","start":2810,"end":3060,"p":0.989},
{"text":" on","start":3060,"end":3200,"p":0.995},
{"text":" your","start":3200,"end":3470,"p":0.997},
{"text":" device","start":3470,"end":3800,"p":0.979},
{"text":".","start":3860,"end":3920,"p":0.798}]}]}
''';

Transcript _parse(String json) =>
    Transcript.fromWhisperJson(jsonDecode(json) as Map<String, dynamic>);

/// A token as the shim writes it: one character per UTF-8 byte.
Map<String, Object> _token(String text, int start, int end) => {
  'text': String.fromCharCodes(utf8.encode(text)),
  'start': start,
  'end': end,
};

void main() {
  group('words', () {
    test('joins tokens at spaces and keeps punctuation on its word', () {
      final words = _parse(_whisper).words();
      expect(words.map((w) => w.text), [
        'Stitch',
        'makes',
        'captions',
        'on',
        'your',
        'phone,',
        'everything',
        'stays',
        'on',
        'your',
        'device.',
      ]);
      expect(words.first, (text: 'Stitch', startUs: 150000, endUs: 370000));
      expect(words[5], (text: 'phone,', startUs: 1610000, endUs: 1920000));
    });

    test('rebuilds characters split across tokens', () {
      // "café" with the é split into its two bytes.
      final bytes = utf8.encode(' café');
      final t = Transcript.fromWhisperJson({
        'language': 'fr',
        'segments': [
          {
            'tokens': [
              {
                'text': String.fromCharCodes(bytes.sublist(0, 5)),
                'start': 0,
                'end': 100,
              },
              {
                'text': String.fromCharCodes(bytes.sublist(5)),
                'start': 100,
                'end': 200,
              },
            ],
          },
        ],
      });
      expect(t.words().single.text, 'café');
    });

    test('without spaces, every whole character run is a word', () {
      final t = Transcript.fromWhisperJson({
        'language': 'ja',
        'segments': [
          {
            'tokens': [_token('こんにちは', 0, 500), _token('世界', 500, 900)],
          },
        ],
      });
      expect(t.words().map((w) => w.text), ['こんにちは', '世界']);
      expect(t.captions(newId: () => 'c').single.text, 'こんにちは世界');
    });

    test('times never go backwards', () {
      final t = Transcript.fromWhisperJson({
        'language': 'en',
        'segments': [
          {
            'tokens': [_token(' one', 500, 800), _token(' two', 300, 200)],
          },
        ],
      });
      final words = t.words();
      expect(words[1].startUs, 500000);
      expect(words[1].endUs, 500000);
    });
  });

  group('captions', () {
    test('break at the comma once half full, and hold after speech', () {
      var n = 0;
      final captions = _parse(_whisper).captions(newId: () => 'c${n++}');
      expect(captions.map((c) => c.text), [
        'Stitch makes captions on your phone,',
        'everything stays on your device.',
      ]);
      // The first stays up until the second starts (within the hold).
      expect(captions[0].startUs, 150000);
      expect(captions[0].endUs, 2190000);
      expect(captions[1].endUs, 3920000 + captionHoldUs);
      expect(captions[1].words.first.text, 'everything');
      expect(captions.map((c) => c.id), ['c0', 'c1']);
    });

    test('break at pauses, sentence ends, and length', () {
      RecognizedWord w(String text, int start, int end) =>
          (text: text, startUs: start, endUs: end);
      final groups = captionGroups(
        [
              w('Hi.', 0, 100),
              w('Wait', 200, 300),
              w('here', 2000, 2100), // a long pause before
              w('a', 2100, 2200),
            ]
            .map(
              (x) => (
                text: x.text,
                startUs: x.startUs * 1000,
                endUs: x.endUs * 1000,
              ),
            )
            .toList(),
      );
      expect(groups.map((g) => g.map((x) => x.text).join(' ')), [
        'Hi.',
        'Wait',
        'here a',
      ]);

      final long = [
        for (var i = 0; i < 10; i++)
          w('word$i', i * 100000, i * 100000 + 90000),
      ];
      final chunks = captionGroups(long, maxChars: 20);
      expect(
        chunks.every((g) => joinWords(g, spaced: true).length <= 20),
        isTrue,
      );
      expect(chunks.expand((g) => g), long);
    });

    test('become caption segments on the timeline', () {
      final captions = _parse(_whisper).captions(newId: () => 'x');
      expect(captions.first.words.map((w) => w.startUs), [
        150000,
        370000,
        770000,
        1170000,
        1290000,
        1610000,
      ]);
    });
  });

  test('srt lists captions in time order', () {
    final srt = srtOf(const [
      ResolvedCaption(
        id: 'b',
        text: 'Second',
        startUs: 2500000,
        endUs: 3723456,
      ),
      ResolvedCaption(id: 'a', text: 'First', startUs: 0, endUs: 1200000),
    ]);
    expect(
      srt,
      '1\n00:00:00,000 --> 00:00:01,200\nFirst\n\n'
      '2\n00:00:02,500 --> 00:00:03,723\nSecond\n\n',
    );
  });
}
