// name: Split vertical
// category: wipe
// description: The incoming clip opens from a line across the middle.

vec4 transition(vec2 uv) {
  return abs(uv.y - 0.5) < progress * 0.5 ? getToColor(uv) : getFromColor(uv);
}
