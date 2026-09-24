// Randomized edit sequences. After every step the timeline must satisfy
// all invariants, whatever order the edits came in. Seeds are fixed, so a
// failure reproduces exactly; the failure message names the seed and step.
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/timeline/domain/audio_ops.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/composition.dart';
import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/limits.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/normalize.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/features/timeline/domain/transition_ops.dart';
import 'package:stitch/features/timeline/domain/video_ops.dart';

import 'fixtures.dart';

const _sequences = 1000;
const _stepsPerSequence = 60;

void main() {
  test('invariants hold across random edit sequences', () {
    for (var seed = 0; seed < _sequences; seed++) {
      final rng = Random(seed);
      var nextId = 0;
      String id() => 'id${nextId++}';
      var t = track([2, 3, 1.5, 4]);
      final log = <String>[];

      for (var step = 0; step < _stepsPerSequence; step++) {
        final (name, edit) = _randomEdit(t, rng, id);
        log.add(name);
        t = edit(t);
        final problems = _violations(t);
        if (problems.isNotEmpty) {
          fail(
            'seed $seed, step $step after ${log.join(' > ')}:\n'
            '${problems.join('\n')}',
          );
        }
      }
    }
  });
}

typedef _Edit = (String, Timeline Function(Timeline));

_Edit _randomEdit(Timeline t, Random rng, String Function() id) {
  final layout = TimelineLayout.of(t);
  final duration = max(1, layout.durationUs);
  int anyTime() => rng.nextInt(duration + s(1)) - s(0.5);
  int delta() => rng.nextInt(s(4)) - s(2);
  T pick<T>(List<T> xs) => xs[rng.nextInt(xs.length)];
  final clipIds = [for (final c in t.videoClips) c.id];
  final textIds = [for (final x in t.textItems) x.id];
  final audioIds = [for (final x in t.audioItems) x.id];
  final captionIds = [for (final x in t.captionTrack.segments) x.id];
  final edge = pick(ClipEdge.values);

  final edits = <_Edit>[
    ('append', (t) => t.appendClips([clip(id(), 0.5 + rng.nextInt(40) / 10)])),
    (
      'photo',
      (t) => t.insertClips(rng.nextInt(clipIds.length + 1), [
        VideoClip.photo(id: id(), mediaId: 'photo'),
      ]),
    ),
    (
      'text',
      (t) => t.addText(
        id: id(),
        text: 'x',
        atUs: anyTime(),
        durationUs: rng.nextInt(s(4)),
      ),
    ),
    (
      'audio',
      (t) => t.addAudio(
        id: id(),
        mediaId: 'song',
        kind: AudioKind.music,
        name: 'song',
        mediaDurationUs: s(1 + rng.nextInt(20)),
        atUs: anyTime(),
        lane: rng.nextInt(3),
      ),
    ),
    (
      'captions',
      (t) {
        final start = rng.nextInt(duration);
        return t.setCaptions([
          (
            id: id(),
            text: 'one two three',
            startUs: start,
            endUs: start + s(1.2),
            words: [
              (text: 'one', startUs: start, endUs: start + s(0.4)),
              (text: 'two', startUs: start + s(0.4), endUs: start + s(0.8)),
              (text: 'three', startUs: start + s(0.8), endUs: start + s(1.2)),
            ],
          ),
        ]);
      },
    ),
    (
      'mix',
      (t) => t.setAudioMix(
        originalSoundEnabled: rng.nextBool(),
        originalLevel: rng.nextDouble() * 3,
      ),
    ),
    if (clipIds.isNotEmpty) ...[
      ('delete clip', (t) => t.deleteClip(pick(clipIds))),
      ('duplicate clip', (t) => t.duplicateClip(pick(clipIds), newId: id())),
      ('split clip', (t) => t.splitClip(pick(clipIds), anyTime(), newId: id())),
      ('trim clip', (t) => t.trimClip(pick(clipIds), edge, delta())),
      (
        'move clip',
        (t) => t.moveClip(pick(clipIds), rng.nextInt(clipIds.length)),
      ),
      ('speed', (t) => t.setClipSpeed(pick(clipIds), rng.nextDouble() * 5)),
      ('volume', (t) => t.setClipVolume(pick(clipIds), rng.nextDouble() * 3)),
      (
        'transition',
        (t) => t.setTransition(
          pick(clipIds),
          rng.nextBool() ? pick(TransitionType.values) : null,
          durationUs: rng.nextInt(s(3)),
        ),
      ),
      (
        'all transitions',
        (t) => t.applyTransitionToAll(
          pick(TransitionType.values),
          durationUs: rng.nextInt(s(2)),
        ),
      ),
      ('extract', (t) => t.extractAudio(pick(clipIds), newId: id(), name: 'x')),
      (
        'replace',
        (t) => t.replaceClipMedia(
          pick(clipIds),
          mediaId: 'r',
          kind: MediaKind.video,
          mediaDurationUs: s(0.5 + rng.nextInt(10)),
        ),
      ),
    ],
    if (textIds.isNotEmpty) ...[
      (
        'move text',
        (t) => t.moveText(pick(textIds), anyTime(), lane: rng.nextInt(3)),
      ),
      ('trim text', (t) => t.trimText(pick(textIds), edge, delta())),
      ('split text', (t) => t.splitText(pick(textIds), anyTime(), newId: id())),
      ('dup text', (t) => t.duplicateText(pick(textIds), newId: id())),
      ('delete text', (t) => t.deleteText(pick(textIds))),
    ],
    if (audioIds.isNotEmpty) ...[
      (
        'move audio',
        (t) => t.moveAudio(pick(audioIds), anyTime(), lane: rng.nextInt(3)),
      ),
      ('trim audio', (t) => t.trimAudio(pick(audioIds), edge, delta())),
      (
        'split audio',
        (t) => t.splitAudio(pick(audioIds), anyTime(), newId: id()),
      ),
      (
        'fades',
        (t) => t.setAudioFades(
          pick(audioIds),
          fadeInUs: rng.nextInt(s(5)),
          fadeOutUs: rng.nextInt(s(5)),
        ),
      ),
      (
        'audio speed',
        (t) => t.setAudioSpeed(pick(audioIds), rng.nextDouble() * 5),
      ),
      ('loop', (t) => t.setAudioLoop(pick(audioIds), loop: rng.nextBool())),
      ('delete audio', (t) => t.deleteAudio(pick(audioIds))),
    ],
    if (captionIds.isNotEmpty) ...[
      (
        'edit caption',
        (t) => t.editCaptionText(pick(captionIds), 'new words here now'),
      ),
      (
        'split caption',
        (t) =>
            t.splitCaption(pick(captionIds), 1 + rng.nextInt(2), newId: id()),
      ),
      ('trim caption', (t) => t.trimCaption(pick(captionIds), edge, delta())),
      ('move caption', (t) => t.moveCaption(pick(captionIds), anyTime())),
    ],
  ];
  return pick(edits);
}

