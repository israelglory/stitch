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
 */
@OptIn(UnstableApi::class)
class LimitingAudioMixer private constructor(private val inner: AudioMixer) : AudioMixer by inner {
  private var limiter: Limiter? = null
  private var channels = 2
  private var output: ByteBuffer = ByteBuffer.allocateDirect(0).order(ByteOrder.nativeOrder())
  private var floats = FloatArray(0)

  override fun configure(outputAudioFormat: AudioFormat, bufferSizeMs: Int, startTimeUs: Long) {
    channels = outputAudioFormat.channelCount
    limiter = Limiter(channels, outputAudioFormat.sampleRate)
    inner.configure(
      AudioFormat(outputAudioFormat.sampleRate, channels, C.ENCODING_PCM_FLOAT),
      bufferSizeMs,
      startTimeUs,
    )
  }

  override fun getOutput(): ByteBuffer {
    // Hand out what is left before mixing more.
    if (output.hasRemaining()) return output
    val mixed = inner.output.order(ByteOrder.nativeOrder())
    val count = mixed.remaining() / 4
    if (floats.size < count) floats = FloatArray(count)
    mixed.asFloatBuffer().get(floats, 0, count)
    mixed.position(mixed.limit())
    limiter?.process(floats, 0, count / channels)

    if (output.capacity() < count * 2) {
      output = ByteBuffer.allocateDirect(count * 2).order(ByteOrder.nativeOrder())
    }
    output.clear()
    for (i in 0 until count) {
      output.putShort((floats[i].coerceIn(-1f, 1f) * Short.MAX_VALUE).toInt().toShort())
    }
    output.flip()
    return output
  }

  override fun isEnded(): Boolean = inner.isEnded && !output.hasRemaining()

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
