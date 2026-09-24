import AVFoundation
import CoreImage

/// One clip drawn during an instruction's time range.
struct CompositorLayer {
  /// Composition track to read frames from, or nil for photos and missing
  /// files.
  let trackID: CMPersistentTrackID?
  /// Still image to draw instead of a track frame.
  let photoPath: String?
  /// Rotation (degrees clockwise) needed to display the source upright.
  let sourceRotationDeg: Int
  let framing: EngineDocument.Framing
  /// Clip timeline range, for transition progress.
  let clipStartUs: Int64
  let clipEndUs: Int64
}

/// A transition in progress during an instruction's time range.
struct CompositorTransition {
  let type: String
  let startUs: Int64
  let durationUs: Int64
}

/// What the compositor draws for one stretch of time: one clip, or two
/// clips crossing in a transition (outgoing first).
///
/// Immutable after init, so safe to share with the compositor's queue.
final class StitchInstruction: NSObject, AVVideoCompositionInstructionProtocol,
  @unchecked Sendable
{
  let timeRange: CMTimeRange
  let enablePostProcessing = false
  let containsTweening = true
  let requiredSourceTrackIDs: [NSValue]?
  let passthroughTrackID = kCMPersistentTrackID_Invalid

  let layers: [CompositorLayer]
  let transition: CompositorTransition?
  let canvasSize: CGSize
  let background: EngineDocument.Background

  init(
    timeRange: CMTimeRange,
    layers: [CompositorLayer],
    transition: CompositorTransition?,
    canvasSize: CGSize,
    background: EngineDocument.Background
  ) {
    self.timeRange = timeRange
    self.layers = layers
    self.transition = transition
    self.canvasSize = canvasSize
    self.background = background
    let ids = layers.compactMap(\.trackID)
    requiredSourceTrackIDs = ids.isEmpty ? nil : ids.map { NSNumber(value: $0) }
  }
}

/// The document as AVFoundation objects, ready for a player or a reader.
struct BuiltComposition {
  let composition: AVMutableComposition
  let videoComposition: AVMutableVideoComposition?
  let audioMix: AVMutableAudioMix
  var duration: CMTime { composition.duration }
}

