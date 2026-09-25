import AVFoundation
import CoreImage
import ImageIO
import UniformTypeIdentifiers

/// Reads what a file contains: exact duration, display size after
/// rotation, frame rate, and whether it has sound or HDR video.
enum MediaProbe {
  static func probe(path: String) async throws -> MediaInfoMessage {
    guard FileManager.default.fileExists(atPath: path) else {
      throw EngineError.missingFile(path)
    }
    let url = URL(fileURLWithPath: path)
    if let still = probeImage(url: url) { return still }

    let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    let (duration, tracks) = try await asset.load(.duration, .tracks)
    let video = tracks.first { $0.mediaType == .video }
    let hasAudio = tracks.contains { $0.mediaType == .audio }
    guard video != nil || hasAudio else { throw EngineError.unsupportedMedia(path) }

    var width = 0
    var height = 0
    var rotation = 0
    var fps = 0.0
    var hdr = false
    if let video {
      let (natural, rate, characteristics) = try await video.load(
        .naturalSize, .nominalFrameRate, .mediaCharacteristics)
      rotation = try await CompositionBuilder.rotationDegrees(of: video)
      let swap = rotation == 90 || rotation == 270
      width = Int(swap ? natural.height : natural.width)
      height = Int(swap ? natural.width : natural.height)
      fps = Double(rate)
      hdr = characteristics.contains(.containsHDRVideo)
    }
    return MediaInfoMessage(
      durationUs: duration.microseconds,
      width: Int64(width), height: Int64(height),
      rotationDeg: Int64(rotation), frameRate: fps,
      hasVideo: video != nil, hasAudio: hasAudio, isHdr: hdr)
  }

  private static func probeImage(url: URL) -> MediaInfoMessage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let type = CGImageSourceGetType(source) as String?,
      let utType = UTType(type), utType.conforms(to: .image),
      let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let w = props[kCGImagePropertyPixelWidth] as? Int,
      let h = props[kCGImagePropertyPixelHeight] as? Int
    else { return nil }
    let orientation = props[kCGImagePropertyOrientation] as? Int ?? 1
    // EXIF orientations 5 to 8 are rotated a quarter turn.
    let swap = (5...8).contains(orientation)
    return MediaInfoMessage(
      durationUs: nil, width: Int64(swap ? h : w), height: Int64(swap ? w : h),
      rotationDeg: 0, frameRate: 0, hasVideo: true, hasAudio: false, isHdr: false)
  }
}

/// Frames for the timeline filmstrip, written as small JPEGs.
enum Thumbnailer {
  static func thumbnails(
    path: String, timesUs: [Int64], maxSize: Int, outDir: String
  ) async -> [String?] {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(
      atPath: outDir, withIntermediateDirectories: true)
    let key = stableKey(path)

    if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let type = CGImageSourceGetType(source) as String?,
      UTType(type)?.conforms(to: .image) == true
    {
      let out = "\(outDir)/\(key)_still_\(maxSize).jpg"
      if !FileManager.default.fileExists(atPath: out) {
        let options: [CFString: Any] = [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: maxSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
          writeJPEG(image, to: out)
        else { return timesUs.map { _ in nil } }
      }
      return timesUs.map { _ in out }
    }

    let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: maxSize, height: maxSize)
    let tolerance = CMTime(value: 1, timescale: 10)
    generator.requestedTimeToleranceBefore = tolerance
    generator.requestedTimeToleranceAfter = tolerance

    var results: [String?] = []
    for t in timesUs {
      let out = "\(outDir)/\(key)_\(t)_\(maxSize).jpg"
      if FileManager.default.fileExists(atPath: out) {
        results.append(out)
        continue
      }
      if let (image, _) = try? await generator.image(at: cmTime(us: t)), writeJPEG(image, to: out) {
        results.append(out)
      } else {
        results.append(nil)
      }
    }
    return results
  }

  /// FNV-1a of the path. Stable across launches, unlike `hashValue`, so
  /// cached frames are found again.
  static func stableKey(_ s: String) -> String {
    var hash: UInt64 = 0xcbf2_9ce4_8422_2325
    for byte in s.utf8 {
      hash ^= UInt64(byte)
      hash = hash &* 0x100_0000_01b3
    }
    return String(hash, radix: 36)
  }

