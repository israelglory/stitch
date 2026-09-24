import AVFoundation
import XCTest

@testable import Runner

/// Engine tests against the media corpus in test_media/ (regenerate with
/// tool/make_test_media.sh).
final class EngineTests: XCTestCase {
  private func media(_ name: String) -> String {
    let bundle = Bundle(for: EngineTests.self)
    let dir = bundle.url(forResource: "test_media", withExtension: nil)!
    return dir.appendingPathComponent(name).path
  }

  private var tempDir: URL!

  override func setUp() {
    tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  }

  override func tearDown() {
    try? FileManager.default.removeItem(at: tempDir)
  }

  // MARK: Probe

  func testProbeVariableFrameRateVideo() async throws {
    let info = try await MediaProbe.probe(path: media("vfr.mp4"))
    XCTAssertEqual(info.width, 360)
    XCTAssertEqual(info.height, 640)
    XCTAssertTrue(info.hasAudio)
    XCTAssertEqual(Double(info.durationUs!) / 1e6, 3.93, accuracy: 0.1)
  }

  func testProbeRotatedVideoReportsDisplaySize() async throws {
    let info = try await MediaProbe.probe(path: media("rotated_portrait.mp4"))
    XCTAssertEqual(info.width, 360, "stored 640x360, displayed portrait")
    XCTAssertEqual(info.height, 640)
    XCTAssertTrue(info.rotationDeg == 90 || info.rotationDeg == 270)
  }

  func testProbeHdrAndSilentAndStillAndAudio() async throws {
    let hdr = try await MediaProbe.probe(path: media("hevc_hdr.mov"))
    XCTAssertTrue(hdr.isHdr)

    let silent = try await MediaProbe.probe(path: media("no_audio.mp4"))
    XCTAssertFalse(silent.hasAudio)

    let still = try await MediaProbe.probe(path: media("still.jpg"))
    XCTAssertNil(still.durationUs)
    XCTAssertEqual(still.width, 1200)
    XCTAssertEqual(still.height, 1600)

    for name in ["music.mp3", "audio_44k.m4a", "audio_48k.wav"] {
      let audio = try await MediaProbe.probe(path: media(name))
      XCTAssertFalse(audio.hasVideo, name)
      XCTAssertTrue(audio.hasAudio, name)
    }
  }

  func testProbeMissingFileThrows() async {
    do {
      _ = try await MediaProbe.probe(path: "/nope/missing.mp4")
      XCTFail("expected an error")
    } catch let e as EngineError {
      XCTAssertEqual(e.code, "missing_file")
    } catch {
      XCTFail("unexpected \(error)")
    }
  }

  // MARK: Composition

  /// Two clips with a 0.5 s crossfade, a photo, and looping music.
  private func sampleDocument(background: String = "solid") -> EngineDocument {
    let json = """
      {
        "canvas": {"width": 360, "height": 640, "frameRate": 30},
        "background": {"type": "\(background)", "color": 4278190080},
        "media": {
          "a": {"path": "\(media("vfr.mp4"))", "kind": "video"},
          "b": {"path": "\(media("rotated_portrait.mp4"))", "kind": "video"},
          "p": {"path": "\(media("still.jpg"))", "kind": "photo"},
          "m": {"path": "\(media("music.mp3"))", "kind": "audio"}
        },
        "composition": {
          "durationUs": 6500000,
          "clips": [
            {"clipId": "c1", "mediaId": "a", "kind": "video", "startUs": 0,
             "endUs": 2000000, "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1,
             "volume": 1, "audioFadeInUs": 0, "audioFadeOutUs": 500000,
             "framing": {"mode": "fit", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}},
            {"clipId": "c2", "mediaId": "b", "kind": "video", "startUs": 1500000,
             "endUs": 3500000, "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1,
             "volume": 1, "audioFadeInUs": 500000, "audioFadeOutUs": 0,
             "framing": {"mode": "fill", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}},
            {"clipId": "c3", "mediaId": "p", "kind": "photo", "startUs": 3500000,
             "endUs": 6500000, "sourceInUs": 0, "sourceOutUs": 3000000, "speed": 1,
             "volume": 0, "audioFadeInUs": 0, "audioFadeOutUs": 0,
             "framing": {"mode": "fit", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}}
          ],
          "transitions": [
            {"type": "crossfade", "fromClipId": "c1", "toClipId": "c2",
             "startUs": 1500000, "durationUs": 500000}
          ],
          "audio": [
            {"id": "m1", "mediaId": "m", "startUs": 1000000, "endUs": 6500000,
             "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1, "loop": true,
             "volume": 0.8, "fadeInUs": 200000, "fadeOutUs": 500000}
          ]
        }
      }
      """
    return try! EngineDocument.decode(json)
  }

