// name: Stripes
// category: wipe
// description: Diagonal stripes fill in one after another.

#define BANDS 8.0

vec4 transition(vec2 uv) {
  float s = (uv.x + uv.y) * 0.5 * BANDS;
  float delay = floor(s) / BANDS * 0.5;
  float local = clamp((progress - delay) / 0.5, 0.0, 1.0);
  return fract(s) < local ? getToColor(uv) : getFromColor(uv);
}
