import AVFoundation
import Flutter
import Photos
import UIKit
import UniformTypeIdentifiers

/// Device features for the editor: picking audio files, trying music before
/// adding it, the microphone permission, and voiceover recording. Mirrors
/// DeviceHost.kt. Used on the main thread.
final class DeviceHost: NSObject, DeviceHostApi, UIDocumentPickerDelegate,
  AVAudioPlayerDelegate, @unchecked Sendable
{
  private let callbacks: DeviceFlutterApi

  init(messenger: FlutterBinaryMessenger) {
    callbacks = DeviceFlutterApi(binaryMessenger: messenger)
    super.init()
    NotificationCenter.default.addObserver(
      self, selector: #selector(onInterruption(_:)),
      name: AVAudioSession.interruptionNotification, object: nil)
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let host = DeviceHost(messenger: registrar.messenger())
    // The message handlers keep the host alive for the engine's lifetime.
    DeviceHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: host)
  }

  // MARK: Picking files

  private var pick: CheckedContinuation<PickedFileMessage?, Never>?
  private var pickDir: String?

  /// Pigeon runs async methods off the main thread; picker state is only
  /// touched on it, so a delegate callback can never race a new pick.
  func pickAudioFile(outDir: String) async throws -> PickedFileMessage? {
    return await withCheckedContinuation { continuation in
      Task { @MainActor in
        // An earlier pick still open ends with nothing.
        self.pick?.resume(returning: nil)
        self.pick = nil
        guard let presenter = Self.topViewController() else {
          continuation.resume(returning: nil)
          return
        }
        self.pick = continuation
        self.pickDir = outDir
        let picker = UIDocumentPickerViewController(
          forOpeningContentTypes: [.audio], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        presenter.present(picker, animated: true)
      }
    }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
  {
    let result = urls.first.flatMap { url in pickDir.flatMap { try? Self.move(url, into: $0) } }
    pick?.resume(returning: result)
    pick = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pick?.resume(returning: nil)
    pick = nil
  }

  /// Moves the picker's copy into [dir] under a unique name.
  private static func move(_ url: URL, into dir: String) throws -> PickedFileMessage {
    try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    let ext = url.pathExtension.isEmpty ? "m4a" : url.pathExtension.lowercased()
    let out = URL(fileURLWithPath: dir).appendingPathComponent("\(UUID().uuidString).\(ext)")
    try FileManager.default.moveItem(at: url, to: out)
    return PickedFileMessage(path: out.path, name: url.deletingPathExtension().lastPathComponent)
  }

  private static func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }

  // MARK: Trying music

  private var previewPlayer: AVAudioPlayer?
  private var previewPath = ""
  private var previewTimer: Timer?

  func startAudioPreview(path: String) throws {
    stopPreviewPlayer()
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
      let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
      player.delegate = self
      player.play()
      previewPlayer = player
      previewPath = path
      previewTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
        self?.publishPreview()
      }
      publishPreview()
    } catch {
      throw PigeonError(code: "unsupported_media", message: "\(error)", details: nil)
    }
  }

  func stopAudioPreview() throws {
    stopPreviewPlayer()
    publishPreview()
  }

  private func stopPreviewPlayer() {
    previewTimer?.invalidate()
    previewTimer = nil
    previewPlayer?.stop()
    previewPlayer = nil
  }

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    previewTimer?.invalidate()
    previewTimer = nil
    publishPreview()
  }

  private func publishPreview() {
    let state = AudioPreviewStateMessage(
      path: previewPath,
      positionUs: Int64((previewPlayer?.currentTime ?? 0) * 1_000_000),
      durationUs: Int64((previewPlayer?.duration ?? 0) * 1_000_000),
      isPlaying: previewPlayer?.isPlaying ?? false)
    Task { @MainActor in try? await callbacks.onAudioPreviewState(state: state) }
  }

  // MARK: The microphone

  func microphonePermission() throws -> MicrophonePermission { Self.permission() }

  private static func permission() -> MicrophonePermission {
    if #available(iOS 17, *) {
      switch AVAudioApplication.shared.recordPermission {
      case .granted: return .granted
      case .undetermined: return .undetermined
      default: return .permanentlyDenied
      }
    }
    switch AVAudioSession.sharedInstance().recordPermission {
    case .granted: return .granted
    case .undetermined: return .undetermined
    // iOS asks once; after a refusal only Settings can grant it.
    default: return .permanentlyDenied
    }
  }

  func requestMicrophone() async throws -> MicrophonePermission {
    guard Self.permission() == .undetermined else { return Self.permission() }
    if #available(iOS 17, *) {
      _ = await AVAudioApplication.requestRecordPermission()
    } else {
      await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
        AVAudioSession.sharedInstance().requestRecordPermission { _ in done.resume() }
      }
    }
    return Self.permission()
  }

  func openAppSettings() throws {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    Task { @MainActor in UIApplication.shared.open(url) }
  }

  // MARK: Storage, saving, and sharing

  func freeSpace(path: String) throws -> Int64 {
    // The nearest folder that exists: the one asked about may not yet.
    var url = URL(fileURLWithPath: path)
    while !FileManager.default.fileExists(atPath: url.path), url.pathComponents.count > 1 {
      url.deleteLastPathComponent()
    }
    let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
    if let bytes = values?.volumeAvailableCapacityForImportantUsage { return bytes }
    let attributes = try FileManager.default.attributesOfFileSystem(forPath: url.path)
    return (attributes[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
  }

  func saveVideoToGallery(path: String) async throws -> GallerySaveResult {
    var status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    if status == .notDetermined {
      status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }
    switch status {
    case .authorized, .limited:
      break
    case .notDetermined:
      return .denied
    default:
      return .permanentlyDenied
    }
    do {
      try await PHPhotoLibrary.shared().performChanges {
        PHAssetCreationRequest.creationRequestForAssetFromVideo(
          atFileURL: URL(fileURLWithPath: path))
      }
      return .saved
    } catch {
      throw PigeonError(code: "save_failed", message: "\(error)", details: nil)
    }
  }

  func shareFile(path: String, mimeType: String) throws {
    let url = URL(fileURLWithPath: path)
    Task { @MainActor in
      guard let top = Self.topViewController() else { return }
      let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
      sheet.popoverPresentationController?.sourceView = top.view
      top.present(sheet, animated: true)
    }
  }

  func openUrl(url: String) throws {
    guard let link = URL(string: url) else { return }
    Task { @MainActor in UIApplication.shared.open(link) }
  }

  func setKeepScreenOn(on: Bool) throws {
    Task { @MainActor in UIApplication.shared.isIdleTimerDisabled = on }
  }

  func appVersion() throws -> String {
    let info = Bundle.main.infoDictionary
    let version = info?["CFBundleShortVersionString"] as? String ?? "?"
    let build = info?["CFBundleVersion"] as? String ?? "?"
    return "\(version) (\(build))"
  }

  func requestNotifications() async throws -> Bool { true }

  // MARK: Recording

  private var recorder: AVAudioRecorder?
  private var levelTimer: Timer?

  func startRecording(outPath: String) throws {
    try cancelRecording()
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(
        .playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
      try session.setActive(true)
      try FileManager.default.createDirectory(
        at: URL(fileURLWithPath: outPath).deletingLastPathComponent(),
        withIntermediateDirectories: true)
      let recorder = try AVAudioRecorder(
        url: URL(fileURLWithPath: outPath),
        settings: [
          AVFormatIDKey: kAudioFormatMPEG4AAC,
          AVSampleRateKey: 48_000,
          AVNumberOfChannelsKey: 1,
          AVEncoderBitRateKey: 128_000,
        ])
      recorder.isMeteringEnabled = true
      guard recorder.record() else {
        throw PigeonError(code: "recording_failed", message: "Could not start", details: nil)
      }
      self.recorder = recorder
      levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
        guard let self, let recorder = self.recorder else { return }
        recorder.updateMeters()
        // Decibels to a 0-to-1 level.
        let level = pow(10, Double(recorder.averagePower(forChannel: 0)) / 20)
        Task { @MainActor in try? await self.callbacks.onRecordingLevel(level: min(max(level, 0), 1)) }
      }
    } catch let error as PigeonError {
      throw error
    } catch {
      throw PigeonError(code: "recording_failed", message: "\(error)", details: nil)
    }
  }

  func stopRecording() async throws -> RecordingMessage {
    // The level timer and recorder belong to the main thread.
    let finished = await MainActor.run { self.finish(keep: true) }
    guard let (path, _) = finished else {
      throw PigeonError(code: "recording_failed", message: "Nothing was recorded", details: nil)
    }
    // The file knows its exact length.
    let asset = AVURLAsset(url: URL(fileURLWithPath: path))
    let duration = (try? await asset.load(.duration))?.microseconds ?? 0
    return RecordingMessage(path: path, durationUs: duration)
  }

  func cancelRecording() throws {
    _ = finish(keep: false)
  }

  /// Stops the recorder; returns the file (when kept) and its length.
  private func finish(keep: Bool) -> (String, Int64)? {
    levelTimer?.invalidate()
    levelTimer = nil
    guard let recorder else { return nil }
    self.recorder = nil
    let duration = Int64(recorder.currentTime * 1_000_000)
    recorder.stop()
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
    let path = recorder.url.path
    guard keep, duration > 0 else {
      recorder.deleteRecording()
      return nil
    }
    return (path, duration)
  }

  /// A call or another app took audio: stop, keeping what was recorded.
  @objc private func onInterruption(_ note: Notification) {
    let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
      .flatMap(AVAudioSession.InterruptionType.init)
    guard type == .began else { return }
    Task { @MainActor in
      if self.previewPlayer?.isPlaying == true {
        self.previewPlayer?.pause()
        self.publishPreview()
      }
      guard self.recorder != nil else { return }
      let kept = self.finish(keep: true)
      try? await self.callbacks.onRecordingInterrupted(
        path: kept?.0, durationUs: kept?.1 ?? 0)
    }
  }
}
