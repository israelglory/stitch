// name: Split
// category: wipe
// description: The incoming clip opens from a line down the middle.

vec4 transition(vec2 uv) {
  return abs(uv.x - 0.5) < progress * 0.5 ? getToColor(uv) : getFromColor(uv);
}
