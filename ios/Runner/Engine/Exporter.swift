import AVFoundation
import VideoToolbox

/// Renders a document to an MP4 with AVAssetReader and AVAssetWriter,
/// which (unlike AVAssetExportSession) lets us set the bitrate, frame rate,
/// and codec exactly.
final class Exporter {
  typealias Progress = (Double) -> Void

  private let doc: EngineDocument
  private let request: ExportRequestMessage
  private let queue = DispatchQueue(label: "stitch.export", qos: .userInitiated)
  private var reader: AVAssetReader?
  private var writer: AVAssetWriter?
  private var cancelled = false

  init(doc: EngineDocument, request: ExportRequestMessage) {
    self.doc = doc
    self.request = request
  }

  /// Stops reading; the pumps then drain and [run] discards the output.
  /// The writer is not cancelled here: a cancelled writer stops asking for
  /// data, which would leave the pumps waiting forever.
  func cancel() {
    queue.async { [self] in
      cancelled = true
      reader?.cancelReading()
    }
  }

  /// Exports and returns the output path. Throws [EngineError.cancelled]
  /// after [cancel].
  func run(progress: @escaping Progress) async throws -> String {
    let size = CGSize(width: Int(request.width), height: Int(request.height))
    let built = try await CompositionBuilder.build(doc, forExport: true, renderSize: size)
    let duration = built.duration
    guard duration > .zero else { throw EngineError.exportFailed("Nothing to export") }

    let output = URL(fileURLWithPath: request.outputPath)
    let temp = output.deletingPathExtension().appendingPathExtension("part.mp4")
    try? FileManager.default.removeItem(at: temp)

    let reader = try AVAssetReader(asset: built.composition)
    let writer = try AVAssetWriter(outputURL: temp, fileType: .mp4)
    writer.shouldOptimizeForNetworkUse = true
    self.reader = reader
    self.writer = writer

    // Video: rendered through the compositor at the export size.
    let videoTracks = built.composition.tracks(withMediaType: .video)
    var videoPair: (AVAssetReaderOutput, AVAssetWriterInput)?
    if !videoTracks.isEmpty, let videoComposition = built.videoComposition {
      videoComposition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(request.frameRate))
      let out = AVAssetReaderVideoCompositionOutput(
        videoTracks: videoTracks,
        videoSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
      out.videoComposition = videoComposition
      out.alwaysCopiesSampleData = false
      let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings())
      input.expectsMediaDataInRealTime = false
      reader.add(out)
      writer.add(input)
      videoPair = (out, input)
    }

    // Audio: everything mixed down, resampled to 48 kHz stereo.
    let audioTracks = built.composition.tracks(withMediaType: .audio)
    var audioPair: (AVAssetReaderOutput, AVAssetWriterInput)?
    if !audioTracks.isEmpty {
      let out = AVAssetReaderAudioMixOutput(
        audioTracks: audioTracks,
        audioSettings: [
          AVFormatIDKey: kAudioFormatLinearPCM,
          AVSampleRateKey: 48_000,
          AVNumberOfChannelsKey: 2,
          AVLinearPCMBitDepthKey: 16,
          AVLinearPCMIsFloatKey: false,
          AVLinearPCMIsBigEndianKey: false,
          AVLinearPCMIsNonInterleaved: false,
        ])
      out.audioMix = built.audioMix
      out.audioTimePitchAlgorithm = .spectral
      let input = AVAssetWriterInput(
        mediaType: .audio,
        outputSettings: [
          AVFormatIDKey: kAudioFormatMPEG4AAC,
          AVSampleRateKey: 48_000,
          AVNumberOfChannelsKey: 2,
          AVEncoderBitRateKey: 192_000,
        ])
      input.expectsMediaDataInRealTime = false
      reader.add(out)
      writer.add(input)
      audioPair = (out, input)
    }

    guard reader.startReading() else {
      throw EngineError.exportFailed(reader.error?.localizedDescription ?? "Reader failed")
    }
    guard writer.startWriting() else {
      throw EngineError.exportFailed(writer.error?.localizedDescription ?? "Writer failed")
    }
    writer.startSession(atSourceTime: .zero)

    let durationSeconds = duration.seconds
    await withTaskGroup(of: Void.self) { group in
      for (isVideo, pair) in [(true, videoPair), (false, audioPair)] {
        guard let (out, input) = pair else { continue }
        group.addTask { [queue] in
          await Self.pump(
            output: out, input: input, queue: queue,
            onSample: isVideo
              ? { time in progress(min(1, time.seconds / durationSeconds)) } : nil)
        }
      }
    }

    if cancelled || reader.status == .cancelled {
      writer.cancelWriting()
      try? FileManager.default.removeItem(at: temp)
      throw EngineError.cancelled
    }
    if reader.status == .failed {
      writer.cancelWriting()
      try? FileManager.default.removeItem(at: temp)
      throw EngineError.exportFailed(reader.error?.localizedDescription ?? "Reading failed")
    }
    await writer.finishWriting()
    guard writer.status == .completed else {
      try? FileManager.default.removeItem(at: temp)
      throw EngineError.exportFailed(writer.error?.localizedDescription ?? "Writing failed")
    }
    try? FileManager.default.removeItem(at: output)
    try FileManager.default.moveItem(at: temp, to: output)
    progress(1)
    return output.path
  }

  /// A reader output and writer input used only on the export queue.
  private struct Pipe: @unchecked Sendable {
    let output: AVAssetReaderOutput
    let input: AVAssetWriterInput
  }

  /// Copies samples until the reader runs dry, then marks the input done.
  private static func pump(
    output: AVAssetReaderOutput, input: AVAssetWriterInput, queue: DispatchQueue,
    onSample: ((CMTime) -> Void)?
  ) async {
    let pipe = Pipe(output: output, input: input)
    await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
      var finished = false
      pipe.input.requestMediaDataWhenReady(on: queue) {
        while pipe.input.isReadyForMoreMediaData, !finished {
          guard let sample = pipe.output.copyNextSampleBuffer() else {
            finished = true
            pipe.input.markAsFinished()
            done.resume()
            return
          }
          onSample?(CMSampleBufferGetPresentationTimeStamp(sample))
          if !pipe.input.append(sample) {
            finished = true
            pipe.input.markAsFinished()
            done.resume()
            return
          }
        }
      }
    }
  }

  private func videoSettings() -> [String: Any] {
    let fps = Int(request.frameRate)
    var compression: [String: Any] = [
      AVVideoAverageBitRateKey: Int(request.videoBitrate),
      AVVideoExpectedSourceFrameRateKey: fps,
      AVVideoMaxKeyFrameIntervalKey: fps * 2,
    ]
    if !request.hevc {
      compression[AVVideoProfileLevelKey] = AVVideoProfileLevelH264HighAutoLevel
    }
    return [
      AVVideoCodecKey: request.hevc ? AVVideoCodecType.hevc : AVVideoCodecType.h264,
      AVVideoWidthKey: Int(request.width),
      AVVideoHeightKey: Int(request.height),
      AVVideoCompressionPropertiesKey: compression,
      AVVideoColorPropertiesKey: [
        AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
        AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
        AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
      ],
    ]
  }

  /// What this device can encode.
  static func capabilities() -> CapabilitiesMessage {
    CapabilitiesMessage(
      hevc: AVOutputSettingsAssistant(preset: .hevc1920x1080) != nil
        && VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC),
      max4k: AVOutputSettingsAssistant(preset: .preset3840x2160) != nil)
  }
}
