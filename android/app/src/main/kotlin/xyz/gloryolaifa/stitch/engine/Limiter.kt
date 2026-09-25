package xyz.gloryolaifa.stitch.engine

import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min

/**
 * A look-ahead peak limiter for interleaved float samples: no sample goes
 * past [ceiling], and the gain comes down smoothly just before a peak
 * instead of clipping it. Mirrors Limiter.swift.
 *
 * For each frame, the gain it needs is `ceiling / peak` (or 1). The gain
 * applied is the smallest need over the next look-ahead, averaged over the
 * look-ahead before it, so it ramps down over the look-ahead and is never
 * above what the peak needs. It recovers over about [RELEASE_S]. The sound
 * comes out [LOOKAHEAD_S] late.
 */
class Limiter(
  private val channels: Int,
  sampleRate: Int,
  private val ceiling: Float = CEILING,
) {
  private val lookahead = max(1, (sampleRate * LOOKAHEAD_S).toInt())
  private val window = lookahead + 1
  private val release = (1 - exp(-1.0 / (RELEASE_S * sampleRate))).toFloat()

  private val delayed = FloatArray(lookahead * channels)
  private var delayPos = 0

  /** Needed gain per frame, by frame index modulo [window]. */
  private val needed = FloatArray(window) { 1f }

  /** Frame indices with increasing need: the front is the window's minimum. */
  private val queue = LongArray(window)
  private var queueHead = 0
  private var queueSize = 0

  private val held = FloatArray(window) { 1f }
  private var heldSum = window.toDouble()
  private var gain = 1f
  private var frame = 0L

  /** Limits [frames] frames of [samples] from [offset], in place. */
  fun process(samples: FloatArray, offset: Int = 0, frames: Int = (samples.size - offset) / channels) {
    var i = offset
    repeat(frames) {
      var peak = 0f
      for (c in 0 until channels) peak = max(peak, abs(samples[i + c]))
      val need = if (peak > ceiling) ceiling / peak else 1f
      val slot = (frame % window).toInt()
      needed[slot] = need

      while (queueSize > 0 && needed[(queue[back()] % window).toInt()] >= need) queueSize--
      queue[(queueHead + queueSize) % window] = frame
      queueSize++
      while (queue[queueHead] < frame - lookahead) {
        queueHead = (queueHead + 1) % window
        queueSize--
      }
      val hold = needed[(queue[queueHead] % window).toInt()]
      heldSum += hold - held[slot]
      held[slot] = hold
      gain = min((heldSum / window).toFloat(), gain + (1 - gain) * release)

      val d = delayPos * channels
      for (c in 0 until channels) {
        val out = delayed[d + c] * gain
        delayed[d + c] = samples[i + c]
        samples[i + c] = out
      }
      delayPos = (delayPos + 1) % lookahead
      frame++
      i += channels
    }
  }

  private fun back() = (queueHead + queueSize - 1) % window

  companion object {
    /** -1 dBFS: headroom for the encoder. */
    val CEILING = Math.pow(10.0, -1.0 / 20).toFloat()
    const val LOOKAHEAD_S = 0.005
    const val RELEASE_S = 0.1
  }
}
