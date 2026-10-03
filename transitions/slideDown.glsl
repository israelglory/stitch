// name: Slide down
// category: slide
// description: Both clips move down together.

vec4 transition(vec2 uv) {
  return uv.y < 1.0 - progress
    ? getFromColor(vec2(uv.x, uv.y + progress))
    : getToColor(vec2(uv.x, uv.y - (1.0 - progress)));
}
