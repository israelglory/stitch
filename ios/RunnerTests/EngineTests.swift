import AVFoundation
import UIKit
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
    hevc: Bool = false, name: String = "out"
  ) async throws -> AVURLAsset {
    let out = tempDir.appendingPathComponent("\(name).mp4").path
    let exporter = Exporter(
      doc: doc,
      request: ExportRequestMessage(
        outputPath: out, width: width, height: height, frameRate: fps,
        videoBitrate: 2_000_000, hevc: hevc, progressTitle: "Exporting"))
    var last = 0.0
    let path = try await exporter.run { last = $0 }
    XCTAssertEqual(last, 1)
    XCTAssertFalse(
      FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("\(name).part.mp4").path))
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
        hevc: false, progressTitle: "Exporting"))
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

  // MARK: Transitions

  /// A solid [color] image the size of the test canvas.
  private func solidPhoto(_ name: String, _ color: UIColor) -> String {
    let size = CGSize(width: 360, height: 640)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
      color.setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }
    let path = tempDir.appendingPathComponent("\(name).png").path
    try! image.pngData()!.write(to: URL(fileURLWithPath: path))
    return path
  }

  /// Two 2.4 s photo clips with a 1.2 s [type] transition from 1.2 s.
  private func transitionDocument(_ type: String, from: String, to: String) -> EngineDocument {
    let framing = #"{"mode": "fit", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}"#
    let json = """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"a": {"path": "\(from)", "kind": "photo"}, "b": {"path": "\(to)", "kind": "photo"}},
       "composition": {"durationUs": 3600000, "clips": [
         {"clipId": "c1", "mediaId": "a", "kind": "photo", "startUs": 0, "endUs": 2400000,
          "sourceInUs": 0, "sourceOutUs": 2400000, "speed": 1, "volume": 0,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": \(framing)},
         {"clipId": "c2", "mediaId": "b", "kind": "photo", "startUs": 1200000, "endUs": 3600000,
          "sourceInUs": 0, "sourceOutUs": 2400000, "speed": 1, "volume": 0,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": \(framing)}],
        "transitions": [{"type": "\(type)", "fromClipId": "c1", "toClipId": "c2",
          "startUs": 1200000, "durationUs": 1200000}]}}
      """
    return try! EngineDocument.decode(json)
  }

  func testTransitionsMatchTheSharedTable() async throws {
    let red = solidPhoto("red", .red)
    let blue = solidPhoto("blue", .blue)
    let data = try Data(contentsOf: URL(fileURLWithPath: media("transition_cases.json")))
    let table = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    let cases = table["cases"] as! [[String: Any]]
    var types: [String] = []
    for c in cases where !types.contains(c["type"] as! String) { types.append(c["type"] as! String) }

    var failures: [String] = []
    for type in types {
      let asset = try await export(transitionDocument(type, from: red, to: blue), name: type)
      let generator = AVAssetImageGenerator(asset: asset)
      generator.requestedTimeToleranceBefore = .zero
      generator.requestedTimeToleranceAfter = .zero
      let typeCases = cases.filter { $0["type"] as! String == type }
      for progress in Set(typeCases.map { $0["progress"] as! Double }).sorted() {
        let time = CMTime(value: Int64(1_200_000 + progress * 1_200_000), timescale: 1_000_000)
        let (image, _) = try await generator.image(at: time)
        let pixels = rgba(image)
        for c in typeCases where c["progress"] as! Double == progress {
          let x = c["x"] as! Double
          let y = c["y"] as! Double
          // Image rows run top down; the table's y runs bottom up.
          let col = Int(x * Double(image.width))
          let row = min(Int((1 - y) * Double(image.height)), image.height - 1)
          let i = (row * image.width + col) * 4
          let r = Double(pixels[i]) / 255
          let b = Double(pixels[i + 2]) / 255
          let wantR = c["from"] as! Double
          let wantB = c["to"] as! Double
          if abs(r - wantR) > 0.12 || abs(b - wantB) > 0.12 {
            failures.append(
              String(
                format: "%@ p=%.2f x=%.1f: red %.2f (want %.2f), blue %.2f (want %.2f)",
                type, progress, x, r, wantR, b, wantB))
          }
        }
      }
    }
    XCTAssert(failures.isEmpty, failures.joined(separator: "\n"))
  }

  /// [image] as tightly packed RGBA bytes, rows top down.
  private func rgba(_ image: CGImage) -> [UInt8] {
    var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
    let context = CGContext(
      data: &pixels, width: image.width, height: image.height, bitsPerComponent: 8,
      bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return pixels
  }

  // MARK: Sound

  func testWaveformHasPeaksOverTime() async throws {
    let peaks = try await Waveform.peaks(path: media("music.mp3"), peaksPerSecond: 20)
    let info = try await MediaProbe.probe(path: media("music.mp3"))
    let seconds = Double(info.durationUs!) / 1e6
    XCTAssertEqual(Double(peaks.count), seconds * 20, accuracy: 3)
    XCTAssertGreaterThan(peaks.max() ?? 0, 0.1)
    XCTAssertLessThanOrEqual(peaks.max() ?? 2, 1)
    let silent = try await Waveform.peaks(path: media("no_audio.mp4"), peaksPerSecond: 20)
    XCTAssertTrue(silent.isEmpty)
  }

  func testLimiterHoldsTheCeilingAndLeavesQuietSoundAlone() {
    let rate = 48_000
    func sine(_ amplitude: Float) -> [Float] {
      (0..<rate).flatMap { i -> [Float] in
        let v = amplitude * Float(sin(2 * Double.pi * 440 * Double(i) / Double(rate)))
        return [v, v]
      }
    }
    var loud = sine(2)
    let limiter = Limiter(channels: 2, sampleRate: rate)
    loud.withUnsafeMutableBufferPointer { limiter.process($0.baseAddress!, frames: rate) }
    XCTAssertLessThanOrEqual(loud.map(abs).max()!, Limiter.defaultCeiling + 1e-4)

    let input = sine(0.5)
    var quiet = input
    let calm = Limiter(channels: 2, sampleRate: rate)
    quiet.withUnsafeMutableBufferPointer { calm.process($0.baseAddress!, frames: rate) }
    let delay = Int(Double(rate) * Limiter.lookaheadSeconds) * 2
    for i in stride(from: delay, to: quiet.count, by: 97) {
      XCTAssertEqual(quiet[i], input[i - delay], accuracy: 1e-6)
    }
  }

  /// Music and clip sound at [volume] each over 2 s.
  private func loudDocument(volume: Double, music: Bool = true, clip: Bool = true) -> EngineDocument {
    let framing = #"{"mode": "fit", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}"#
    let json = """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"a": {"path": "\(media("vfr.mp4"))", "kind": "video"},
                 "m": {"path": "\(media("music.mp3"))", "kind": "audio"}},
       "composition": {"durationUs": 2000000, "clips": [
         {"clipId": "c", "mediaId": "a", "kind": "video", "startUs": 0, "endUs": 2000000,
          "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1, "volume": \(clip ? volume : 0),
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": \(framing)}],
        "audio": [\(music ? """
          {"id": "m1", "mediaId": "m", "startUs": 0, "endUs": 2000000, "sourceInUs": 0,
           "sourceOutUs": 2000000, "speed": 1, "loop": false, "volume": \(volume),
           "fadeInUs": 0, "fadeOutUs": 0}
          """ : "")]}}
      """
    return try! EngineDocument.decode(json)
  }

  /// The exported sound as floats, all channels interleaved.
  private func samples(_ asset: AVURLAsset) async throws -> [Float] {
    let track = try await asset.loadTracks(withMediaType: .audio).first!
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(
      track: track,
      outputSettings: [
        AVFormatIDKey: kAudioFormatLinearPCM, AVLinearPCMBitDepthKey: 32,
        AVLinearPCMIsFloatKey: true, AVLinearPCMIsNonInterleaved: false,
        AVLinearPCMIsBigEndianKey: false,
      ])
    reader.add(output)
    reader.startReading()
    var all: [Float] = []
    while let buffer = output.copyNextSampleBuffer() {
      guard let block = CMSampleBufferGetDataBuffer(buffer) else { continue }
      let length = CMBlockBufferGetDataLength(block)
      var chunk = [Float](repeating: 0, count: length / 4)
      chunk.withUnsafeMutableBytes { raw in
        _ = CMBlockBufferCopyDataBytes(
          block, atOffset: 0, dataLength: length, destination: raw.baseAddress!)
      }
      all += chunk
    }
    return all
  }

  private func rms(_ x: [Float]) -> Double {
    sqrt(x.reduce(0) { $0 + Double($1 * $1) } / Double(max(1, x.count)))
  }

  /// A 2 s, 440 Hz sine at 0.9 of full scale.
  private func loudTone() throws -> String {
    let path = tempDir.appendingPathComponent("tone.wav").path
    let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!
    let file = try AVAudioFile(forWriting: URL(fileURLWithPath: path), settings: format.settings)
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 96_000)!
    buffer.frameLength = 96_000
    for c in 0..<2 {
      for i in 0..<96_000 {
        buffer.floatChannelData![c][i] = 0.9 * Float(sin(2 * Double.pi * 440 * Double(i) / 48_000))
      }
    }
    try file.write(from: buffer)
    return path
  }

  func testCancelBeforeReadingStartsStopsTheExport() async throws {
    let out = tempDir.appendingPathComponent("early.mp4").path
    let exporter = Exporter(
      doc: sampleDocument(),
      request: ExportRequestMessage(
        outputPath: out, width: 360, height: 640, frameRate: 30, videoBitrate: 1_000_000,
        hevc: false, progressTitle: "Exporting"))
    // Before run: the composition is still to be built.
    exporter.cancel()
    do {
      _ = try await exporter.run { _ in }
      XCTFail("A cancelled export must not finish")
    } catch EngineError.cancelled {
    }
    XCTAssertFalse(FileManager.default.fileExists(atPath: out))
  }

  func testLoudMixIsLimitedNotClipped() async throws {
    // Two copies of a loud tone at 200 percent: 3.6 times full scale.
    let tone = try loudTone()
    let item = { (id: String) in
      """
      {"id": "\(id)", "mediaId": "t", "startUs": 0, "endUs": 2000000, "sourceInUs": 0,
       "sourceOutUs": 2000000, "speed": 1, "loop": false, "volume": 2, "fadeInUs": 0,
       "fadeOutUs": 0}
      """
    }
    let framing = #"{"mode": "fit", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}"#
    let json = """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"p": {"path": "\(solidPhoto("black", .black))", "kind": "photo"},
                 "t": {"path": "\(tone)", "kind": "audio"}},
       "composition": {"durationUs": 2000000, "clips": [
         {"clipId": "c", "mediaId": "p", "kind": "photo", "startUs": 0, "endUs": 2000000,
          "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1, "volume": 0,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": \(framing)}],
        "audio": [\(item("a")), \(item("b"))]}}
      """
    let x = try await samples(try await export(try EngineDocument.decode(json), name: "loud"))
    // Skip the encoder's start-up.
    let body = Array(x.dropFirst(9_600))
    let peak = body.map(abs).max() ?? 0
    let clipped = body.filter { abs($0) >= 0.99 }.count
    XCTAssertLessThan(peak, 1.0, "peak \(peak)")
    XCTAssertLessThan(Double(clipped) / Double(body.count), 0.001, "clipped samples: \(clipped)")
    XCTAssertGreaterThan(rms(body), 0.4, "still loud")
  }

  func testVolumeAboveFullIsLouder() async throws {
    let normal = try await samples(
      try await export(loudDocument(volume: 1, clip: false), name: "normal"))
    let doubled = try await samples(
      try await export(loudDocument(volume: 2, clip: false), name: "doubled"))
    XCTAssertGreaterThan(rms(doubled) / rms(normal), 1.4)
  }

  // MARK: Text

  func testOverlaysArePlacedAndAnimated() async throws {
    let blue = solidPhoto("blue", .blue)
    // A 90 x 64 red block, drawn at twice its canvas size as Dart does.
    let redPath = tempDir.appendingPathComponent("red.png").path
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let red = UIGraphicsImageRenderer(size: CGSize(width: 180, height: 128), format: format)
      .image { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 180, height: 128))
      }
    try red.pngData()!.write(to: URL(fileURLWithPath: redPath))
    let framing = #"{"mode": "fit", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}"#
    let json = """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"p": {"path": "\(blue)", "kind": "photo"}},
       "composition": {"durationUs": 2000000, "clips": [
         {"clipId": "c", "mediaId": "p", "kind": "photo", "startUs": 0, "endUs": 2000000,
          "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1, "volume": 0,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": \(framing)}]},
       "overlays": [{"id": "t", "startUs": 0, "endUs": 2000000, "images": ["\(redPath)"],
         "width": 90, "height": 64, "x": 0.5, "y": 0.25, "scale": 1, "rotationDeg": 0,
         "animationIn": {"type": "fade", "durationUs": 400000},
         "animationOut": {"type": "none", "durationUs": 0}}]}
      """
    let asset = try await export(try EngineDocument.decode(json), name: "overlay")
    let generator = AVAssetImageGenerator(asset: asset)
    generator.requestedTimeToleranceBefore = .zero
    generator.requestedTimeToleranceAfter = .zero
    func pixel(_ image: CGImage, _ x: Double, _ y: Double) -> (Double, Double) {
      let p = rgba(image)
      let i = (Int(y * Double(image.height)) * image.width + Int(x * Double(image.width))) * 4
      return (Double(p[i]) / 255, Double(p[i + 2]) / 255)
    }
    let (shown, _) = try await generator.image(at: CMTime(value: 1, timescale: 1))
    let center = pixel(shown, 0.5, 0.25)
    XCTAssertGreaterThan(center.0, 0.8, "red at the overlay's center")
    XCTAssertLessThan(center.1, 0.2)
    let outside = pixel(shown, 0.5, 0.75)
    XCTAssertGreaterThan(outside.1, 0.8, "blue away from it")
    let (fading, _) = try await generator.image(at: .zero)
    XCTAssertGreaterThan(pixel(fading, 0.5, 0.25).1, 0.8, "hidden as the fade starts")
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

  // MARK: Speech audio

  /// A second of photo, then the speech clip from 1 s.
  private func speechDocument(photoOnly: Bool = false) -> EngineDocument {
    let framing = #"{"mode": "fit", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}"#
    let speech = """
      , {"clipId": "s", "mediaId": "v", "kind": "video", "startUs": 1000000, "endUs": 4900000,
         "sourceInUs": 0, "sourceOutUs": 3900000, "speed": 1, "volume": 1,
         "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": \(framing)}
      """
    let json = """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"p": {"path": "\(media("still.jpg"))", "kind": "photo"},
                 "v": {"path": "\(media("speech.mp4"))", "kind": "video", "hasAudio": true}},
       "composition": {"durationUs": \(photoOnly ? 1000000 : 4900000), "clips": [
         {"clipId": "p", "mediaId": "p", "kind": "photo", "startUs": 0, "endUs": 1000000,
          "sourceInUs": 0, "sourceOutUs": 1000000, "speed": 1, "volume": 0,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": \(framing)}
         \(photoOnly ? "" : speech)]}}
      """
    return try! EngineDocument.decode(json)
  }

  private func floats(_ path: String) throws -> [Float] {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    return data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
  }

  func testSpeechAudioIsSixteenKilohertzMonoOnTheTimeline() async throws {
    let out = tempDir.appendingPathComponent("speech.f32").path
    var reported: [Double] = []
    let path = try await SpeechAudio(doc: speechDocument(), outputPath: out).run {
      reported.append($0)
    }
    XCTAssertEqual(path, out)
    let x = try floats(out)
    // The whole timeline, at 16 kHz.
    XCTAssertEqual(Double(x.count) / 16_000, 4.9, accuracy: 0.15)
    // Silent over the photo; speech after (it starts about 0.15 s in).
    XCTAssertLessThan(rms(Array(x[0..<15_000])), 0.001)
    XCTAssertGreaterThan(rms(Array(x[20_000..<60_000])), 0.01)
    XCTAssertEqual(reported.last, 1)
    XCTAssertFalse(FileManager.default.fileExists(atPath: out + ".part"))
  }

  func testSpeechAudioWithoutSoundIsEmpty() async throws {
    let out = tempDir.appendingPathComponent("silent.f32").path
    _ = try await SpeechAudio(doc: speechDocument(photoOnly: true), outputPath: out).run { _ in }
    XCTAssertEqual(try floats(out).count, 0)
  }

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
