// name: Checkerboard
// category: shape
// description: Half the squares of a checkerboard change, then the other half.

#define GRID 8.0

vec4 transition(vec2 uv) {
  vec2 cell = floor(uv * vec2(GRID * ratio, GRID));
  float odd = mod(cell.x + cell.y, 2.0);
  float t = clamp(progress * 2.0 - odd, 0.0, 1.0);
  return mix(getFromColor(uv), getToColor(uv), t);
}
