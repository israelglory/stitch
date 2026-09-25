import CoreImage
import Metal

/// Mixes two canvas images with the transition shader.
///
/// The shader is Metal compiled at runtime by the system: a Core Image
/// kernel would need the Metal toolchain, an optional Xcode download, for
/// every build. Both canvases are rendered into textures, a compute kernel
/// mixes them, and the result goes back to Core Image.
///
/// Used from the compositor's serial queue only.
final class Transitions {
  /// Type names from the document, in the shader's type-number order.
  private static let types = [
    "crossfade", "fadeToBlack", "slideLeft", "slideRight", "wipeLeft", "wipeRight", "zoomIn",
  ]

  /// 1-based number for [type]; unknown types crossfade.
  static func number(for type: String) -> Int32 {
    Int32((types.firstIndex(of: type) ?? 0) + 1)
  }

  private let context: CIContext
  private let queue: MTLCommandQueue
  private let pipeline: MTLComputePipelineState
  private let colorSpace: CGColorSpace
  private var textures: (from: MTLTexture, to: MTLTexture, out: MTLTexture)?

  init?(device: MTLDevice?, context: CIContext, colorSpace: CGColorSpace) {
    guard let device, let queue = device.makeCommandQueue() else { return nil }
    do {
      let library = try device.makeLibrary(source: Self.source, options: nil)
      guard let function = library.makeFunction(name: "stitchTransition") else { return nil }
      pipeline = try device.makeComputePipelineState(function: function)
    } catch {
      NSLog("Stitch: transition shader failed to build: \(error)")
      return nil
    }
    self.context = context
    self.queue = queue
    self.colorSpace = colorSpace
  }

  /// [from] and [to] each cover [canvas], which starts at the origin.
  func apply(from: CIImage, to: CIImage, type: String, progress: CGFloat, canvas: CGRect)
    -> CIImage?
  {
    let width = Int(canvas.width.rounded())
    let height = Int(canvas.height.rounded())
    guard width > 0, height > 0, let targets = textures(width: width, height: height),
      let commands = queue.makeCommandBuffer()
    else { return nil }

    // Core Image writes row 0 as the bottom and reads it back the same way,
    // so the shader's y runs up, as in the GLSL version.
    context.render(from, to: targets.from, commandBuffer: commands, bounds: canvas, colorSpace: colorSpace)
    context.render(to, to: targets.to, commandBuffer: commands, bounds: canvas, colorSpace: colorSpace)
    guard let encoder = commands.makeComputeCommandEncoder() else { return nil }
    encoder.setComputePipelineState(pipeline)
    encoder.setTexture(targets.from, index: 0)
    encoder.setTexture(targets.to, index: 1)
    encoder.setTexture(targets.out, index: 2)
    var params = Params(progress: Float(progress), type: Self.number(for: type))
    encoder.setBytes(&params, length: MemoryLayout<Params>.stride, index: 0)
    let group = MTLSize(width: 16, height: 16, depth: 1)
    encoder.dispatchThreadgroups(
      MTLSize(width: (width + 15) / 16, height: (height + 15) / 16, depth: 1),
      threadsPerThreadgroup: group)
    encoder.endEncoding()
    commands.commit()
    commands.waitUntilCompleted()
    return CIImage(mtlTexture: targets.out, options: [.colorSpace: colorSpace])
  }

  private func textures(width: Int, height: Int) -> (from: MTLTexture, to: MTLTexture, out: MTLTexture)? {
    if let textures, textures.out.width == width, textures.out.height == height { return textures }
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
    descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
    descriptor.storageMode = .private
    let device = queue.device
    guard let from = device.makeTexture(descriptor: descriptor),
      let to = device.makeTexture(descriptor: descriptor),
      let out = device.makeTexture(descriptor: descriptor)
    else { return nil }
    textures = (from, to, out)
    return textures
  }

  private struct Params {
    var progress: Float
    var type: Int32
  }

  /// The transitions, in the style of gl-transitions (https://gl-transitions.com,
  /// MIT): a color from the outgoing frame, the incoming frame, and linear
  /// progress. Mirrors TransitionShader.kt on Android; docs/engine.md defines
  /// the looks and test_media/transition_cases.json holds the colors both
  /// platforms are tested against. uv is 0 to 1 with y up.
  private static let source = """
    #include <metal_stdlib>
    using namespace metal;

    struct Params { float progress; int type; };

    static float4 at(texture2d<float, access::sample> t, float2 uv) {
      constexpr sampler s(address::clamp_to_edge, filter::linear, coord::normalized);
      return t.sample(s, uv);
    }

    kernel void stitchTransition(
        texture2d<float, access::sample> from [[texture(0)]],
        texture2d<float, access::sample> to [[texture(1)]],
        texture2d<float, access::write> out [[texture(2)]],
        constant Params& params [[buffer(0)]],
        uint2 gid [[thread_position_in_grid]]) {
      if (gid.x >= out.get_width() || gid.y >= out.get_height()) return;
      float2 uv = (float2(gid) + 0.5) / float2(out.get_width(), out.get_height());
      float p = params.progress;
      int type = params.type;
      float4 black = float4(0.0, 0.0, 0.0, 1.0);
      float4 color;
      if (type == 2) {
        // Fade to black: out through black, darkest halfway.
        color = p < 0.5 ? mix(at(from, uv), black, p * 2.0)
                        : mix(black, at(to, uv), p * 2.0 - 1.0);
      } else if (type == 3) {
        // Slide left: both frames move left by p.
        color = uv.x < 1.0 - p ? at(from, float2(uv.x + p, uv.y))
                               : at(to, float2(uv.x - (1.0 - p), uv.y));
      } else if (type == 4) {
        // Slide right: both frames move right by p.
        color = uv.x >= p ? at(from, float2(uv.x - p, uv.y))
                          : at(to, float2(uv.x + (1.0 - p), uv.y));
      } else if (type == 5) {
        // Wipe left: the incoming frame is revealed from the right edge.
        color = uv.x >= 1.0 - p ? at(to, uv) : at(from, uv);
      } else if (type == 6) {
        // Wipe right: the incoming frame is revealed from the left edge.
        color = uv.x < p ? at(to, uv) : at(from, uv);
      } else if (type == 7) {
        // Zoom in: the outgoing frame grows by up to 60 percent as it fades.
        float4 grown = at(from, (uv - 0.5) / (1.0 + 0.6 * p) + 0.5);
        color = mix(grown, at(to, uv), p);
      } else {
        // Crossfade.
        color = mix(at(from, uv), at(to, uv), p);
      }
      out.write(color, gid);
    }
    """
}
