import 'package:stitch/features/timeline/domain/layout.dart';
import 'package:stitch/features/timeline/domain/models.dart';

/// Seconds to microseconds, for readable tests.
int s(num seconds) => (seconds * 1000000).round();

/// A video clip showing [seconds] of a 60s file, starting at [from].
VideoClip clip(
  String id,
  num seconds, {
  num from = 0,
  double speed = 1,
  num mediaSeconds = 60,
}) => VideoClip(
  id: id,
  mediaId: 'media-$id',
  kind: MediaKind.video,
  mediaDurationUs: s(mediaSeconds),
  sourceInUs: s(from),
  sourceOutUs: s(from + seconds),
  speed: speed,
);

/// Clips a, b, c, ... of the given lengths in seconds.
Timeline track(List<num> lengths) => Timeline(
  videoClips: [
    for (final (i, len) in lengths.indexed)
      clip(String.fromCharCode(97 + i), len),
  ],
);

extension TestLayout on Timeline {
  TimelineLayout get layout => TimelineLayout.of(this);

  int startOfClip(String id) => layout.span(id)!.startUs;

  int get durationUs => layout.durationUs;

  int startOfText(String id) =>
      layout.startOf(textItems.firstWhere((t) => t.id == id).anchor);

  int startOfAudio(String id) =>
      layout.startOf(audioItems.firstWhere((a) => a.id == id).anchor);

  int startOfCaption(String id) => layout.startOf(
    captionTrack.segments.firstWhere((c) => c.id == id).anchor,
  );
}
