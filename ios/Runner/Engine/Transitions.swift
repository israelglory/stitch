import CoreImage
import Metal

/// Mixes two canvas images with a transition shader.
///
/// Each transition is written once, in transitions/*.glsl, and generated
/// as Metal into TransitionSources.swift (tool/gen_transitions.dart). The
/// shaders are compiled at runtime by the system, each on first use: a Core
/// Image kernel would need the Metal toolchain, an optional Xcode download,
/// for every build. Both canvases are rendered into textures, a compute
/// kernel mixes them, and the result goes back to Core Image.
///
/// Used from the compositor's serial queue only.
final class Transitions {
  /// What unknown types (from a newer version) play as.
  static let fallback = "crossfade"

  private let device: MTLDevice
  private let context: CIContext
  private let queue: MTLCommandQueue

  /// The shader sees sRGB values, as on Android and in the Flutter
  /// previews (all three are tested against the same reference images):
  /// transitions that brighten or threshold (burn, brightness fade) would
  /// look different on values encoded for Rec. 709. Core Image converts on
  /// the way in and out.
  private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
  private var pipelines: [String: MTLComputePipelineState] = [:]
  private var textures: (from: MTLTexture, to: MTLTexture, out: MTLTexture)?

  init?(device: MTLDevice?, context: CIContext) {
    guard let device, let queue = device.makeCommandQueue() else { return nil }
    self.device = device
    self.context = context
    self.queue = queue
  }

  /// [from] and [to] each cover [canvas], which starts at the origin. Nil
  /// when the transition cannot run (the caller dissolves instead).
  func apply(from: CIImage, to: CIImage, type: String, progress: CGFloat, canvas: CGRect)
    -> CIImage?
  {
    let width = Int(canvas.width.rounded())
    let height = Int(canvas.height.rounded())
    guard width > 0, height > 0,
      let pipeline = pipeline(for: type) ?? pipeline(for: Self.fallback),
      let targets = textures(width: width, height: height),
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
    var params = Params(progress: Float(progress), ratio: Float(width) / Float(height))
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

  /// The compiled shader for [type], built on first use; nil for unknown
  /// types and shaders that fail to build.
  private func pipeline(for type: String) -> MTLComputePipelineState? {
    if let cached = pipelines[type] { return cached }
    guard let body = TransitionSources.metal[type] else { return nil }
    do {
      let pipeline = try Self.makePipeline(device: device, body: body)
      pipelines[type] = pipeline
      return pipeline
    } catch {
      NSLog("Stitch: transition \(type) failed to build: \(error)")
      return nil
    }
  }

  /// Compiles one transition's Metal [body] into a compute pipeline.
  static func makePipeline(device: MTLDevice, body: String) throws -> MTLComputePipelineState {
    let library = try device.makeLibrary(source: prelude + body + kernel, options: nil)
    guard let function = library.makeFunction(name: "stitchTransition") else {
      throw EngineError.badDocument("Transition kernel missing")
    }
    return try device.makeComputePipelineState(function: function)
  }

  private func textures(width: Int, height: Int) -> (from: MTLTexture, to: MTLTexture, out: MTLTexture)? {
    if let textures, textures.out.width == width, textures.out.height == height { return textures }
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
    descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
    descriptor.storageMode = .private
    guard let from = device.makeTexture(descriptor: descriptor),
      let to = device.makeTexture(descriptor: descriptor),
      let out = device.makeTexture(descriptor: descriptor)
    else { return nil }
    textures = (from, to, out)
    return textures
  }

  private struct Params {
    var progress: Float
    var ratio: Float
  }

  /// Makes the GLSL the transitions are written in (see
  /// transitions/README.md) valid Metal: GLSL's type names and the few
  /// functions Metal names differently. Every transition function takes
  /// the two textures, progress, and ratio (CTX_PARAMS), as Metal has no
  /// global uniforms; the generator passes them on (CTX_ARGS). uv is 0 to 1
  /// with y up.
  private static let prelude = """
    #include <metal_stdlib>
    using namespace metal;

    #define vec2 float2
    #define vec3 float3
    #define vec4 float4
    #define mat2 float2x2
    #define mat3 float3x3

    #define CTX_PARAMS texture2d<float> _from, texture2d<float> _to, float progress, float ratio
    #define CTX_ARGS _from, _to, progress, ratio

    constexpr sampler _smp(address::clamp_to_edge, filter::linear, coord::normalized);
    #define getFromColor(p) _from.sample(_smp, (p))
    #define getToColor(p) _to.sample(_smp, (p))

    // GLSL's mod floors; Metal's fmod truncates.
    inline float mod(float x, float y) { return x - y * floor(x / y); }
    inline float2 mod(float2 x, float y) { return x - y * floor(x / y); }
    inline float3 mod(float3 x, float y) { return x - y * floor(x / y); }
    inline float2 mod(float2 x, float2 y) { return x - y * floor(x / y); }
    inline float atan(float y, float x) { return atan2(y, x); }
    #define inversesqrt rsqrt


    """

  private static let kernel = """


    struct Params { float progress; float ratio; };

    kernel void stitchTransition(
        texture2d<float, access::sample> from [[texture(0)]],
        texture2d<float, access::sample> to [[texture(1)]],
        texture2d<float, access::write> out [[texture(2)]],
        constant Params& params [[buffer(0)]],
        uint2 gid [[thread_position_in_grid]]) {
      if (gid.x >= out.get_width() || gid.y >= out.get_height()) return;
      float2 uv = (float2(gid) + 0.5) / float2(out.get_width(), out.get_height());
      out.write(transition(from, to, params.progress, params.ratio, uv), gid);
    }
    """
}
