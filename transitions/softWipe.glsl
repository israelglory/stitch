// name: Soft wipe
// category: wipe
// description: A soft diagonal edge sweeps from the bottom left corner.

#define SOFTNESS 0.15

vec4 transition(vec2 uv) {
  float d = (uv.x + uv.y) * 0.5;
  float edge = progress * (1.0 + SOFTNESS);
  float t = 1.0 - smoothstep(edge - SOFTNESS, edge, d);
  return mix(getFromColor(uv), getToColor(uv), t);
}
