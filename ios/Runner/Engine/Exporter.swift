import AVFoundation
import UIKit
import VideoToolbox

/// Renders a document to an MP4 with AVAssetReader and AVAssetWriter,
/// which (unlike AVAssetExportSession) lets us set the bitrate, frame rate,
/// and codec exactly.
final class Exporter {
  typealias Progress = (Double) -> Void

  private let doc: EngineDocument
  private let request: ExportRequestMessage
  private let queue = DispatchQueue(label: "stitch.export", qos: .userInitiated)
  /// Guards the fields below: cancel arrives on the main thread while the
  /// export runs on [queue].
  private let lock = NSLock()
  private var reader: AVAssetReader?
  private var cancelled = false
  private var interrupted = false
  private var backgrounded = false

  init(doc: EngineDocument, request: ExportRequestMessage) {
    self.doc = doc
    self.request = request
  }

  /// Stops the export; [run] discards the output and throws
  /// [EngineError.cancelled]. Works before reading has started too.
  func cancel() {
    let reader = lock.withLock { () -> AVAssetReader? in
      cancelled = true
      return self.reader
    }
    reader?.cancelReading()
  }

  /// Stops like [cancel], but [run] reports [EngineError.interrupted]: the
  /// app ran out of background time.
  func interrupt() {
    lock.withLock { interrupted = true }
    cancel()
  }

  private var stopped: Bool { lock.withLock { cancelled } }

  /// How the export stopped early, when it did.
  private func stopReason() -> EngineError {
    lock.withLock { interrupted } ? .interrupted : .cancelled
  }

  /// [error] as reported to Dart. Work refused because the app went to
  /// the background is "interrupted", which the app offers to retry.
  private func failure(_ error: Error?, _ fallback: String) -> EngineError {
    let code = (error as NSError?)?.code
    if code == AVError.Code.operationInterrupted.rawValue || lock.withLock({ backgrounded }) {
      return .interrupted
    }
    return .exportFailed(error?.localizedDescription ?? fallback)
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
    // Cancelled while the composition was built: stop before any work.
    let early = lock.withLock { () -> Bool in
      self.reader = reader
      return cancelled
    }
    if early { throw stopReason() }

    let background = NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil
    ) { [weak self] _ in self?.lock.withLock { self?.backgrounded = true } }
    defer { NotificationCenter.default.removeObserver(background) }

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

