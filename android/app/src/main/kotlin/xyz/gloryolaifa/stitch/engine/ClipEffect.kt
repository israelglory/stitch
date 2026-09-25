package xyz.gloryolaifa.stitch.engine

import android.content.Context
import android.graphics.Matrix
import android.opengl.GLES20
import androidx.annotation.OptIn
import androidx.media3.common.VideoFrameProcessingException
import androidx.media3.common.util.GlProgram
import androidx.media3.common.util.GlUtil
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BaseGlShaderProgram
import androidx.media3.effect.GlEffect
import androidx.media3.effect.GlShaderProgram
import java.util.Locale
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** The canvas a clip is drawn on: output size and background. */
data class CanvasLook(val width: Int, val height: Int, val background: EngineDocument.Background)

/** The clip a transition leaves, as the incoming clip's effect draws it. */
data class Outgoing(
  /** Null when the file is missing: the clip shows as the background. */
  val path: String?,
  val kind: String,
  /** Source time at the start of the transition. */
  val sourceStartUs: Long,
  val speed: Double,
  val framing: EngineDocument.Framing,
  /** How long to wait for a frame of it; see [OutgoingFrames.open]. */
  val timeoutMs: Long,
)

/** A transition into the clip, in sequence time. */
data class Incoming(
  val type: String,
  val startUs: Long,
  val durationUs: Long,
  val from: Outgoing,
)

/**
 * Draws a clip on the canvas: fitted or filled, framed, over the background
 * (a solid color or a blurred copy of the clip). During [incoming] it also
 * draws the clip being left and mixes the two with the transition shader.
 *
 * One effect per clip replaces Media3's compositor, which has no way to
 * run a custom shader and stalls when previewing two sequences.
 */
@OptIn(UnstableApi::class)
class ClipEffect(
  private val look: CanvasLook,
  private val framing: EngineDocument.Framing,
  private val incoming: Incoming?,
) : GlEffect {
  override fun toGlShaderProgram(context: Context, useHdr: Boolean): GlShaderProgram =
    ClipProgram(look, framing, incoming, useHdr)

  override fun isNoOp(inputWidth: Int, inputHeight: Int) = false
}

