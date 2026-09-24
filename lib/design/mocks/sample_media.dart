// Sample media for mock-ups: the design gallery, goldens, and the
// onboarding illustrations of the editor. Never used for user content.
import 'package:flutter/widgets.dart';

/// Stand-ins for video frames: flat, muted tones so the UI is judged
/// against something that looks like footage without real media.
const _sampleTones = [
  Color(0xFF3E4A52),
  Color(0xFF5B5A4E),
  Color(0xFF6D5C4F),
  Color(0xFF4B5F58),
  Color(0xFF394354),
  Color(0xFF5E4E57),
];

Widget sampleFrame(int i) =>
    ColoredBox(color: _sampleTones[i % _sampleTones.length]);

/// Deterministic waveform so goldens are stable.
List<double> sampleWaveform(int count, {int seed = 1}) => [
  for (var i = 0; i < count; i++)
    (0.25 + 0.6 * (((i * 37 + seed * 11) % 17) / 16)) * (i % 7 == 0 ? 0.5 : 1),
];