    // Audio: everything mixed down, resampled to 48 kHz stereo. Mixed in
    // float so loud moments reach the limiter instead of clipping.
    let audioTracks = built.composition.tracks(withMediaType: .audio)
    var audioPair: (AVAssetReaderOutput, AVAssetWriterInput)?
    if !audioTracks.isEmpty {
      let out = AVAssetReaderAudioMixOutput(
        audioTracks: audioTracks,
        audioSettings: [
          AVFormatIDKey: kAudioFormatLinearPCM,
          AVSampleRateKey: 48_000,
          AVNumberOfChannelsKey: 2,
          AVLinearPCMBitDepthKey: 32,
          AVLinearPCMIsFloatKey: true,
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
      throw failure(reader.error, "Reader failed")
    }
    guard writer.startWriting() else {
      throw failure(writer.error, "Writer failed")
    }
    writer.startSession(atSourceTime: .zero)

    let durationSeconds = duration.seconds
    var pipes: [Pipe] = []
    if let (out, input) = videoPair {
      pipes.append(
        Pipe(
          output: out, input: input,
          onSample: { time in progress(min(1, time.seconds / durationSeconds)) }))
    }
    if let (out, input) = audioPair {
      let audio = LimitedAudio(limiter: Limiter(channels: 2, sampleRate: 48_000))
      pipes.append(
        Pipe(
          output: out, input: input, transform: audio.transform, flush: audio.flush))
    }
    await drive(pipes, writer: writer)

    if stopped || reader.status == .cancelled {
      writer.cancelWriting()
      try? FileManager.default.removeItem(at: temp)
      throw stopReason()
    }
    if reader.status == .failed || writer.status == .failed {
      let error = reader.status == .failed ? reader.error : writer.error
      if writer.status == .writing { writer.cancelWriting() }
      try? FileManager.default.removeItem(at: temp)
      throw failure(error, "Export failed")
    }
    await writer.finishWriting()
    guard writer.status == .completed else {
      try? FileManager.default.removeItem(at: temp)
      throw failure(writer.error, "Writing failed")
    }
    try? FileManager.default.removeItem(at: output)
    try FileManager.default.moveItem(at: temp, to: output)
    progress(1)
    return output.path
  }

  /// A reader output feeding a writer input, used only on the export queue.
  private final class Pipe: @unchecked Sendable {
    let output: AVAssetReaderOutput
    let input: AVAssetWriterInput
    let onSample: ((CMTime) -> Void)?
    let transform: ((CMSampleBuffer) -> CMSampleBuffer?)?
    /// What is left once the reader runs dry (the limiter's tail).
    let flush: (() -> CMSampleBuffer?)?
    var pending: CMSampleBuffer?
    var draining = false
    var done = false

    init(
      output: AVAssetReaderOutput, input: AVAssetWriterInput,
      onSample: ((CMTime) -> Void)? = nil,
      transform: ((CMSampleBuffer) -> CMSampleBuffer?)? = nil,
      flush: (() -> CMSampleBuffer?)? = nil
    ) {
      self.output = output
      self.input = input
      self.onSample = onSample
      self.transform = transform
      self.flush = flush
    }
  }

  /// Feeds every input whose writer is ready, in one loop on the export
  /// queue, until each has had all its samples. It ends early on cancel or
  /// when the writer fails, so it never waits on a writer that stopped
  /// asking for data.
  private func drive(_ pipes: [Pipe], writer: AVAssetWriter) async {
    await withCheckedContinuation { (finished: CheckedContinuation<Void, Never>) in
      queue.async { [self] in
        while pipes.contains(where: { !$0.done }) {
          if stopped || writer.status != .writing { break }
          var fed = false
          for pipe in pipes where !pipe.done && pipe.input.isReadyForMoreMediaData {
            fed = true
            if let sample = pipe.pending {
              pipe.pending = nil
              if !pipe.input.append(sample) { break }
              continue
            }
            if pipe.draining {
              pipe.input.markAsFinished()
              pipe.done = true
              continue
            }
            guard let sample = pipe.output.copyNextSampleBuffer() else {
              pipe.draining = true
              pipe.pending = pipe.flush?()
              continue
            }
            pipe.onSample?(CMSampleBufferGetPresentationTimeStamp(sample))
            guard let ready = pipe.transform.map({ $0(sample) }) ?? sample else { continue }
            if !pipe.input.append(ready) { break }
          }
          // Nothing was ready: the encoders are busy.
          if !fed { usleep(2_000) }
        }
        finished.resume()
      }
    }
  }

  /// Export sound through the limiter, on time: the limiter's output is
  /// [Limiter.lookahead] frames late, so every buffer moves that much
  /// earlier, the first loses its silent start, and the tail still in the
  /// limiter is let out at the end.
  private final class LimitedAudio: @unchecked Sendable {
    let limiter: Limiter
    private var toDrop: Int
    private var lastFormat: CMFormatDescription?
    private var endTime = CMTime.zero

    init(limiter: Limiter) {
      self.limiter = limiter
      toDrop = limiter.lookahead
    }

    private var shift: CMTime { CMTime(value: CMTimeValue(limiter.lookahead), timescale: 48_000) }

    func transform(_ sample: CMSampleBuffer) -> CMSampleBuffer? {
      let frames = CMSampleBufferGetNumSamples(sample)
      let pts = CMSampleBufferGetPresentationTimeStamp(sample)
      endTime = pts + CMTime(value: CMTimeValue(frames), timescale: 48_000)
      lastFormat = CMSampleBufferGetFormatDescription(sample)
      guard var data = Exporter.pcm(sample) else { return sample }
      data.withUnsafeMutableBufferPointer { limiter.process($0.baseAddress!, frames: frames) }
      let drop = min(toDrop, frames)
      toDrop -= drop
      if drop == frames { return nil }
      let kept = Array(data[(drop * 2)...])
      let time = drop > 0 ? CMTime.zero : pts - shift
      return Exporter.audioBuffer(kept, format: lastFormat, at: time)
    }

    func flush() -> CMSampleBuffer? {
      guard lastFormat != nil else { return nil }
      var tail = [Float](repeating: 0, count: limiter.lookahead * 2)
      tail.withUnsafeMutableBufferPointer {
        limiter.process($0.baseAddress!, frames: limiter.lookahead)
      }
      return Exporter.audioBuffer(tail, format: lastFormat, at: endTime - shift)
    }
  }

  /// The interleaved float samples of [sample], copied.
  static func pcm(_ sample: CMSampleBuffer) -> [Float]? {
    let frames = CMSampleBufferGetNumSamples(sample)
    guard frames > 0, let block = CMSampleBufferGetDataBuffer(sample) else { return nil }
    let length = CMBlockBufferGetDataLength(block)
    guard length >= frames * 2 * MemoryLayout<Float>.size else { return nil }
    var data = [Float](repeating: 0, count: length / MemoryLayout<Float>.size)
    let status = data.withUnsafeMutableBytes {
      CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length, destination: $0.baseAddress!)
    }
    return status == noErr ? data : nil
  }

  /// Interleaved stereo float [samples] as a sample buffer at [time].
  static func audioBuffer(
    _ samples: [Float], format: CMFormatDescription?, at time: CMTime
  ) -> CMSampleBuffer? {
    guard let format, !samples.isEmpty else { return nil }
    let bytes = samples.count * MemoryLayout<Float>.size
    var block: CMBlockBuffer?
    guard
      CMBlockBufferCreateWithMemoryBlock(
        allocator: nil, memoryBlock: nil, blockLength: bytes, blockAllocator: nil,
        customBlockSource: nil, offsetToData: 0, dataLength: bytes, flags: 0,
        blockBufferOut: &block) == noErr, let block
    else { return nil }
    let copied = samples.withUnsafeBytes {
      CMBlockBufferReplaceDataBytes(
        with: $0.baseAddress!, blockBuffer: block, offsetIntoDestination: 0, dataLength: bytes)
    }
    guard copied == noErr else { return nil }
    var out: CMSampleBuffer?
    CMAudioSampleBufferCreateReadyWithPacketDescriptions(
      allocator: nil, dataBuffer: block, formatDescription: format,
      sampleCount: samples.count / 2, presentationTimeStamp: time,
      packetDescriptions: nil, sampleBufferOut: &out)
    return out
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
