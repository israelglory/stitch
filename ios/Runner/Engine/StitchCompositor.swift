import AVFoundation
import CoreImage
import Metal

/// Draws every output frame: each active clip turned upright, fitted or
/// filled into the canvas, and framed, over its background. During a
/// transition the two clips' canvases are mixed by the shader in
/// Transitions.swift.
///
/// Geometry is computed in canvas pixels (Core Image space, origin bottom
/// left) and scaled to the render size at the end, so preview and every
/// export resolution frame identically.
///
/// Not declaring HDR support makes AVFoundation tone map HDR sources to
/// SDR before they arrive here.
final class StitchCompositor: NSObject, AVVideoCompositing {
  private static let device = MTLCreateSystemDefaultDevice()
  private let context: CIContext = {
    let options: [CIContextOption: Any] = [
      .workingColorSpace: CGColorSpace(name: CGColorSpace.itur_709)!,
      .cacheIntermediates: false,
    ]
    if let device = StitchCompositor.device {
      return CIContext(mtlDevice: device, options: options)
    }
    return CIContext(options: options)
  }()
  private let queue = DispatchQueue(label: "stitch.compositor", qos: .userInitiated)
  private let outputColorSpace = CGColorSpace(name: CGColorSpace.itur_709)!
  private var photoCache = PhotoCache()
  private lazy var transitions = Transitions(
    device: Self.device, context: context, colorSpace: outputColorSpace)

