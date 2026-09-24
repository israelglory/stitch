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
      throw EngineError.exportFailed(session.error?.localizedDescription ?? "Proxy failed")
    }
    try? FileManager.default.removeItem(atPath: outPath)
    try FileManager.default.moveItem(at: temp, to: URL(fileURLWithPath: outPath))
  }
}
