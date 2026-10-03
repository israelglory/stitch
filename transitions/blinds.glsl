// name: Blinds
// category: wipe
// description: The incoming clip appears through opening blinds.

#define SLATS 10.0

vec4 transition(vec2 uv) {
  return fract(uv.y * SLATS) < progress ? getToColor(uv) : getFromColor(uv);
}