@OptIn(UnstableApi::class)
private class ClipProgram(
  private val look: CanvasLook,
  private val framing: EngineDocument.Framing,
  private val incoming: Incoming?,
  useHdr: Boolean,
) : BaseGlShaderProgram(useHdr, /* texturePoolCapacity= */ 1) {
  private val blur = look.background.type == "blur"
  private val programs = mutableMapOf<String, GlProgram>()
  private var inputWidth = 1
  private var inputHeight = 1
  private val blurSize = blurSize(look)
  private var toBlur: BlurTargets? = null
  private var fromBlur: BlurTargets? = null
  private var outgoing: OutgoingFrames? = null
  private var outgoingOpened = false

  override fun configure(inputWidth: Int, inputHeight: Int): Size {
    this.inputWidth = inputWidth
    this.inputHeight = inputHeight
    return Size(look.width, look.height)
  }

  override fun drawFrame(inputTexId: Int, presentationTimeUs: Long) {
    try {
      val saved = IntArray(1)
      GLES20.glGetIntegerv(GLES20.GL_FRAMEBUFFER_BINDING, saved, 0)

      val transition = incoming?.takeIf {
        presentationTimeUs >= it.startUs && presentationTimeUs < it.startUs + it.durationUs
      }
      var from: SourceFrame? = null
      if (transition != null) {
        val sourceUs = transition.from.sourceStartUs +
          ((presentationTimeUs - transition.startUs) * transition.from.speed).toLong()
        from = outgoing(transition)?.frameAt(sourceUs)
      }

      val toBlurTex = if (blur) {
        val input = SourceFrame(intArrayOf(inputTexId), inputWidth, inputHeight, Mat3.IDENTITY)
        blurTargets(isFrom = false).render(input)
      } else {
        0
      }
      val fromBlurTex = if (blur && from != null) {
        blurTargets(isFrom = true).render(from)
      } else {
        toBlurTex
      }

      GlUtil.focusFramebufferUsingCurrentContext(saved[0], look.width, look.height)
      val yuv = from?.isYuv == true
      val program = program(mainKey(transition != null, yuv)) {
        GlProgram(VERTEX, mainFragment(transition != null, yuv, blur))
      }
      program.use()
      program.setSamplerTexIdUniform("uTo", inputTexId, 0)
      program.setFloatsUniform(
        "uToPlace",
        placement(look, inputWidth, inputHeight, framing.mode, framing),
      )
      program.setFloatsUniformIfPresent("uBackground", backgroundRgb())
      if (blur) program.setSamplerTexIdUniform("uToBlur", toBlurTex, 1)
      if (transition != null) {
        // A missing outgoing clip samples the incoming texture but shows
        // only the background.
        if (from != null && from.isYuv) {
          program.setSamplerTexIdUniform("uFromY", from.textures[0], 2)
          program.setSamplerTexIdUniform("uFromU", from.textures[1], 4)
          program.setSamplerTexIdUniform("uFromV", from.textures[2], 5)
          program.setFloatsUniform("uYuv", from.yuvToRgb!!)
          program.setFloatsUniform("uYuvOffset", from.yuvOffset!!)
        } else {
          program.setSamplerTexIdUniform("uFrom", from?.textures?.get(0) ?: inputTexId, 2)
        }
        program.setFloatsUniform(
          "uFromPlace",
          if (from != null) {
            placement(look, from.width, from.height, transition.from.framing.mode, transition.from.framing)
          } else {
            Mat3.IDENTITY
          },
        )
        program.setFloatsUniform("uFromTex", from?.texMatrix ?: Mat3.IDENTITY)
        program.setFloatUniform("uFromPresent", if (from != null) 1f else 0f)
        if (blur) program.setSamplerTexIdUniform("uFromBlur", fromBlurTex, 3)
        program.setFloatUniform(
          "uProgress",
          (presentationTimeUs - transition.startUs).toFloat() / transition.durationUs,
        )
        program.setIntUniform("uType", TransitionShader.typeIndex(transition.type))
      }
      program.bindAttributesAndUniforms()
      GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
      GlUtil.checkGlError()
    } catch (e: GlUtil.GlException) {
      throw VideoFrameProcessingException(e, presentationTimeUs)
    }
  }

  private fun outgoing(transition: Incoming): OutgoingFrames? {
    if (!outgoingOpened) {
      outgoingOpened = true
      outgoing = transition.from.path?.let {
        OutgoingFrames.open(it, transition.from.kind, transition.from.timeoutMs)
      }
    }
    return outgoing
  }

  private fun backgroundRgb(): FloatArray {
    val argb = look.background.color ?: 0xFF000000L
    return floatArrayOf(
      ((argb shr 16) and 0xFF) / 255f,
      ((argb shr 8) and 0xFF) / 255f,
      (argb and 0xFF) / 255f,
    )
  }

  private fun blurTargets(isFrom: Boolean): BlurTargets {
    val existing = if (isFrom) fromBlur else toBlur
    if (existing != null) return existing
    return BlurTargets(blurSize).also { if (isFrom) fromBlur = it else toBlur = it }
  }

  private fun program(key: String, create: () -> GlProgram): GlProgram =
    programs.getOrPut(key, create).also { it.setBufferAttribute("aFramePosition", QUAD, 4) }

  /** Two small textures: the source filled into the canvas, then blurred. */
  private inner class BlurTargets(val size: Size) {
    private val a = GlUtil.createTexture(size.width, size.height, false)
    private val b = GlUtil.createTexture(size.width, size.height, false)
    private val fboA = GlUtil.createFboForTexture(a)
    private val fboB = GlUtil.createFboForTexture(b)

    /** Returns the blurred texture. */
    fun render(source: SourceFrame): Int {
      val cover = program(if (source.isYuv) "coverYuv" else "cover") {
        GlProgram(VERTEX, coverFragment(source.isYuv))
      }
      GlUtil.focusFramebufferUsingCurrentContext(fboA, size.width, size.height)
      cover.use()
      if (source.isYuv) {
        cover.setSamplerTexIdUniform("uSourceY", source.textures[0], 0)
        cover.setSamplerTexIdUniform("uSourceU", source.textures[1], 1)
        cover.setSamplerTexIdUniform("uSourceV", source.textures[2], 2)
        cover.setFloatsUniform("uYuv", source.yuvToRgb!!)
        cover.setFloatsUniform("uYuvOffset", source.yuvOffset!!)
      } else {
        cover.setSamplerTexIdUniform("uSource", source.textures[0], 0)
      }
      cover.setFloatsUniform("uCover", placement(look, source.width, source.height, "fill", null))
      cover.setFloatsUniform("uTex", source.texMatrix)
      cover.bindAttributesAndUniforms()
      GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

      val pass = program("blur${size.width}") { GlProgram(VERTEX, blurFragment(size.width)) }
      GlUtil.focusFramebufferUsingCurrentContext(fboB, size.width, size.height)
      pass.use()
      pass.setSamplerTexIdUniform("uSource", a, 0)
      pass.setFloatsUniform("uStep", floatArrayOf(1f / size.width, 0f))
      pass.bindAttributesAndUniforms()
      GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

      GlUtil.focusFramebufferUsingCurrentContext(fboA, size.width, size.height)
      pass.setSamplerTexIdUniform("uSource", b, 0)
      pass.setFloatsUniform("uStep", floatArrayOf(0f, 1f / size.height))
      pass.bindAttributesAndUniforms()
      GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
      return a
    }

    fun release() {
      runCatching { GlUtil.deleteFbo(fboA) }
      runCatching { GlUtil.deleteFbo(fboB) }
      runCatching { GlUtil.deleteTexture(a) }
      runCatching { GlUtil.deleteTexture(b) }
    }
  }

  override fun release() {
    super.release()
    outgoing?.release()
    toBlur?.release()
    fromBlur?.release()
    programs.values.forEach { runCatching { it.delete() } }
  }

  companion object {
    val QUAD = GlUtil.getNormalizedCoordinateBounds()

    /** Long side of the blur textures; the blur radius scales with it. */
    const val BLUR_LONG_SIDE = 96

    fun blurSize(look: CanvasLook): Size {
      val scale = BLUR_LONG_SIDE.toFloat() / max(look.width, look.height)
      return Size(
        max(8, (look.width * scale).roundToInt()),
        max(8, (look.height * scale).roundToInt()),
      )
    }

    fun mainKey(transition: Boolean, yuv: Boolean) =
      "main" + (if (transition) "T" else "") + (if (yuv) "Y" else "")
  }
}

