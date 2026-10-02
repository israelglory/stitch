package xyz.gloryolaifa.stitch.engine

import kotlin.math.ceil
import kotlin.math.min
import kotlin.math.pow

/**
 * An overlay's look at one moment of its entrance or exit. Mirrors
 * lib/features/text/domain/text_motion.dart; docs/engine.md defines the
 * looks.
 */
data class TextMotion(
  /** Opacity, 0 to 1. */
  val alpha: Double = 1.0,
  /** Vertical offset as a fraction of the canvas height, down. */
  val dy: Double = 0.0,
  /** Multiplies the overlay's own scale. */
  val scale: Double = 1.0,
  /** Fraction of the text shown by a typewriter, 0 to 1. */
  val reveal: Double = 1.0,
) {
  companion object {
    const val SLIDE_DISTANCE = 0.05
    const val SCALE_FROM = 0.6

    /** The motion [tUs] into [overlay]. */
    fun at(overlay: EngineDocument.Overlay, tUs: Long): TextMotion {
      val duration = overlay.endUs - overlay.startUs
      fun phase(span: Long, into: Long) =
        if (span <= 0) 1.0 else (into.toDouble() / span).coerceIn(0.0, 1.0)
      val a = apply(overlay.animationIn.type, phase(overlay.animationIn.durationUs, tUs), true)
      val b = apply(
        overlay.animationOut.type,
        phase(overlay.animationOut.durationUs, duration - tUs),
        false,
      )
      return TextMotion(
        alpha = a.alpha * b.alpha,
        dy = a.dy + b.dy,
        scale = a.scale * b.scale,
        reveal = min(a.reveal, b.reveal),
      )
    }

    private fun apply(type: String, phase: Double, entering: Boolean): TextMotion {
      val e = 1 - (1 - phase).pow(3)
      return when (type) {
        "fade" -> TextMotion(alpha = e)
        "slideUp" -> TextMotion(alpha = e, dy = (1 - e) * SLIDE_DISTANCE * (if (entering) 1 else -1))
        "slideDown" -> TextMotion(alpha = e, dy = (1 - e) * SLIDE_DISTANCE * (if (entering) -1 else 1))
        "scale" -> TextMotion(alpha = e, scale = SCALE_FROM + (1 - SCALE_FROM) * e)
        "typewriter" -> TextMotion(reveal = phase)
        else -> TextMotion()
      }
    }

    /** Which of [count] typewriter frames shows [reveal], or null for none. */
    fun frame(reveal: Double, count: Int): Int? {
      if (count <= 1) return if (reveal > 0) 0 else null
      val shown = ceil(reveal * count).toInt()
      return if (shown <= 0) null else min(shown, count) - 1
    }
  }
}
