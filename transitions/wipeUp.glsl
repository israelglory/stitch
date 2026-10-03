// name: Wipe up
// category: wipe
// description: The incoming clip is revealed from the bottom edge.

vec4 transition(vec2 uv) {
  return uv.y < progress ? getToColor(uv) : getFromColor(uv);
}