/**
 * Maps canvas coordinates (0 to 1, y up) to frame coordinates for a
 * [width] x [height] frame fitted or filled ([mode]) into [look], then
 * scaled, offset (fractions of the canvas, y down), and rotated (degrees
 * clockwise) by [framing]. Matches `place` in StitchCompositor.swift.
 * Column-major mat3.
 */
fun placement(
  look: CanvasLook,
  width: Int,
  height: Int,
  mode: String,
  framing: EngineDocument.Framing?,
): FloatArray {
  val cw = look.width.toFloat()
  val ch = look.height.toFloat()
  val fw = max(1, width).toFloat()
  val fh = max(1, height).toFloat()
  val base = if (mode == "fill") max(cw / fw, ch / fh) else min(cw / fw, ch / fh)
  val scale = base * (framing?.scale ?: 1.0).toFloat()
  val placeFrame = Matrix().apply {
    setTranslate(-fw / 2, -fh / 2)
    postScale(scale, scale)
    // Positive degrees turn counterclockwise with y up.
    postRotate(-(framing?.rotationDeg ?: 0.0).toFloat())
    postTranslate(
      cw / 2 + (framing?.offsetX ?: 0.0).toFloat() * cw,
      ch / 2 - (framing?.offsetY ?: 0.0).toFloat() * ch,
    )
  }
  val inverse = Matrix()
  placeFrame.invert(inverse)
  val m = Matrix().apply {
    setScale(cw, ch)
    postConcat(inverse)
    postScale(1 / fw, 1 / fh)
  }
  val v = FloatArray(9)
  m.getValues(v)
  return floatArrayOf(v[0], v[3], v[6], v[1], v[4], v[7], v[2], v[5], v[8])
}

private const val VERTEX = """
attribute vec4 aFramePosition;
varying vec2 vUv;
void main() {
  gl_Position = aFramePosition;
  vUv = aFramePosition.xy * 0.5 + 0.5;
}
"""

private const val HEADER = "precision highp float;\nvarying vec2 vUv;\n"

