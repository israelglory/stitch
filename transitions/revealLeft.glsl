// name: Reveal left
// category: slide
// description: The outgoing clip slides away to the left, uncovering the incoming one.

vec4 transition(vec2 uv) {
  return uv.x < 1.0 - progress
    ? getFromColor(vec2(uv.x + progress, uv.y))
    : getToColor(uv);
}
