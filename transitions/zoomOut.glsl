// name: Zoom out
// category: zoom
// description: The incoming clip settles from close up as it fades in.

vec4 transition(vec2 uv) {
  vec4 close = getToColor((uv - vec2(0.5)) / (1.6 - 0.6 * progress) + vec2(0.5));
  return mix(getFromColor(uv), close, progress);
}