  let sourcePixelBufferAttributes: [String: any Sendable]? = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any](),
  ]

  let requiredPixelBufferAttributesForRenderContext: [String: any Sendable] = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any](),
  ]

  var supportsHDRSourceFrames: Bool { false }
  var supportsWideColorSourceFrames: Bool { false }

  func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}

  func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
    queue.async { [self] in
      guard let instruction = request.videoCompositionInstruction as? StitchInstruction,
        let output = request.renderContext.newPixelBuffer()
      else {
        request.finish(with: EngineError.badDocument("No instruction for frame"))
        return
      }
      let timeUs = request.compositionTime.microseconds
      let image = compose(instruction, at: timeUs, request: request)
      let renderSize = request.renderContext.size
      let scale = CGAffineTransform(
        scaleX: renderSize.width / instruction.canvasSize.width,
        y: renderSize.height / instruction.canvasSize.height)
      context.render(
        image.transformed(by: scale),
        to: output,
        bounds: CGRect(origin: .zero, size: renderSize),
        colorSpace: outputColorSpace)
      request.finish(withComposedVideoFrame: output)
    }
  }

  func cancelAllPendingVideoCompositionRequests() {
    queue.sync {}
  }

  private func compose(
    _ instruction: StitchInstruction, at timeUs: Int64,
    request: AVAsynchronousVideoCompositionRequest
  ) -> CIImage {
    let canvas = CGRect(origin: .zero, size: instruction.canvasSize)
    // Each clip drawn on its own canvas: background, then the placed frame.
    let images = instruction.layers.map { layer -> CIImage in
      let frame = source(for: layer, request: request)
      let back = background(instruction, frame: frame, canvas: canvas)
      guard let frame else { return back }
      return place(frame, framing: layer.framing, in: canvas).composited(over: back)
        .cropped(to: canvas)
    }
    guard let last = images.last else {
      return background(instruction, frame: nil, canvas: canvas)
    }
    if images.count == 2, let transition = instruction.transition,
      let progress = transitionProgress(transition, at: timeUs)
    {
      if let mixed = transitions?.apply(
        from: images[0], to: images[1], type: transition.type, progress: progress,
        canvas: canvas)
      {
        return mixed
      }
      // No Metal: dissolve instead.
      return images[0].applyingFilter(
        "CIDissolveTransition", parameters: [kCIInputTargetImageKey: images[1], "inputTime": progress])
    }
    return last
  }

  /// The source frame for a layer, upright, with its origin at zero.
  private func source(
    for layer: CompositorLayer, request: AVAsynchronousVideoCompositionRequest
  ) -> CIImage? {
    if let path = layer.photoPath {
      return photoCache.image(at: path)
    }
    guard let id = layer.trackID, let buffer = request.sourceFrame(byTrackID: id) else {
      return nil
    }
    let image = CIImage(cvPixelBuffer: buffer)
    let upright = image.oriented(Self.orientation(forClockwiseDegrees: layer.sourceRotationDeg))
    return upright.transformed(
      by: CGAffineTransform(translationX: -upright.extent.minX, y: -upright.extent.minY))
  }

  /// Fits (or fills) [image] into [canvas], then applies the clip's scale,
  /// offset (fractions of the canvas, y down), and rotation (clockwise).
  private func place(_ image: CIImage, framing: EngineDocument.Framing, in canvas: CGRect)
    -> CIImage
  {
    let size = image.extent.size
    guard size.width > 0, size.height > 0 else { return image }
    let fit = min(canvas.width / size.width, canvas.height / size.height)
    let fill = max(canvas.width / size.width, canvas.height / size.height)
    let base = framing.mode == "fill" ? fill : fit
    let scale = base * CGFloat(framing.scale)
    let angle = -CGFloat(framing.rotationDeg) * .pi / 180
    let center = CGPoint(
      x: canvas.midX + CGFloat(framing.offsetX) * canvas.width,
      y: canvas.midY - CGFloat(framing.offsetY) * canvas.height)
    let transform = CGAffineTransform(translationX: -size.width / 2, y: -size.height / 2)
      .concatenating(CGAffineTransform(scaleX: scale, y: scale))
      .concatenating(CGAffineTransform(rotationAngle: angle))
      .concatenating(CGAffineTransform(translationX: center.x, y: center.y))
    return image.transformed(by: transform, highQualityDownsample: true)
  }

  /// The canvas behind [frame]: a blurred, filled copy of it, or the color.
  private func background(_ instruction: StitchInstruction, frame: CIImage?, canvas: CGRect)
    -> CIImage
  {
    if instruction.background.type == "blur", let frame {
      let size = frame.extent.size
      let fill = max(canvas.width / size.width, canvas.height / size.height)
      let filled = frame.transformed(
        by: CGAffineTransform(scaleX: fill, y: fill).concatenating(
          CGAffineTransform(
            translationX: canvas.midX - size.width * fill / 2,
            y: canvas.midY - size.height * fill / 2)))
      return filled.clampedToExtent()
        .applyingGaussianBlur(sigma: Double(canvas.width) * 0.04)
        .cropped(to: canvas)
    }
    let argb = instruction.background.color ?? 0xFF00_0000
    let color = CIColor(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255)
    return CIImage(color: color).cropped(to: canvas)
  }

  private func transitionProgress(_ t: CompositorTransition?, at timeUs: Int64) -> CGFloat? {
    guard let t, t.durationUs > 0 else { return nil }
    let p = CGFloat(timeUs - t.startUs) / CGFloat(t.durationUs)
    return min(max(p, 0), 1)
  }

  static func orientation(forClockwiseDegrees degrees: Int) -> CGImagePropertyOrientation {
    switch degrees {
    case 90: return .right
    case 180: return .down
    case 270: return .left
    default: return .up
    }
  }
}

/// Decoded photos, upright, kept while they are on the timeline. Bounded
/// so a long slideshow cannot exhaust memory.
private struct PhotoCache {
  private var images: [String: CIImage] = [:]
  private var order: [String] = []
  private let limit = 8

  mutating func image(at path: String) -> CIImage? {
    if let cached = images[path] { return cached }
    guard
      let image = CIImage(
        contentsOf: URL(fileURLWithPath: path), options: [.applyOrientationProperty: true])
    else { return nil }
    let upright = image.transformed(
      by: CGAffineTransform(translationX: -image.extent.minX, y: -image.extent.minY))
    images[path] = upright
    order.append(path)
    if order.count > limit {
      images.removeValue(forKey: order.removeFirst())
    }
    return upright
  }
}
