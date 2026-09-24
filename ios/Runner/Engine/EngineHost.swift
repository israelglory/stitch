import Flutter
import Foundation

/// Implements the Pigeon host API: owns the preview player and running
/// exports, and reports back through [EngineFlutterApi] on the main thread.
final class EngineHost: EngineHostApi {
  private let textures: FlutterTextureRegistry
  private let callbacks: EngineFlutterApi
  private var preview: PreviewPlayer?
  private var document: EngineDocument?
  private var exports: [String: Exporter] = [:]

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

  func startExport(request: ExportRequestMessage) throws -> String {
    guard let document else {
      throw PigeonError(code: "bad_document", message: "No document to export", details: nil)
    }
    let jobId = UUID().uuidString
    let exporter = Exporter(doc: document, request: request)
    exports[jobId] = exporter
    let callbacks = self.callbacks
    Task { @MainActor [weak self] in
      var lastReported = -1.0
      do {
        let path = try await exporter.run { fraction in
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
      self?.exports[jobId] = nil
    }
    return jobId
  }

  func cancelExport(jobId: String) throws { exports[jobId]?.cancel() }
}
