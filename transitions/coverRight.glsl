// name: Cover right
// category: slide
// description: The incoming clip slides in from the left over the outgoing one.

vec4 transition(vec2 uv) {
  return uv.x < progress
    ? getToColor(vec2(uv.x + (1.0 - progress), uv.y))
    : getFromColor(uv);
}
