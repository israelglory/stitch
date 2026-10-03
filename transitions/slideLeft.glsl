// name: Slide left
// category: slide
// description: Both clips move left together.

vec4 transition(vec2 uv) {
  return uv.x < 1.0 - progress
    ? getFromColor(vec2(uv.x + progress, uv.y))
    : getToColor(vec2(uv.x - (1.0 - progress), uv.y));
}
