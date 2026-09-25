import Flutter
import UIKit
import Foundation

/// Implements the Pigeon host API: owns the preview player and running
/// exports, and reports back through [EngineFlutterApi] on the main thread.
final class EngineHost: EngineHostApi {
  private let textures: FlutterTextureRegistry
  private let callbacks: EngineFlutterApi
  private var preview: PreviewPlayer?
  private var document: EngineDocument?
  private var jobs: [String: EngineJob] = [:]

  init(messenger: FlutterBinaryMessenger, textures: FlutterTextureRegistry) {
    self.textures = textures
    callbacks = EngineFlutterApi(binaryMessenger: messenger)
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let host = EngineHost(messenger: registrar.messenger(), textures: registrar.textures())
    // The message handlers keep the host alive for the engine's lifetime.
    EngineHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: host)
  }

  private func player() -> PreviewPlayer {
    if let preview { return preview }
    let p = PreviewPlayer(textures: textures) { [weak self] state in
      Task { @MainActor in try? await self?.callbacks.onPlaybackState(state: state) }
    }
    preview = p
    return p
  }

  func createPreview() throws -> Int64 { player().textureId }

  func setDocument(json: String) throws {
    do {
      let doc = try EngineDocument.decode(json)
      document = doc
      player().setDocument(doc)
    } catch {
      throw PigeonError(code: "bad_document", message: "\(error)", details: nil)
    }
  }

  func play() throws { player().play() }

  func pause() throws { player().pause() }

  func seek(positionUs: Int64, exact: Bool) throws {
    player().seek(us: positionUs, exact: exact)
  }

  func release() throws { preview?.release() }

  func probe(path: String) async throws -> MediaInfoMessage {
    do { return try await MediaProbe.probe(path: path) } catch let e as EngineError {
      throw PigeonError(code: e.code, message: e.message, details: nil)
    }
  }

  func thumbnails(path: String, timesUs: [Int64], maxSize: Int64, outDir: String) async throws
    -> [String?]
  {
    await Thumbnailer.thumbnails(
      path: path, timesUs: timesUs, maxSize: Int(maxSize), outDir: outDir)
  }

  func createProxy(path: String, outPath: String) async throws {
    do { try await ProxyMaker.createProxy(path: path, outPath: outPath) } catch let e as EngineError
    {
      throw PigeonError(code: e.code, message: e.message, details: nil)
    }
  }

  func capabilities() throws -> CapabilitiesMessage { Exporter.capabilities() }

  func waveform(path: String, peaksPerSecond: Int64) async throws -> [Double] {
    do { return try await Waveform.peaks(path: path, peaksPerSecond: Int(peaksPerSecond)) } catch
      let e as EngineError
    {
      throw PigeonError(code: e.code, message: e.message, details: nil)
    }
  }

  func setPreviewVolume(volume: Double) throws { preview?.setVolume(volume) }

  func startExport(request: ExportRequestMessage) throws -> String {
    guard let document else {
      throw PigeonError(code: "bad_document", message: "No document to export", details: nil)
    }
    return start(Exporter(doc: document, request: request))
  }

  func startSpeechAudio(documentJson: String, outputPath: String) throws -> String {
    let doc: EngineDocument
    do {
      doc = try EngineDocument.decode(documentJson)
    } catch {
      throw PigeonError(code: "bad_document", message: "\(error)", details: nil)
    }
    return start(SpeechAudio(doc: doc, outputPath: outputPath))
  }

  /// Runs [job], reporting through the export callbacks under a new id.
  /// An export asks for time to finish in the background; when that runs
  /// out, it stops as interrupted.
  private func start(_ job: EngineJob) -> String {
    let jobId = UUID().uuidString
    jobs[jobId] = job
    let callbacks = self.callbacks
    let background = BackgroundTime()
    if let exporter = job as? Exporter {
      background.begin { exporter.interrupt() }
    }
    Task { @MainActor [weak self] in
      defer { background.end() }
      var lastReported = -1.0
      do {
        let path = try await job.run { fraction in
          // Report at most every 1 percent.
          guard fraction - lastReported >= 0.01 || fraction >= 1 else { return }
          lastReported = fraction
          Task { @MainActor in
            try? await callbacks.onExportProgress(jobId: jobId, fraction: fraction)
          }
        }
        try? await callbacks.onExportCompleted(jobId: jobId, outputPath: path)
      } catch let e as EngineError {
        try? await callbacks.onExportFailed(jobId: jobId, code: e.code, message: e.message)
      } catch {
        try? await callbacks.onExportFailed(
          jobId: jobId, code: "export_failed", message: "\(error)")
      }
      self?.jobs[jobId] = nil
    }
    return jobId
  }

  func cancelExport(jobId: String) throws { jobs[jobId]?.cancel() }
}

/// Time to keep working in the background. When the system is about to
/// take it away, [onExpire] runs and the time is handed back at once, as
/// iOS requires. Both calls are safe from any thread.
private final class BackgroundTime {
  private var id = UIBackgroundTaskIdentifier.invalid

  func begin(onExpire: @escaping () -> Void) {
    id = UIApplication.shared.beginBackgroundTask(withName: "Export") { [weak self] in
      onExpire()
      self?.end()
    }
  }

  func end() {
    guard id != .invalid else { return }
    UIApplication.shared.endBackgroundTask(id)
    id = .invalid
  }
}
