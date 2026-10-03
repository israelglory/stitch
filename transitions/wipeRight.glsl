// name: Wipe right
// category: wipe
// description: The incoming clip is revealed from the left edge.

vec4 transition(vec2 uv) {
  return uv.x < progress ? getToColor(uv) : getFromColor(uv);
}
