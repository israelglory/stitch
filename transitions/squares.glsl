// name: Squares
// category: shape
// description: Squares grow from the middle outward until they meet.

#define GRID 10.0

vec4 transition(vec2 uv) {
  vec2 cells = vec2(GRID * ratio, GRID);
  vec2 f = fract(uv * cells) - vec2(0.5);
  vec2 c = (floor(uv * cells) + vec2(0.5)) / cells - vec2(0.5);
  c.x *= ratio;
  float delay = length(c) / length(vec2(0.5 * ratio, 0.5)) * 0.5;
  float local = clamp((progress - delay) / 0.5, 0.0, 1.0);
  return max(abs(f.x), abs(f.y)) <= local * 0.5 + 0.001 && local > 0.0
    ? getToColor(uv)
    : getFromColor(uv);
}
