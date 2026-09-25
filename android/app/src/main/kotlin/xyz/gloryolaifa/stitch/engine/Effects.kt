package xyz.gloryolaifa.stitch.engine

import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.audio.SpeedProvider
import androidx.media3.common.util.UnstableApi
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
 * The loudness of one item over time.
 *
 * An item can be part of a clip (a clip ending in a transition plays as two
 * items), so the clip's own fades are placed on the clip: the item starts
 * [offsetUs] into a clip [clipDurationUs] long. [rampInUs] and [rampOutUs]
 * are crossfades at the item's own start and end. Times are timeline time.
 */
data class Gain(
  val volume: Float,
  val clipDurationUs: Long,
  val fadeInUs: Long,
  val fadeOutUs: Long,
  val itemDurationUs: Long = clipDurationUs,
  val offsetUs: Long = 0,
  val rampInUs: Long = 0,
  val rampOutUs: Long = 0,
) {
  /** Gain at [itemTimeUs] from the item's start. Silent after the item. */
  fun at(itemTimeUs: Long): Float {
    if (itemTimeUs < 0 || itemTimeUs >= itemDurationUs) return 0f
    var g = volume
    val t = offsetUs + itemTimeUs
    if (fadeInUs > 0 && t < fadeInUs) g *= t.toFloat() / fadeInUs
    val fromClipEnd = clipDurationUs - t
    if (fadeOutUs > 0 && fromClipEnd < fadeOutUs) g *= max(0L, fromClipEnd).toFloat() / fadeOutUs
    if (rampInUs > 0 && itemTimeUs < rampInUs) g *= itemTimeUs.toFloat() / rampInUs
    val fromItemEnd = itemDurationUs - itemTimeUs
    if (rampOutUs > 0 && fromItemEnd < rampOutUs) g *= fromItemEnd.toFloat() / rampOutUs
    return max(0f, min(g, MAX_GAIN))
  }

  companion object {
    /**
     * An item's own volume (up to 200 percent) times the added-audio level
     * (up to 200 percent).
     */
    const val MAX_GAIN = 4f
  }
}

/**
 * Applies a [Gain] to 16-bit or float PCM.
 *
 * After a seek Media3 reports where the stream restarts as an offset from
 * the item's start (timeline time, after speed changes), so the gain follows
 * seeks in preview.
 *
 * Gain is applied in float. When the item can go above 100 percent, a
 * [Limiter] at full scale keeps it from clipping before the mix, which
 * has its own limiter ([LimitingAudioMixer]).
 *
 * The input is read out before the output buffer is claimed: Media3 can
 * hand a processor its own (empty) output buffer as input.
 */
@OptIn(UnstableApi::class)
class GainProcessor(private val gain: Gain) : BaseAudioProcessor() {
  private var framesSinceFlush = 0L
  private var startUs = 0L
  private var limiter: Limiter? = null
  private var samples = FloatArray(0)

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
    limiter = if (gain.volume > 1f) {
      Limiter(inputAudioFormat.channelCount, inputAudioFormat.sampleRate, ceiling = 1f)
    } else {
      null
    }
  }

  override fun queueInput(inputBuffer: ByteBuffer) {
    val format = inputAudioFormat
    val input = inputBuffer.order(ByteOrder.nativeOrder())
    val frames = input.remaining() / format.bytesPerFrame
    val count = frames * format.channelCount
    val isFloat = format.encoding == C.ENCODING_PCM_FLOAT
    if (samples.size < count) samples = FloatArray(count)
    for (i in 0 until count) {
      samples[i] = if (isFloat) input.float else input.short / 32768f
    }

    var i = 0
    for (f in 0 until frames) {
      val g = gain.at(startUs + (framesSinceFlush + f) * 1_000_000L / format.sampleRate)
      repeat(format.channelCount) { samples[i++] *= g }
    }
    limiter?.process(samples, 0, frames)

    val out = replaceOutputBuffer(frames * format.bytesPerFrame).order(ByteOrder.nativeOrder())
    for (k in 0 until count) {
      val v = samples[k].coerceIn(-1f, 1f)
      if (isFloat) out.putFloat(v) else out.putShort((v * Short.MAX_VALUE).toInt().toShort())
    }
    framesSinceFlush += frames
    out.flip()
  }
}
