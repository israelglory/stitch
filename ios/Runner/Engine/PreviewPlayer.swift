import AVFoundation
import Flutter
import QuartzCore

/// Plays the document into a Flutter texture.
///
/// Frames come from an AVPlayerItemVideoOutput polled on every display
/// refresh. Seeks coalesce: while one is in flight only the latest target
/// is kept, so dragging the timeline never queues stale seeks.
///
/// Used from the main thread only; frames cross threads under `frameLock`.
final class PreviewPlayer: NSObject, FlutterTexture, @unchecked Sendable {
  private let textures: FlutterTextureRegistry
  private let onState: (PlaybackStateMessage) -> Void
  private(set) var textureId: Int64 = 0

  private let player = AVPlayer()
  private var output: AVPlayerItemVideoOutput?
  private var displayLink: CADisplayLink?
  private var latestFrame: CVPixelBuffer?
  private let frameLock = NSLock()
  private var timeObserver: Any?
  private var endObserver: NSObjectProtocol?
  private var interruptionObserver: NSObjectProtocol?
  private var routeObserver: NSObjectProtocol?
  private var buildTask: Task<Void, Never>?
  private var durationUs: Int64 = 0
  /// Version of the document on screen (see `EngineDocument.version`).
  private var shownVersion: Int64 = 0

  private var seeking = false
  private var pendingSeek: (us: Int64, exact: Bool)?
  private var wantsPlay = false

  init(textures: FlutterTextureRegistry, onState: @escaping (PlaybackStateMessage) -> Void) {
    self.textures = textures
    self.onState = onState
    super.init()
    textureId = textures.register(self)
    player.actionAtItemEnd = .pause
    player.automaticallyWaitsToMinimizeStalling = false

    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
    interruptionObserver = NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
    ) { [weak self] note in
      // A call or another app took audio: stop, and let the user resume.
      let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
        .flatMap(AVAudioSession.InterruptionType.init)
      if type == .began { self?.pause() }
    }
    // Headphones unplugged: AVPlayer pauses on its own; the preview must
    // agree, or the next document would start it again out loud.
    routeObserver = NotificationCenter.default.addObserver(
      forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main
    ) { [weak self] note in
      let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt)
        .flatMap(AVAudioSession.RouteChangeReason.init)
      if reason == .oldDeviceUnavailable { self?.pause() }
    }

    timeObserver = player.addPeriodicTimeObserver(
      forInterval: CMTime(value: 1, timescale: 30), queue: .main
    ) { [weak self] _ in self?.publish() }

    let link = CADisplayLink(target: self, selector: #selector(onDisplayLink))
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  // MARK: FlutterTexture

  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    frameLock.lock()
    defer { frameLock.unlock() }
    guard let frame = latestFrame else { return nil }
    return Unmanaged.passRetained(frame)
  }

  @objc private func onDisplayLink(_ link: CADisplayLink) {
    guard let output, player.currentItem != nil else { return }
    let time = output.itemTime(forHostTime: CACurrentMediaTime())
    guard output.hasNewPixelBuffer(forItemTime: time),
      let buffer = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil)
    else { return }
    frameLock.lock()
    latestFrame = buffer
    frameLock.unlock()
    textures.textureFrameAvailable(textureId)
  }

  // MARK: Document

  /// Rebuilds the player item, keeping the position and play state.
  func setDocument(_ doc: EngineDocument) {
    buildTask?.cancel()
    let keepPosition = player.currentTime()
    buildTask = Task { @MainActor [weak self] in
      do {
        let built = try await CompositionBuilder.build(doc, forExport: false)
        guard let self, !Task.isCancelled else { return }
        self.install(built, at: keepPosition, version: Int64(doc.version))
      } catch {
        NSLog("Stitch: preview build failed: \(error)")
      }
    }
  }

  @MainActor
  private func install(_ built: BuiltComposition, at position: CMTime, version: Int64) {
    let item = AVPlayerItem(asset: built.composition)
    item.videoComposition = built.videoComposition
    item.audioMix = built.audioMix
    item.audioTimePitchAlgorithm = .spectral
    let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
      kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any](),
    ])
    item.add(output)
    self.output = output
    durationUs = built.duration.microseconds

    if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    endObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
    ) { [weak self] _ in
      self?.wantsPlay = false
      self?.publish()
    }

    player.replaceCurrentItem(with: item)
    displayLink?.isPaused = false
    let target = min(position, built.duration)
    player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
      guard let self else { return }
      self.shownVersion = version
      if self.wantsPlay { self.player.play() }
      self.publish()
    }
  }

  // MARK: Transport

  func play() {
    guard player.currentItem != nil else { return }
    wantsPlay = true
    if player.currentTime().microseconds >= durationUs - 10_000 {
      player.seek(to: .zero)
    }
    player.play()
    publish()
  }

  /// 0 to 1; muted while a voiceover records.
  func setVolume(_ volume: Double) {
    player.volume = Float(min(max(volume, 0), 1))
  }

  func pause() {
    wantsPlay = false
    player.pause()
    publish()
  }

  func seek(us: Int64, exact: Bool) {
    if seeking {
      pendingSeek = (us, exact)
      return
    }
    seeking = true
    // Scrubbing tolerates landing near the target, which is much faster.
    let tolerance = exact ? CMTime.zero : CMTime(value: 1, timescale: 10)
    player.seek(to: cmTime(us: us), toleranceBefore: tolerance, toleranceAfter: tolerance) {
      [weak self] _ in
      DispatchQueue.main.async {
        guard let self else { return }
        self.seeking = false
        self.publish()
        if let next = self.pendingSeek {
          self.pendingSeek = nil
          self.seek(us: next.us, exact: next.exact)
        }
      }
    }
  }

  private func publish() {
    let buffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
    onState(
      PlaybackStateMessage(
        positionUs: min(player.currentTime().microseconds, durationUs),
        durationUs: durationUs,
        isPlaying: player.rate != 0 || (wantsPlay && buffering),
        isBuffering: buffering,
        documentVersion: shownVersion))
  }

  /// Stops playback and frees decoders. The texture stays registered so
  /// the preview can be used again after a new document.
  func release() {
    buildTask?.cancel()
    wantsPlay = false
    player.pause()
    player.replaceCurrentItem(with: nil)
    output = nil
    durationUs = 0
    // Nothing to draw until the next document: stop the frame callback
    // and let the last frame go.
    displayLink?.isPaused = true
    frameLock.lock()
    latestFrame = nil
    frameLock.unlock()
    publish()
  }

  func dispose() {
    release()
    displayLink?.invalidate()
    if let timeObserver { player.removeTimeObserver(timeObserver) }
    if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    if let interruptionObserver { NotificationCenter.default.removeObserver(interruptionObserver) }
    if let routeObserver { NotificationCenter.default.removeObserver(routeObserver) }
    textures.unregisterTexture(textureId)
  }
}
