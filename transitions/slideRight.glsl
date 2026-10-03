// name: Slide right
// category: slide
// description: Both clips move right together.

vec4 transition(vec2 uv) {
  return uv.x >= progress
    ? getFromColor(vec2(uv.x - progress, uv.y))
    : getToColor(vec2(uv.x + (1.0 - progress), uv.y));
}
