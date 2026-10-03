// name: Slide up
// category: slide
// description: Both clips move up together.

vec4 transition(vec2 uv) {
  return uv.y >= progress
    ? getFromColor(vec2(uv.x, uv.y - progress))
    : getToColor(vec2(uv.x, uv.y + (1.0 - progress)));
}
