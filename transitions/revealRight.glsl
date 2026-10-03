// name: Reveal right
// category: slide
// description: The outgoing clip slides away to the right, uncovering the incoming one.

vec4 transition(vec2 uv) {
  return uv.x >= progress
    ? getFromColor(vec2(uv.x - progress, uv.y))
    : getToColor(uv);
}