/** GLSL for sampling a frame that is either RGB or three YUV planes. */
private fun sampler(name: String, yuv: Boolean): String = if (yuv) {
  """
uniform sampler2D ${name}Y;
uniform sampler2D ${name}U;
uniform sampler2D ${name}V;
uniform mat3 uYuv;
uniform vec3 uYuvOffset;
vec4 sample$name(vec2 t) {
  vec3 yuv = vec3(texture2D(${name}Y, t).r, texture2D(${name}U, t).r, texture2D(${name}V, t).r);
  return vec4(clamp(uYuv * (yuv - uYuvOffset), 0.0, 1.0), 1.0);
}
"""
} else {
  """
uniform sampler2D $name;
vec4 sample$name(vec2 t) { return texture2D($name, t); }
"""
}

private fun mainFragment(transition: Boolean, yuv: Boolean, blur: Boolean): String {
  val defines = buildString {
    if (transition) append("#define TRANSITION\n")
    if (blur) append("#define BLUR\n")
  }
  return HEADER + defines + """
uniform sampler2D uTo;
uniform mat3 uToPlace;
uniform vec3 uBackground;
#ifdef BLUR
uniform sampler2D uToBlur;
#endif

bool inside(vec2 p) {
  return p.x >= 0.0 && p.x <= 1.0 && p.y >= 0.0 && p.y <= 1.0;
}

vec4 getToColor(vec2 uv) {
#ifdef BLUR
  vec3 bg = texture2D(uToBlur, uv).rgb;
#else
  vec3 bg = uBackground;
#endif
  vec2 p = (uToPlace * vec3(uv, 1.0)).xy;
  if (!inside(p)) return vec4(bg, 1.0);
  vec4 c = texture2D(uTo, p);
  return vec4(mix(bg, c.rgb, c.a), 1.0);
}

#ifdef TRANSITION
${sampler("uFrom", yuv)}
uniform mat3 uFromPlace;
uniform mat3 uFromTex;
uniform float uFromPresent;
uniform float uProgress;
uniform int uType;
#ifdef BLUR
uniform sampler2D uFromBlur;
#endif

vec4 getFromColor(vec2 uv) {
  if (uFromPresent < 0.5) return vec4(uBackground, 1.0);
#ifdef BLUR
  vec3 bg = texture2D(uFromBlur, uv).rgb;
#else
  vec3 bg = uBackground;
#endif
  vec2 p = (uFromPlace * vec3(uv, 1.0)).xy;
  if (!inside(p)) return vec4(bg, 1.0);
  vec4 c = sampleuFrom((uFromTex * vec3(p, 1.0)).xy);
  return vec4(mix(bg, c.rgb, c.a), 1.0);
}

${TransitionShader.GLSL}
#endif

void main() {
#ifdef TRANSITION
  gl_FragColor = transition(vUv, uProgress, uType);
#else
  gl_FragColor = getToColor(vUv);
#endif
}
"""
}

private fun coverFragment(yuv: Boolean): String = HEADER + sampler("uSource", yuv) + """
uniform mat3 uCover;
uniform mat3 uTex;
void main() {
  vec2 p = clamp((uCover * vec3(vUv, 1.0)).xy, 0.0, 1.0);
  gl_FragColor = sampleuSource((uTex * vec3(p, 1.0)).xy);
}
"""

/**
 * One direction of a gaussian blur, unrolled. Sigma is 4 percent of the
 * canvas width, as on iOS; here the canvas is [width] texels wide.
 */
private fun blurFragment(width: Int): String {
  val sigma = 0.04 * width
  val taps = (sigma * 2.5).roundToInt().coerceIn(2, 12)
  val raw = (0..taps).map { exp(-(it * it) / (2 * sigma * sigma)) }
  val total = raw[0] + 2 * raw.drop(1).sum()
  // Plain decimals: GLSL does not accept Kotlin's exponent notation.
  val w = raw.map { String.format(Locale.ROOT, "%.8f", it / total) }
  return buildString {
    append(HEADER)
    append("uniform sampler2D uSource;\nuniform vec2 uStep;\nvoid main() {\n")
    append("  vec4 c = texture2D(uSource, vUv) * ${w[0]};\n")
    for (i in 1..taps) {
      append(
        "  c += (texture2D(uSource, vUv + uStep * $i.0) + " +
          "texture2D(uSource, vUv - uStep * $i.0)) * ${w[i]};\n",
      )
    }
    append("  gl_FragColor = c;\n}\n")
  }
}