  func testCompositionCoversTheWholeDocument() async throws {
    let built = try await CompositionBuilder.build(sampleDocument(), forExport: true)
    XCTAssertEqual(built.duration.seconds, 6.5, accuracy: 0.01)

    let instructions = built.videoComposition!.instructions
    XCTAssertEqual(instructions.first!.timeRange.start, .zero)
    for (a, b) in zip(instructions, instructions.dropFirst()) {
      XCTAssertEqual(a.timeRange.end, b.timeRange.start, "instructions are contiguous")
    }
    XCTAssertEqual(instructions.last!.timeRange.end.seconds, 6.5, accuracy: 0.001)

    let crossing = instructions.compactMap { $0 as? StitchInstruction }
      .first { $0.transition != nil }!
    XCTAssertEqual(crossing.layers.count, 2)
    XCTAssertEqual(crossing.timeRange.start.seconds, 1.5, accuracy: 0.001)
    XCTAssertEqual(crossing.timeRange.end.seconds, 2.0, accuracy: 0.001)

    // Clip sound on A and B, music on its own track.
    XCTAssertEqual(built.composition.tracks(withMediaType: .audio).count, 3)
  }

  func testSpeedScalesTheSegment() async throws {
    let json = """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"a": {"path": "\(media("vfr.mp4"))", "kind": "video"}},
       "composition": {"durationUs": 1000000, "clips": [
         {"clipId": "c", "mediaId": "a", "kind": "video", "startUs": 0, "endUs": 1000000,
          "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 2, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0,
          "framing": {"mode": "fit", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}}]}}
      """
    let built = try await CompositionBuilder.build(try EngineDocument.decode(json), forExport: true)
    XCTAssertEqual(built.duration.seconds, 1.0, accuracy: 0.01)
  }

  // MARK: Export

