package xyz.gloryolaifa.stitch.engine

import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor.AudioFormat
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.AudioMixer
import androidx.media3.transformer.DefaultAudioMixer
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Media3's mixer, summing in float without clipping, followed by a
 * [Limiter]: loud moments come down smoothly instead of clipping.
 *
 * Media3 asks for 16-bit output, which would clip the sum before any
 * later processing could help; this mixes to float inside and converts
 * after limiting.
 *
 * The limiter's output is [Limiter.lookahead] frames late; the mixer
 * drops that many (silent) frames at the start and lets the limiter's
 * tail out at the end, so the sound stays on time and whole.
 */
@OptIn(UnstableApi::class)
class LimitingAudioMixer private constructor(private val inner: AudioMixer) : AudioMixer by inner {
  private var limiter: Limiter? = null
  private var channels = 2
  private var output: ByteBuffer = ByteBuffer.allocateDirect(0).order(ByteOrder.nativeOrder())
  private var floats = FloatArray(0)
  private var toDrop = 0
  private var flushed = false

  override fun configure(outputAudioFormat: AudioFormat, bufferSizeMs: Int, startTimeUs: Long) {
    channels = outputAudioFormat.channelCount
    val l = Limiter(channels, outputAudioFormat.sampleRate)
    limiter = l
    toDrop = l.lookahead
    flushed = false
    inner.configure(
      AudioFormat(outputAudioFormat.sampleRate, channels, C.ENCODING_PCM_FLOAT),
      bufferSizeMs,
      startTimeUs,
    )
  }

  override fun getOutput(): ByteBuffer {
    // Hand out what is left before mixing more.
    if (output.hasRemaining()) return output
    val l = limiter
    if (inner.isEnded) {
      // The sound still inside the limiter.
      if (flushed || l == null) return output
      flushed = true
      val count = l.lookahead * channels
      if (floats.size < count) floats = FloatArray(count)
      floats.fill(0f, 0, count)
      l.process(floats, 0, l.lookahead)
      return write(0, count)
    }
    val mixed = inner.output.order(ByteOrder.nativeOrder())
    val count = mixed.remaining() / 4
    if (floats.size < count) floats = FloatArray(count)
    mixed.asFloatBuffer().get(floats, 0, count)
    mixed.position(mixed.limit())
    l?.process(floats, 0, count / channels)
    // The limiter's first frames are silence it put there.
    val drop = minOf(toDrop, count / channels)
    toDrop -= drop
    return write(drop * channels, count)
  }

  /** [floats] from [from] to [to], as 16-bit output. */
  private fun write(from: Int, to: Int): ByteBuffer {
    val bytes = (to - from) * 2
    if (output.capacity() < bytes) {
      output = ByteBuffer.allocateDirect(bytes).order(ByteOrder.nativeOrder())
    }
    output.clear()
    for (i in from until to) {
      output.putShort((floats[i].coerceIn(-1f, 1f) * Short.MAX_VALUE).toInt().toShort())
    }
    output.flip()
    return output
  }

  override fun isEnded(): Boolean =
    inner.isEnded && (flushed || limiter == null) && !output.hasRemaining()

  override fun reset() {
    inner.reset()
    limiter = null
    output.clear().flip()
  }

  class Factory : AudioMixer.Factory {
    override fun create(): AudioMixer = LimitingAudioMixer(
      DefaultAudioMixer.Factory(
        /* outputSilenceWithNoSources= */ false,
        /* clipFloatOutput= */ false,
      ).create(),
    )
  }
}
