package xyz.gloryolaifa.stitch.engine

import android.content.Context
import android.graphics.Matrix
import android.opengl.GLES20
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.VideoFrameProcessingException
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.audio.SpeedProvider
import androidx.media3.common.util.GlProgram
import androidx.media3.common.util.GlUtil
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BaseGlShaderProgram
import androidx.media3.effect.GlEffect
import androidx.media3.effect.GlShaderProgram
import androidx.media3.effect.MatrixTransformation
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.max
import kotlin.math.min

/** Constant playback speed for an item. Pitch is kept by Media3's speed processing. */
@OptIn(UnstableApi::class)
class ConstantSpeed(private val speed: Float) : SpeedProvider {
  override fun getSpeed(timeUs: Long): Float = speed

  override fun getNextSpeedChangeTimeUs(timeUs: Long): Long = C.TIME_UNSET
}

/**
 * The clip's framing inside the canvas: scale, offset (fractions of the canvas,
 * y down), and rotation (degrees clockwise). Applied after the clip has been
 * fitted or filled to the canvas size, so it keeps the canvas size.
 */
@OptIn(UnstableApi::class)
class FramingTransformation(
  private val framing: EngineDocument.Framing,
  private val width: Int,
  private val height: Int,
) : MatrixTransformation {
  override fun getMatrix(presentationTimeUs: Long): Matrix {
    val w = width.toFloat()
    val h = height.toFloat()
    // Work in pixels (y up), then return to normalized device coordinates, so
    // rotation is not distorted by the canvas aspect ratio.
    return Matrix().apply {
      postScale(w / 2, h / 2)
      postScale(framing.scale.toFloat(), framing.scale.toFloat())
      postRotate(-framing.rotationDeg.toFloat())
      postTranslate((framing.offsetX * w).toFloat(), (-framing.offsetY * h).toFloat())
      postScale(2 / w, 2 / h)
    }
  }

  override fun isNoOp(inputWidth: Int, inputHeight: Int): Boolean =
    framing.scale == 1.0 && framing.offsetX == 0.0 && framing.offsetY == 0.0 &&
      framing.rotationDeg == 0.0
}

/**
 * Fills transparent areas (letterbox bars, space left by framing) with the
 * canvas background color, making each clip frame opaque. Clips then
 * crossfade cleanly without the background showing through mid-transition.
 */
@OptIn(UnstableApi::class)
class BackgroundFill(private val argb: Long) : GlEffect {
  override fun toGlShaderProgram(context: Context, useHdr: Boolean): GlShaderProgram =
    BackgroundFillProgram(useHdr, argb)
}

@OptIn(UnstableApi::class)
private class BackgroundFillProgram(useHdr: Boolean, argb: Long) :
  BaseGlShaderProgram(useHdr, /* texturePoolCapacity= */ 3) {
  private val program = GlProgram(VERTEX, FRAGMENT).apply {
    setBufferAttribute(
      "aFramePosition",
      GlUtil.getNormalizedCoordinateBounds(),
      GlUtil.HOMOGENEOUS_COORDINATE_VECTOR_SIZE,
    )
    setFloatsUniform(
      "uBackground",
      floatArrayOf(
        ((argb shr 16) and 0xFF) / 255f,
        ((argb shr 8) and 0xFF) / 255f,
        (argb and 0xFF) / 255f,
      ),
    )
  }

  override fun configure(inputWidth: Int, inputHeight: Int) = Size(inputWidth, inputHeight)

  override fun drawFrame(inputTexId: Int, presentationTimeUs: Long) {
    try {
      program.use()
      program.setSamplerTexIdUniform("uTexSampler", inputTexId, /* texUnitIndex= */ 0)
      program.bindAttributesAndUniforms()
      GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
    } catch (e: GlUtil.GlException) {
      throw VideoFrameProcessingException(e, presentationTimeUs)
    }
  }

  override fun release() {
    super.release()
    try {
      program.delete()
    } catch (_: GlUtil.GlException) {
    }
  }

  companion object {
    const val VERTEX = """
      attribute vec4 aFramePosition;
      varying vec2 vTexSamplingCoord;
      void main() {
        gl_Position = aFramePosition;
        vTexSamplingCoord = aFramePosition.xy * 0.5 + 0.5;
      }
    """
    const val FRAGMENT = """
      precision mediump float;
      uniform sampler2D uTexSampler;
      uniform vec3 uBackground;
      varying vec2 vTexSamplingCoord;
      void main() {
        vec4 c = texture2D(uTexSampler, vTexSamplingCoord);
        gl_FragColor = vec4(mix(uBackground, c.rgb, c.a), 1.0);
      }
    """
  }
}

/**
 * Volume with fade in and fade out over an item [durationUs] long (timeline
 * time). Silent after the end. Supports 16-bit and float PCM.
 */
@OptIn(UnstableApi::class)
class GainProcessor(
  private val volume: Float,
  private val durationUs: Long,
  private val fadeInUs: Long,
  private val fadeOutUs: Long,
) : BaseAudioProcessor() {
  private var framesSinceFlush = 0L
  private var startUs = 0L

  override fun onConfigure(inputAudioFormat: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
    if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT &&
      inputAudioFormat.encoding != C.ENCODING_PCM_FLOAT
    ) {
      throw AudioProcessor.UnhandledAudioFormatException(inputAudioFormat)
    }
    return inputAudioFormat
  }

  override fun onFlush(streamMetadata: AudioProcessor.StreamMetadata) {
    framesSinceFlush = 0
    startUs = max(0, streamMetadata.positionOffsetUs)
  }

  /** Gain at [timeUs] from the item's start. */
  fun gainAt(timeUs: Long): Float {
    if (timeUs >= durationUs) return 0f
    var g = volume
    if (fadeInUs > 0 && timeUs < fadeInUs) g *= timeUs.toFloat() / fadeInUs
    val fromEnd = durationUs - timeUs
    if (fadeOutUs > 0 && fromEnd < fadeOutUs) g *= fromEnd.toFloat() / fadeOutUs
    return max(0f, min(g, MAX_GAIN))
  }

  override fun queueInput(inputBuffer: ByteBuffer) {
    val format = inputAudioFormat
    val bytesPerFrame = format.bytesPerFrame
    val frames = inputBuffer.remaining() / bytesPerFrame
    val out = replaceOutputBuffer(inputBuffer.remaining()).order(ByteOrder.nativeOrder())
    val input = inputBuffer.order(ByteOrder.nativeOrder())
    for (f in 0 until frames) {
      val timeUs = startUs + (framesSinceFlush + f) * 1_000_000L / format.sampleRate
      val gain = gainAt(timeUs)
      for (ch in 0 until format.channelCount) {
        if (format.encoding == C.ENCODING_PCM_16BIT) {
          val s = input.short * gain
          out.putShort(s.coerceIn(Short.MIN_VALUE.toFloat(), Short.MAX_VALUE.toFloat()).toInt().toShort())
        } else {
          out.putFloat((input.float * gain).coerceIn(-1f, 1f))
        }
      }
    }
    framesSinceFlush += frames
    out.flip()
  }

  companion object {
    /** Volumes go up to 200 percent, as in the editor. */
    const val MAX_GAIN = 2f
  }
}
