package xyz.gloryolaifa.stitch.engine

import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.pow

/**
 * An item's animatable values at one moment. Mirrors `KeyframeValues` in
 * lib/features/timeline/domain/models.dart. Clips read x and y as their
 * offset, overlays as their center; volume is the final gain.
 */
data class KeyframeValues(
  val x: Double = 0.0,
  val y: Double = 0.0,
  val scale: Double = 1.0,
  val rotationDeg: Double = 0.0,
  val opacity: Double = 1.0,
  val volume: Double = 1.0,
) {
  /** Each value [t] (0 to 1) of the way to [to]. */
  fun lerp(to: KeyframeValues, t: Double): KeyframeValues {
    fun mix(a: Double, b: Double) = a + (b - a) * t
    return KeyframeValues(
      mix(x, to.x), mix(y, to.y), mix(scale, to.scale), mix(rotationDeg, to.rotationDeg),
      mix(opacity, to.opacity), mix(volume, to.volume),
    )
  }

  companion object {
    fun decode(o: JSONObject) = KeyframeValues(
      x = o.optDouble("x", 0.0),
      y = o.optDouble("y", 0.0),
      scale = o.optDouble("scale", 1.0),
      rotationDeg = o.optDouble("rotationDeg", 0.0),
      opacity = o.optDouble("opacity", 1.0),
      volume = o.optDouble("volume", 1.0),
    )
  }
}

/** One keyframe, its time on the timeline. */
data class Keyframe(
  val timeUs: Long,
  val values: KeyframeValues,
  /** "linear", "easeIn", "easeOut", "easeInOut", or "hold". */
  val easing: String,
)

/**
 * An item's keyframes, evaluated as `engineValuesAt` in
 * lib/features/timeline/domain/keyframes.dart does (docs/timeline.md,
 * Evaluator contract). A looping item's repeat every [loopUs] from
 * [loopStartUs].
 */
data class Keyframes(
  val list: List<Keyframe>,
  val loopStartUs: Long = 0,
  val loopUs: Long = 0,
) {
  val isEmpty get() = list.isEmpty()

  /** Largest volume any keyframe reaches, or null without keyframes. */
  val maxVolume: Double? = list.maxOfOrNull { it.values.volume }

  /** Values at timeline time [timeUs], or null without keyframes (the item's own apply). */
  fun valuesAt(timeUs: Long): KeyframeValues? {
    if (list.isEmpty()) return null
    val t = local(timeUs)
    if (t <= list.first().timeUs) return list.first().values
    if (t >= list.last().timeUs) return list.last().values
    val i = before(t)
    val a = list[i]
    val b = list[i + 1]
    return a.values.lerp(b.values, progress(a, b, t))
  }

  /**
   * Volume at [timeUs], or null without keyframes. Like [valuesAt] but
   * allocates nothing: it runs for every audio frame.
   */
  fun volumeAt(timeUs: Long): Double? {
    if (list.isEmpty()) return null
    val t = local(timeUs)
    if (t <= list.first().timeUs) return list.first().values.volume
    if (t >= list.last().timeUs) return list.last().values.volume
    val i = before(t)
    val a = list[i]
    val b = list[i + 1]
    return a.values.volume + (b.values.volume - a.values.volume) * progress(a, b, t)
  }

  private fun local(timeUs: Long) =
    if (loopUs > 0 && timeUs >= loopStartUs) loopStartUs + (timeUs - loopStartUs) % loopUs else timeUs

  /** Index of the last keyframe at or before [t], inside the list's span. */
  private fun before(t: Long): Int {
    var lo = 0
    var hi = list.size - 1
    while (hi - lo > 1) {
      val mid = (lo + hi) ushr 1
      if (list[mid].timeUs <= t) lo = mid else hi = mid
    }
    return lo
  }

  private fun progress(a: Keyframe, b: Keyframe, t: Long) =
    ease(a.easing, (t - a.timeUs).toDouble() / (b.timeUs - a.timeUs))

  companion object {
    val NONE = Keyframes(emptyList())

    fun decode(array: JSONArray?, loopStartUs: Long = 0, loopUs: Long = 0): Keyframes {
      if (array == null || array.length() == 0) return NONE
      val list = (0 until array.length()).map {
        val k = array.getJSONObject(it)
        Keyframe(
          timeUs = k.getLong("timeUs"),
          values = KeyframeValues.decode(k.getJSONObject("values")),
          easing = k.optString("easing", "linear"),
        )
      }
      return Keyframes(list, loopStartUs, loopUs)
    }

    /** [p] (0 to 1) shaped by [easing]. Mirrors `easeProgress`. */
    fun ease(easing: String, p: Double): Double = when (easing) {
      "easeIn" -> p * p * p
      "easeOut" -> 1 - (1 - p).pow(3)
      "easeInOut" -> if (p < 0.5) 4 * p * p * p else 1 - (-2 * p + 2).pow(3) / 2
      "hold" -> 0.0
      else -> p
    }
  }
}
