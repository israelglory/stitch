import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Export resolutions, by the output's shorter side.
enum ExportResolution {
  hd(720),
  fullHd(1080),
  uhd(2160);

  new(this.shortSide);

  final int shortSide;
}

/// Smaller files use 60 percent of the better quality bitrate.
enum ExportQuality { smaller, better }

const exportFrameRates = [24, 30, 60];

/// AAC, for every export.
const exportAudioBitrate = 192000;

/// What an export makes.
@immutable
final class ExportOptions {
  const new({
    this.resolution = ExportResolution.fullHd,
    this.frameRate = 30,
    this.quality = ExportQuality.better,
    this.hevc = false,
    this.captionsFile = false,
  });

  final ExportResolution resolution;
  final int frameRate;
  final ExportQuality quality;

  /// HEVC instead of H.264, where the device encodes it.
  final bool hevc;

  /// Also writes the captions as an SRT file.
  final bool captionsFile;

  ExportOptions copyWith({
    ExportResolution? resolution,
    int? frameRate,
    ExportQuality? quality,
    bool? hevc,
    bool? captionsFile,
  }) => ExportOptions(
    resolution: resolution ?? this.resolution,
    frameRate: frameRate ?? this.frameRate,
    quality: quality ?? this.quality,
    hevc: hevc ?? this.hevc,
    captionsFile: captionsFile ?? this.captionsFile,
  );

  @override
  bool operator ==(Object other) =>
      other is ExportOptions &&
      other.resolution == resolution &&
      other.frameRate == frameRate &&
      other.quality == quality &&
      other.hevc == hevc &&
      other.captionsFile == captionsFile;

  @override
  int get hashCode =>
      Object.hash(resolution, frameRate, quality, hevc, captionsFile);
}

/// The output size for a [canvasWidth] x [canvasHeight] canvas: scaled so
/// its shorter side is [resolution], in even numbers (encoders need them).
({int width, int height}) exportSize(
  int canvasWidth,
  int canvasHeight,
  ExportResolution resolution,
) {
  final scale = resolution.shortSide / math.min(canvasWidth, canvasHeight);
  int even(num v) => math.max(2, (v / 2).round() * 2);
  return (width: even(canvasWidth * scale), height: even(canvasHeight * scale));
}

/// Video bits per second. At 30 fps: 720p about 5, 1080p about 10, and 4K
/// about 35 Mbps. 60 fps takes half as much again and 24 fps a fifth less;
/// smaller files take 60 percent, and HEVC 70 percent for the same look.
int videoBitrate(ExportOptions options) {
  final base = switch (options.resolution) {
    ExportResolution.hd => 5000000,
    ExportResolution.fullHd => 10000000,
    ExportResolution.uhd => 35000000,
  };
  final fps = switch (options.frameRate) {
    >= 50 => 1.5,
    <= 25 => 0.8,
    _ => 1.0,
  };
  final quality = options.quality == ExportQuality.smaller ? 0.6 : 1.0;
  final codec = options.hevc ? 0.7 : 1.0;
  return (base * fps * quality * codec).round();
}

/// About how large [durationUs] of video will be, container included.
int estimatedExportBytes(ExportOptions options, int durationUs) =>
    ((videoBitrate(options) + exportAudioBitrate) * durationUs / 8e6 * 1.02)
        .round();

/// Free space an export needs: the file, its copy in the photo library,
/// and room to spare.
int exportSpaceNeeded(int estimatedBytes) =>
    estimatedBytes * 2 + 100 * 1000 * 1000;
