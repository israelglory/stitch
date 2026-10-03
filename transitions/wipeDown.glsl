// name: Wipe down
// category: wipe
// description: The incoming clip is revealed from the top edge.

vec4 transition(vec2 uv) {
  return uv.y >= 1.0 - progress ? getToColor(uv) : getFromColor(uv);
}
