// name: Cover left
// category: slide
// description: The incoming clip slides in from the right over the outgoing one.

vec4 transition(vec2 uv) {
  return uv.x >= 1.0 - progress
    ? getToColor(vec2(uv.x - (1.0 - progress), uv.y))
    : getFromColor(uv);
}
