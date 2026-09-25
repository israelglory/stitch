import AVFoundation

/// A long engine task: an export, or speech audio.
protocol EngineJob: AnyObject {
  /// Runs and returns the output path. Throws [EngineError.cancelled]
  /// after [cancel].
  func run(progress: @escaping (Double) -> Void) async throws -> String
  func cancel()
}

extension Exporter: EngineJob {}

/// Renders a document's mixed sound for speech recognition: 16 kHz mono
/// float PCM, raw and little endian. Mirrors SpeechAudio.kt.
///
/// The composition's audio mix is read and converted by AVAssetReader; no
/// video is decoded. Samples are placed by their time, so the file lines
/// up with the timeline even across silent gaps. A document with no sound
/// gives an empty file.
final class SpeechAudio: EngineJob {
  static let sampleRate = 16_000

  private let doc: EngineDocument
  private let outputPath: String
  private let queue = DispatchQueue(label: "stitch.speech", qos: .userInitiated)
  private let lock = NSLock()
  private var cancelled = false
  private var reader: AVAssetReader?

  init(doc: EngineDocument, outputPath: String) {
    self.doc = doc
    self.outputPath = outputPath
  }

  func cancel() {
    lock.withLock {
      cancelled = true
      reader?.cancelReading()
    }
  }

  private var isCancelled: Bool { lock.withLock { cancelled } }

  func run(progress: @escaping (Double) -> Void) async throws -> String {
    let output = URL(fileURLWithPath: outputPath)
    let temp = output.appendingPathExtension("part")
    try? FileManager.default.removeItem(at: temp)
    guard FileManager.default.createFile(atPath: temp.path, contents: nil) else {
      throw EngineError.exportFailed("Could not write output")
    }

    let built: BuiltComposition?
    do {
      built = try await CompositionBuilder.build(doc, forExport: true)
    } catch EngineError.badDocument(_) {
      built = nil  // nothing that makes a sound
    }
    let tracks = built?.composition.tracks(withMediaType: .audio) ?? []
    if let built, !tracks.isEmpty {
      let reader = try AVAssetReader(asset: built.composition)
      let out = AVAssetReaderAudioMixOutput(
        audioTracks: tracks,
        audioSettings: [
          AVFormatIDKey: kAudioFormatLinearPCM,
          AVSampleRateKey: Self.sampleRate,
          AVNumberOfChannelsKey: 1,
          AVLinearPCMBitDepthKey: 32,
          AVLinearPCMIsFloatKey: true,
          AVLinearPCMIsBigEndianKey: false,
          AVLinearPCMIsNonInterleaved: false,
        ])
      out.audioMix = built.audioMix
      out.audioTimePitchAlgorithm = .spectral
      reader.add(out)
      let started = lock.withLock { () -> Bool in
        self.reader = reader
        return !cancelled && reader.startReading()
      }
      if !started {
        try? FileManager.default.removeItem(at: temp)
        if isCancelled { throw EngineError.cancelled }
        throw EngineError.exportFailed(reader.error?.localizedDescription ?? "Reader failed")
      }
      do {
        try await copy(from: out, to: temp, duration: built.duration.seconds, progress: progress)
      } catch {
        try? FileManager.default.removeItem(at: temp)
        throw error
      }
      if isCancelled || reader.status == .cancelled {
        try? FileManager.default.removeItem(at: temp)
        throw EngineError.cancelled
      }
      if reader.status == .failed {
        try? FileManager.default.removeItem(at: temp)
        throw EngineError.exportFailed(reader.error?.localizedDescription ?? "Reading failed")
      }
    }
    try? FileManager.default.removeItem(at: output)
    try FileManager.default.moveItem(at: temp, to: output)
    progress(1)
    return output.path
  }

  /// Writes every sample from [out] to [file] on the job's queue.
  private func copy(
    from out: AVAssetReaderOutput, to file: URL, duration: Double,
    progress: @escaping (Double) -> Void
  ) async throws {
    let handle = try FileHandle(forWritingTo: file)
    defer { try? handle.close() }
    let rate = Double(Self.sampleRate)
    let frameBytes = MemoryLayout<Float>.size
    try await withCheckedThrowingContinuation { (done: CheckedContinuation<Void, Error>) in
      queue.async {
        do {
          var written = 0  // frames
          while let sample = out.copyNextSampleBuffer() {
            let frames = CMSampleBufferGetNumSamples(sample)
            guard frames > 0, let block = CMSampleBufferGetDataBuffer(sample) else { continue }
            let time = CMSampleBufferGetPresentationTimeStamp(sample).seconds
            // Silence up to this sample's time, if the mix skipped ahead.
            let at = Int((time * rate).rounded())
            if at > written {
              try handle.write(contentsOf: Data(count: (at - written) * frameBytes))
              written = at
            }
            let length = CMBlockBufferGetDataLength(block)
            var data = Data(count: length)
            let status = data.withUnsafeMutableBytes { bytes in
              CMBlockBufferCopyDataBytes(
                block, atOffset: 0, dataLength: length, destination: bytes.baseAddress!)
            }
            guard status == noErr else { continue }
            try handle.write(contentsOf: data)
            written += length / frameBytes
            if duration > 0 { progress(min(1, time / duration)) }
          }
          done.resume()
        } catch {
          done.resume(throwing: EngineError.exportFailed("\(error)"))
        }
      }
    }
  }
}