List<String> _violations(Timeline t) {
  final problems = <String>[];
  final layout = TimelineLayout.of(t);
  final clips = t.videoClips;
  final clipIds = {for (final c in clips) c.id};

  // Ids are unique within each collection.
  void unique(String what, Iterable<String> ids) {
    if (ids.toSet().length != ids.length) problems.add('duplicate $what ids');
  }

  unique('clip', clips.map((c) => c.id));
  unique('text', t.textItems.map((x) => x.id));
  unique('audio', t.audioItems.map((x) => x.id));
  unique('caption', t.captionTrack.segments.map((x) => x.id));

  for (final c in clips) {
    if (c.durationUs < TimelineLimits.minDurationUs - 1) {
      problems.add('clip ${c.id} shorter than minimum: ${c.durationUs}');
    }
    if (c.sourceInUs < 0) problems.add('clip ${c.id} starts before source');
    if (c.mediaDurationUs case final d? when c.sourceOutUs > d) {
      problems.add('clip ${c.id} ends after source');
    }
    if (c.speed < TimelineLimits.minSpeed ||
        c.speed > TimelineLimits.maxSpeed) {
      problems.add('clip ${c.id} speed ${c.speed}');
    }
    if (c.volume < 0 || c.volume > TimelineLimits.maxVolume) {
      problems.add('clip ${c.id} volume ${c.volume}');
    }
  }

  final seen = <String>{};
  for (final tr in t.transitions) {
    final i = t.indexOfClip(tr.afterClipId);
    if (i < 0 || i == clips.length - 1) {
      problems.add('transition after ${tr.afterClipId} has no cut');
      continue;
    }
    if (!seen.add(tr.afterClipId)) problems.add('two transitions in one cut');
    final cap = transitionCapUs(clips[i], clips[i + 1]);
    if (tr.durationUs > cap || tr.durationUs <= 0) {
      problems.add('transition ${tr.durationUs} outside (0, $cap]');
    }
  }

  void anchorOk(String what, Anchor a) {
    if (a is ClipAnchor && !clipIds.contains(a.clipId)) {
      problems.add('$what anchored to missing clip ${a.clipId}');
    }
    if (a is TimeAnchor && clips.isNotEmpty) {
      problems.add('$what has an absolute anchor while clips exist');
    }
  }

  for (final x in t.textItems) {
    anchorOk('text ${x.id}', x.anchor);
  }
  for (final x in t.audioItems) {
    anchorOk('audio ${x.id}', x.anchor);
    if (x.fadeInUs < 0 || x.fadeOutUs < 0) problems.add('negative fade');
    if (x.fadeInUs + x.fadeOutUs > x.durationUs) {
      problems.add('audio ${x.id} fades longer than item');
    }
    if (x.sourceInUs < 0 || x.sourceOutUs > x.mediaDurationUs) {
      problems.add('audio ${x.id} outside its source');
    }
  }
  for (final x in t.captionTrack.segments) {
    anchorOk('caption ${x.id}', x.anchor);
    for (final w in x.words) {
      if (w.startOffsetUs < 0 || w.endOffsetUs > x.durationUs) {
        problems.add('caption ${x.id} word outside segment');
      }
    }
  }

  void noOverlaps(String what, List<(int, int, int)> items) {
    for (var i = 0; i < items.length; i++) {
      for (var j = i + 1; j < items.length; j++) {
        final (la, sa, ea) = items[i];
        final (lb, sb, eb) = items[j];
        if (la == lb && sa < eb && sb < ea) {
          problems.add('$what overlap on lane $la');
        }
      }
    }
  }

  noOverlaps('text', [
    for (final x in t.textItems)
      (
        x.laneIndex,
        layout.startOf(x.anchor),
        layout.startOf(x.anchor) + x.durationUs,
      ),
  ]);
  noOverlaps('audio', [
    for (final x in t.audioItems)
      (x.laneIndex, layout.startOf(x.anchor), audioEndUs(x, layout)),
  ]);

  // Composition: clips are contiguous (minus transitions) and every item
  // lies inside the video.
  final comp = ResolvedComposition.resolve(t);
  for (var i = 0; i + 1 < comp.clips.length; i++) {
    final gap = comp.clips[i].endUs - comp.clips[i + 1].startUs;
    if (gap != layout.transitionUs(comp.clips[i].clipId)) {
      problems.add('clips $i and ${i + 1} not contiguous');
    }
  }
  bool inside(int a, int b) => a >= 0 && b <= comp.durationUs && a < b;
  for (final x in comp.texts) {
    if (!inside(x.startUs, x.endUs)) problems.add('text outside video');
  }
  for (final x in comp.captions) {
    if (!inside(x.startUs, x.endUs)) problems.add('caption outside video');
  }
  for (final x in comp.audio) {
    if (!inside(x.startUs, x.endUs)) problems.add('audio outside video');
    if (x.fadeInUs + x.fadeOutUs > x.endUs - x.startUs) {
      problems.add('resolved fades longer than audio');
    }
  }

  // Round trip.
  final json = jsonDecode(jsonEncode(t.toJson())) as Map<String, dynamic>;
  if (Timeline.fromJson(json) != t) problems.add('JSON round trip differs');

  // Normalizing a normalized timeline changes nothing.
  if (normalize(t) != t) problems.add('not normalized');

  return problems;
}