/// Builds the AVFoundation composition for an [EngineDocument].
///
/// Clips alternate between two video tracks (A and B) so that the clips on
/// either side of a transition overlap in time. Their sound alternates the
/// same way. Audio items are packed onto as few tracks as possible. Speed
/// changes scale each segment; pitch is kept by the player or reader's
/// time-pitch algorithm.
enum CompositionBuilder {
  static func build(
    _ doc: EngineDocument,
    forExport: Bool,
    renderSize: CGSize? = nil
  ) async throws -> BuiltComposition {
    let composition = AVMutableComposition()
    let comp = doc.composition
    let canvas = CGSize(width: doc.canvas.width, height: doc.canvas.height)

    var assets: [String: AVURLAsset] = [:]
    func asset(for mediaId: String) -> AVURLAsset? {
      if let cached = assets[mediaId] { return cached }
      guard let media = doc.media[mediaId] else { return nil }
      var path = media.path
      if !forExport, let proxy = media.proxyPath,
        FileManager.default.fileExists(atPath: proxy)
      {
        path = proxy
      }
      guard FileManager.default.fileExists(atPath: path) else { return nil }
      let a = AVURLAsset(
        url: URL(fileURLWithPath: path),
        options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
      )
      assets[mediaId] = a
      return a
    }

    // Video: tracks A and B.
    let videoTracks = [
      composition.addMutableTrack(
        withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!,
      composition.addMutableTrack(
        withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!,
    ]
    let clipAudioTracks = [
      composition.addMutableTrack(
        withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!,
      composition.addMutableTrack(
        withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!,
    ]
    var clipAudioParams: [CMPersistentTrackID: AVMutableAudioMixInputParameters] = [:]
    var layerInfo: [String: CompositorLayer] = [:]
    let blank = try await blankVideoTrack()

    for (index, clip) in comp.clips.enumerated() {
      let slot = index % 2
      let videoTrack = videoTracks[slot]
      let timelineRange = cmRange(startUs: clip.startUs, endUs: clip.endUs)
      let sourceRange = cmRange(startUs: clip.sourceInUs, endUs: clip.sourceOutUs)
      let media = doc.media[clip.mediaId]
      var usedTrack: CMPersistentTrackID? = nil
      var rotation = 0

      if clip.kind == "video", let a = asset(for: clip.mediaId),
        let source = try await a.loadTracks(withMediaType: .video).first
      {
        try await insert(
          source: source, sourceRange: sourceRange, into: videoTrack,
          at: timelineRange)
        usedTrack = videoTrack.trackID
        rotation = try await rotationDegrees(of: source)

        if clip.volume > 0, let audio = try await a.loadTracks(withMediaType: .audio).first {
          let audioTrack = clipAudioTracks[slot]
          try await insert(
            source: audio, sourceRange: sourceRange, into: audioTrack,
            at: timelineRange)
          let params =
            clipAudioParams[audioTrack.trackID]
            ?? AVMutableAudioMixInputParameters(track: audioTrack)
          applyVolume(
            to: params, volume: clip.volume, startUs: clip.startUs,
            endUs: clip.endUs, fadeInUs: clip.audioFadeInUs,
            fadeOutUs: clip.audioFadeOutUs)
          clipAudioParams[audioTrack.trackID] = params
        }
      } else {
        // Photos and missing files: stretch a black clip over the range so
        // the track has real frames and timing; the compositor draws the
        // photo (or black) instead of reading it.
        try await insert(
          source: blank, sourceRange: try await blank.load(.timeRange), into: videoTrack,
          at: timelineRange)
      }

      layerInfo[clip.clipId] = CompositorLayer(
        trackID: usedTrack,
        photoPath: clip.kind == "photo" ? media?.path : nil,
        sourceRotationDeg: rotation,
        framing: clip.framing,
        clipStartUs: clip.startUs,
        clipEndUs: clip.endUs
      )
    }

    // Keep pitch when clips are sped up or slowed down.
    for params in clipAudioParams.values {
      params.audioTimePitchAlgorithm = .spectral
    }

    // Audio items, packed onto tracks so none overlap on a track.
    var itemTracks: [(track: AVMutableCompositionTrack, endUs: Int64)] = []
    var itemParams: [AVMutableAudioMixInputParameters] = []
    for item in comp.audio.sorted(by: { $0.startUs < $1.startUs }) {
      guard let a = asset(for: item.mediaId),
        let source = try await a.loadTracks(withMediaType: .audio).first
      else { continue }
      let slot: Int
      if let free = itemTracks.firstIndex(where: { $0.endUs <= item.startUs }) {
        slot = free
      } else {
        itemTracks.append(
          (
            composition.addMutableTrack(
              withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!,
            0
          ))
        slot = itemTracks.count - 1
        itemParams.append(AVMutableAudioMixInputParameters(track: itemTracks[slot].track))
      }
      let track = itemTracks[slot].track
      // One pass of the source per insertion; loops repeat until the end.
      let passSourceUs = item.sourceOutUs - item.sourceInUs
      let passTimelineUs = Int64((Double(passSourceUs) / item.speed).rounded())
      var t = item.startUs
      while t < item.endUs, passTimelineUs > 0 {
        let segmentEnd = min(t + passTimelineUs, item.endUs)
        let sourceEnd =
          item.sourceInUs + Int64((Double(segmentEnd - t) * item.speed).rounded())
        try await insert(
          source: source,
          sourceRange: cmRange(startUs: item.sourceInUs, endUs: min(sourceEnd, item.sourceOutUs)),
          into: track,
          at: cmRange(startUs: t, endUs: segmentEnd))
        if !item.loop { break }
        t = segmentEnd
      }
      itemTracks[slot].endUs = item.endUs
      let params = itemParams[slot]
      params.audioTimePitchAlgorithm = .spectral
      applyVolume(
        to: params, volume: item.volume, startUs: item.startUs, endUs: item.endUs,
        fadeInUs: item.fadeInUs, fadeOutUs: item.fadeOutUs)
    }

    let audioMix = AVMutableAudioMix()
    audioMix.inputParameters = Array(clipAudioParams.values) + itemParams

    // Remove unused tracks so readers and players do not see empty ones.
    for track in composition.tracks where track.segments.isEmpty {
      composition.removeTrack(track)
    }

    let videoComposition = try buildVideoComposition(
      doc: doc, layers: layerInfo, canvas: canvas,
      renderSize: renderSize ?? canvas)

    return BuiltComposition(
      composition: composition, videoComposition: videoComposition, audioMix: audioMix)
  }

  /// Inserts [sourceRange] of [source] so it occupies [timelineRange],
  /// scaling for speed. Gaps before it on the track stay empty.
  private static func insert(
    source: AVAssetTrack, sourceRange: CMTimeRange,
    into track: AVMutableCompositionTrack, at timelineRange: CMTimeRange
  ) async throws {
    let available = try await source.load(.timeRange)
    let clamped = sourceRange.intersection(available)
    guard clamped.duration > .zero else { return }
    try track.insertTimeRange(clamped, of: source, at: timelineRange.start)
    let inserted = CMTimeRange(start: timelineRange.start, duration: clamped.duration)
    if inserted.duration != timelineRange.duration {
      track.scaleTimeRange(inserted, toDuration: timelineRange.duration)
    }
  }

  /// Volume ramps: silent outside [startUs, endUs), fading in and out.
  private static func applyVolume(
    to params: AVMutableAudioMixInputParameters, volume: Double,
    startUs: Int64, endUs: Int64, fadeInUs: Int64, fadeOutUs: Int64
  ) {
    let v = Float(max(0, volume))
    let fadeInEnd = min(startUs + fadeInUs, endUs)
    let fadeOutStart = max(endUs - fadeOutUs, fadeInEnd)
    if fadeInUs > 0 {
      params.setVolumeRamp(
        fromStartVolume: 0, toEndVolume: v,
        timeRange: cmRange(startUs: startUs, endUs: fadeInEnd))
    } else {
      params.setVolume(v, at: cmTime(us: startUs))
    }
    if fadeInEnd < fadeOutStart {
      params.setVolume(v, at: cmTime(us: fadeInEnd))
    }
    if fadeOutUs > 0 {
      params.setVolumeRamp(
        fromStartVolume: v, toEndVolume: 0,
        timeRange: cmRange(startUs: fadeOutStart, endUs: endUs))
    }
    params.setVolume(0, at: cmTime(us: endUs))
  }

  private static func buildVideoComposition(
    doc: EngineDocument, layers: [String: CompositorLayer], canvas: CGSize,
    renderSize: CGSize
  ) throws -> AVMutableVideoComposition? {
    let comp = doc.composition
    guard comp.durationUs > 0, !comp.clips.isEmpty else { return nil }

    // Cut the timeline where any clip starts or ends; each piece shows one
    // clip, or two during a transition.
    var cuts = Set<Int64>([0, comp.durationUs])
    for c in comp.clips {
      cuts.insert(c.startUs)
      cuts.insert(c.endUs)
    }
    let times = cuts.filter { $0 >= 0 && $0 <= comp.durationUs }.sorted()
    let transitionsByTo = Dictionary(
      comp.transitions.map { ($0.toClipId, $0) }, uniquingKeysWith: { a, _ in a })

    var instructions: [StitchInstruction] = []
    for (t0, t1) in zip(times, times.dropFirst()) where t1 > t0 {
      let active = comp.clips.filter { $0.startUs < t1 && $0.endUs > t0 }
      let active2 = Array(active.suffix(2))
      var transition: CompositorTransition? = nil
      if active2.count == 2, let tr = transitionsByTo[active2[1].clipId] {
        transition = CompositorTransition(
          type: tr.type, startUs: tr.startUs, durationUs: tr.durationUs)
      }
      instructions.append(
        StitchInstruction(
          timeRange: cmRange(startUs: t0, endUs: t1),
          layers: active2.compactMap { layers[$0.clipId] },
          transition: transition,
          canvasSize: canvas,
          background: doc.background))
    }

    let videoComposition = AVMutableVideoComposition()
    videoComposition.customVideoCompositorClass = StitchCompositor.self
    videoComposition.renderSize = renderSize
    videoComposition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(doc.canvas.frameRate))
    videoComposition.instructions = instructions
    // Output is SDR Rec. 709; HDR sources are tone mapped before they reach
    // the compositor (it does not declare HDR support).
    videoComposition.colorPrimaries = AVVideoColorPrimaries_ITU_R_709_2
    videoComposition.colorTransferFunction = AVVideoTransferFunction_ITU_R_709_2
    videoComposition.colorYCbCrMatrix = AVVideoYCbCrMatrix_ITU_R_709_2
    return videoComposition
  }

  /// The bundled one-second black clip used under photos and missing
  /// files. The asset is kept for the app's lifetime: a track is only
  /// valid while its asset is alive.
  private static let blankAsset: AVURLAsset? = Bundle.main
    .url(forResource: "blank", withExtension: "mp4")
    .map { AVURLAsset(url: $0) }

  private static func blankVideoTrack() async throws -> AVAssetTrack {
    guard let asset = blankAsset,
      let track = try await asset.loadTracks(withMediaType: .video).first
    else { throw EngineError.badDocument("blank.mp4 missing from the app bundle") }
    return track
  }

  /// Clockwise rotation encoded in the track's preferred transform.
  static func rotationDegrees(of track: AVAssetTrack) async throws -> Int {
    let t = try await track.load(.preferredTransform)
    let angle = atan2(t.b, t.a) * 180 / .pi
    let rounded = Int((angle / 90).rounded()) * 90
    return (rounded + 360) % 360
  }
}