  static func writeJPEG(_ image: CGImage, to path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    guard
      let dest = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
    else { return false }
    CGImageDestinationAddImage(
      dest, image, [kCGImageDestinationLossyCompressionQuality: 0.7] as CFDictionary)
    return CGImageDestinationFinalize(dest)
  }
}

/// A 720p copy for smooth preview of large or long-GOP sources. Export
/// always reads the original.
enum ProxyMaker {
  static func createProxy(path: String, outPath: String) async throws {
    let asset = AVURLAsset(url: URL(fileURLWithPath: path))
    guard
      let session = AVAssetExportSession(
        asset: asset, presetName: AVAssetExportPreset1280x720)
    else { throw EngineError.unsupportedMedia(path) }
    let temp = URL(fileURLWithPath: outPath + ".part.mp4")
    try? FileManager.default.removeItem(at: temp)
    session.outputURL = temp
    session.outputFileType = .mp4
    // The async export(to:as:) needs iOS 18; this works from iOS 16.
    await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
      session.exportAsynchronously { done.resume() }
    }
    guard session.status == .completed else {
      try? FileManager.default.removeItem(at: temp)
      throw EngineError.exportFailed(session.error?.localizedDescription ?? "Proxy failed")
    }
    try? FileManager.default.removeItem(atPath: outPath)
    try FileManager.default.moveItem(at: temp, to: URL(fileURLWithPath: outPath))
  }
}

/// Loudness over time for the timeline's audio tiles.
enum Waveform {
  /// Decoding at a low rate is plenty for peaks drawn a few pixels wide.
  private static let sampleRate = 11_025

  /// The peak, 0 to 1, of every 1 / [peaksPerSecond] of a second of
  /// [path]'s sound; empty when it has none.
  static func peaks(path: String, peaksPerSecond: Int) async throws -> [Double] {
    guard FileManager.default.fileExists(atPath: path) else {
      throw EngineError.missingFile(path)
    }
    let asset = AVURLAsset(url: URL(fileURLWithPath: path))
    let tracks = try await asset.loadTracks(withMediaType: .audio)
    guard !tracks.isEmpty, peaksPerSecond > 0 else { return [] }
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderAudioMixOutput(
      audioTracks: tracks,
      audioSettings: [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsNonInterleaved: false,
      ])
    reader.add(output)
    guard reader.startReading() else { throw EngineError.unsupportedMedia(path) }
    // Decoding blocks for seconds; on its own queue it cannot hold up the
    // threads Swift's async work shares.
    let peaks = await withCheckedContinuation { (done: CheckedContinuation<[Double], Never>) in
      decodeQueue.async { done.resume(returning: decode(output, peaksPerSecond: peaksPerSecond)) }
    }
    if reader.status == .failed { throw EngineError.unsupportedMedia(path) }
    return peaks
  }

  private static let decodeQueue = DispatchQueue(label: "stitch.waveform", qos: .utility)

  private static func decode(_ output: AVAssetReaderOutput, peaksPerSecond: Int) -> [Double] {
    let bucket = max(1, sampleRate / peaksPerSecond)
    var peaks: [Double] = []
    var current: Int16 = 0
    var filled = 0
    while let buffer = output.copyNextSampleBuffer() {
      guard var block = CMSampleBufferGetDataBuffer(buffer) else { continue }
      if !CMBlockBufferIsRangeContiguous(block, atOffset: 0, length: 0) {
        var copy: CMBlockBuffer?
        CMBlockBufferCreateContiguous(
          allocator: nil, sourceBuffer: block, blockAllocator: nil, customBlockSource: nil,
          offsetToData: 0, dataLength: 0, flags: 0, blockBufferOut: &copy)
        guard let copy else { continue }
        block = copy
      }
      var length = 0
      var pointer: UnsafeMutablePointer<Int8>?
      CMBlockBufferGetDataPointer(
        block, atOffset: 0, lengthAtOffsetOut: &length, totalLengthOut: nil,
        dataPointerOut: &pointer)
      guard let pointer else { continue }
      let count = length / 2
      pointer.withMemoryRebound(to: Int16.self, capacity: count) { samples in
        for i in 0..<count {
          // Int16.min has no positive counterpart.
          let v = samples[i] == .min ? .max : abs(samples[i])
          if v > current { current = v }
          filled += 1
          if filled == bucket {
            peaks.append(Double(current) / Double(Int16.max))
            current = 0
            filled = 0
          }
        }
      }
    }
    if filled > 0 { peaks.append(Double(current) / Double(Int16.max)) }
    return peaks
  }
}