  private func export(
    _ doc: EngineDocument, width: Int64 = 360, height: Int64 = 640, fps: Int64 = 30,
    hevc: Bool = false
  ) async throws -> AVURLAsset {
    let out = tempDir.appendingPathComponent("out.mp4").path
    let exporter = Exporter(
      doc: doc,
      request: ExportRequestMessage(
        outputPath: out, width: width, height: height, frameRate: fps,
        videoBitrate: 2_000_000, hevc: hevc))
    var last = 0.0
    let path = try await exporter.run { last = $0 }
    XCTAssertEqual(last, 1)
    XCTAssertFalse(
      FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("out.part.mp4").path))
    return AVURLAsset(url: URL(fileURLWithPath: path))
  }

  func testExportMatchesTheDocument() async throws {
    let asset = try await export(sampleDocument())
    let duration = try await asset.load(.duration)
    XCTAssertEqual(duration.seconds, 6.5, accuracy: 0.1)

    let video = try await asset.loadTracks(withMediaType: .video).first!
    let (size, fps) = try await video.load(.naturalSize, .nominalFrameRate)
    XCTAssertEqual(size.width, 360)
    XCTAssertEqual(size.height, 640)
    XCTAssertEqual(Double(fps), 30, accuracy: 1)
    let audio = try await asset.loadTracks(withMediaType: .audio)
    XCTAssertEqual(audio.count, 1, "one mixed audio track")
  }

  func testExportDrawsFramesNotBlack() async throws {
    let asset = try await export(sampleDocument())
    let generator = AVAssetImageGenerator(asset: asset)
    generator.requestedTimeToleranceBefore = .zero
    generator.requestedTimeToleranceAfter = .zero
    // A video clip, the crossfade, and the photo.
    for seconds in [0.5, 1.75, 5.0] {
      let (image, _) = try await generator.image(at: CMTime(seconds: seconds, preferredTimescale: 600))
      XCTAssertGreaterThan(meanBrightness(image), 0.1, "frame at \(seconds)s is drawn")
    }
  }

  func testExportAt60fpsAndDifferentSize() async throws {
    let asset = try await export(sampleDocument(background: "blur"), width: 720, height: 1280, fps: 60)
    let video = try await asset.loadTracks(withMediaType: .video).first!
    let (size, fps) = try await video.load(.naturalSize, .nominalFrameRate)
    XCTAssertEqual(size.width, 720)
    XCTAssertEqual(Double(fps), 60, accuracy: 2)
  }

  func testHdrSourceExportsAsSdr() async throws {
    let json = """
      {"canvas": {"width": 540, "height": 960, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"h": {"path": "\(media("hevc_hdr.mov"))", "kind": "video"}},
       "composition": {"durationUs": 2000000, "clips": [
         {"clipId": "c", "mediaId": "h", "kind": "video", "startUs": 0, "endUs": 2000000,
          "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0,
          "framing": {"mode": "fit", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}}]}}
      """
    let asset = try await export(try EngineDocument.decode(json), width: 540, height: 960)
    let video = try await asset.loadTracks(withMediaType: .video).first!
    let format = try await video.load(.formatDescriptions).first!
    let transfer = CMFormatDescriptionGetExtension(
      format, extensionKey: kCMFormatDescriptionExtension_TransferFunction) as? String
    XCTAssertEqual(transfer, kCMFormatDescriptionTransferFunction_ITU_R_709_2 as String)
  }

  func testPhotoOnlyProjectExports() async throws {
    let json = """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4294967295},
       "media": {"p": {"path": "\(media("still.jpg"))", "kind": "photo"}},
       "composition": {"durationUs": 3000000, "clips": [
         {"clipId": "c", "mediaId": "p", "kind": "photo", "startUs": 0, "endUs": 3000000,
          "sourceInUs": 0, "sourceOutUs": 3000000, "speed": 1, "volume": 0,
          "audioFadeInUs": 0, "audioFadeOutUs": 0,
          "framing": {"mode": "fit", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}}]}}
      """
    let asset = try await export(try EngineDocument.decode(json))
    let duration = try await asset.load(.duration)
    XCTAssertEqual(duration.seconds, 3, accuracy: 0.1)
  }

  func testCancelStopsAndLeavesNoFile() async throws {
    let out = tempDir.appendingPathComponent("cancel.mp4").path
    let json = """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"l": {"path": "\(media("long.mp4"))", "kind": "video"}},
       "composition": {"durationUs": 60000000, "clips": [
         {"clipId": "c", "mediaId": "l", "kind": "video", "startUs": 0, "endUs": 60000000,
          "sourceInUs": 0, "sourceOutUs": 60000000, "speed": 1, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0,
          "framing": {"mode": "fit", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}}]}}
      """
    let exporter = Exporter(
      doc: try EngineDocument.decode(json),
      request: ExportRequestMessage(
        outputPath: out, width: 360, height: 640, frameRate: 30, videoBitrate: 1_000_000,
        hevc: false))
    var cancelled = false
    do {
      _ = try await exporter.run { fraction in
        if fraction > 0.05, !cancelled {
          cancelled = true
          exporter.cancel()
        }
      }
      XCTFail("expected cancel")
    } catch let e as EngineError {
      XCTAssertEqual(e.code, "cancelled")
    }
    XCTAssertFalse(FileManager.default.fileExists(atPath: out))
  }

  // MARK: Performance (reported, not a pass/fail gate: simulators are not
  // representative of the iPhone 12 target)

  func testReportExportSpeedOneMinute1080p() async throws {
    let json = """
      {"canvas": {"width": 1080, "height": 1920, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"l": {"path": "\(media("long.mp4"))", "kind": "video"}},
       "composition": {"durationUs": 60000000, "clips": [
         {"clipId": "c", "mediaId": "l", "kind": "video", "startUs": 0, "endUs": 60000000,
          "sourceInUs": 0, "sourceOutUs": 60000000, "speed": 1, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0,
          "framing": {"mode": "fill", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}}]}}
      """
    let start = Date()
    _ = try await export(
      try EngineDocument.decode(json), width: 1080, height: 1920, fps: 30)
    let seconds = Date().timeIntervalSince(start)
    print("PERF export 60s 1080p30: \(String(format: "%.1f", seconds))s")
    XCTAssertLessThan(seconds, 600)
  }

  // MARK: Thumbnails and proxies

  func testThumbnailsAreWrittenAndCached() async throws {
    let dir = tempDir.appendingPathComponent("thumbs").path
    let paths = await Thumbnailer.thumbnails(
      path: media("rotated_portrait.mp4"), timesUs: [0, 1_000_000, 2_000_000], maxSize: 128,
      outDir: dir)
    XCTAssertEqual(paths.compactMap { $0 }.count, 3)
    let image = UIImage(contentsOfFile: paths[0]!)!
    XCTAssertGreaterThan(image.size.height, image.size.width, "upright portrait")

    let still = await Thumbnailer.thumbnails(
      path: media("still.jpg"), timesUs: [0, 500_000], maxSize: 64, outDir: dir)
    XCTAssertEqual(still[0], still[1], "a still has one frame")
  }

  func testProxyIsSmaller() async throws {
    let out = tempDir.appendingPathComponent("proxy.mp4").path
    try await ProxyMaker.createProxy(path: media("large_1440p.mp4"), outPath: out)
    let info = try await MediaProbe.probe(path: out)
    XCTAssertLessThanOrEqual(max(info.width, info.height), 1280)
  }

  private func meanBrightness(_ image: CGImage) -> Double {
    let ci = CIImage(cgImage: image)
    let filter = CIFilter(name: "CIAreaAverage", parameters: [
      kCIInputImageKey: ci, kCIInputExtentKey: CIVector(cgRect: ci.extent),
    ])!
    var pixel = [UInt8](repeating: 0, count: 4)
    CIContext().render(
      filter.outputImage!, toBitmap: &pixel, rowBytes: 4,
      bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
    return (Double(pixel[0]) + Double(pixel[1]) + Double(pixel[2])) / (3 * 255)
  }
}
