package xyz.gloryolaifa.stitch.engine

/**
 * The transitions, as GLSL in the style of gl-transitions
 * (https://gl-transitions.com, MIT): a color from the outgoing frame
 * (`getFromColor`), the incoming frame (`getToColor`), and linear
 * progress. uv is 0 to 1 with y up.
 *
 * The looks are defined in docs/engine.md and mirrored in
 * ios/Runner/Engine/Transitions.metal; test_media/transition_cases.json
 * holds the colors both platforms are tested against.
 */
object TransitionShader {
  /** Type names from the document, in the order of [GLSL]'s type numbers. */
  private val TYPES = listOf(
    "crossfade",
    "fadeToBlack",
    "slideLeft",
    "slideRight",
    "wipeLeft",
    "wipeRight",
    "zoomIn",
  )

  /** 1-based number for [type]; unknown types crossfade. */
  fun typeIndex(type: String): Int = TYPES.indexOf(type).let { if (it < 0) 1 else it + 1 }

  const val GLSL = """
vec4 transition(vec2 uv, float p, int type) {
  vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
  if (type == 2) {
    // Fade to black: out through black, darkest halfway.
    return p < 0.5
      ? mix(getFromColor(uv), black, p * 2.0)
      : mix(black, getToColor(uv), p * 2.0 - 1.0);
  }
  if (type == 3) {
    // Slide left: both frames move left by p.
    return uv.x < 1.0 - p
      ? getFromColor(vec2(uv.x + p, uv.y))
      : getToColor(vec2(uv.x - (1.0 - p), uv.y));
  }
  if (type == 4) {
    // Slide right: both frames move right by p.
    return uv.x >= p
      ? getFromColor(vec2(uv.x - p, uv.y))
      : getToColor(vec2(uv.x + (1.0 - p), uv.y));
  }
  if (type == 5) {
    // Wipe left: the incoming frame is revealed from the right edge.
    return uv.x >= 1.0 - p ? getToColor(uv) : getFromColor(uv);
  }
  if (type == 6) {
    // Wipe right: the incoming frame is revealed from the left edge.
    return uv.x < p ? getToColor(uv) : getFromColor(uv);
  }
  if (type == 7) {
    // Zoom in: the outgoing frame grows by up to 60 percent as it fades.
    vec4 from = getFromColor((uv - 0.5) / (1.0 + 0.6 * p) + 0.5);
    return mix(from, getToColor(uv), p);
  }
  // Crossfade.
  return mix(getFromColor(uv), getToColor(uv), p);
}
"""
}
