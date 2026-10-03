// name: Wipe left
// category: wipe
// description: The incoming clip is revealed from the right edge.

vec4 transition(vec2 uv) {
  return uv.x >= 1.0 - progress ? getToColor(uv) : getFromColor(uv);
}
