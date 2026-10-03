// name: Wave
// category: fun
// description: The picture sways in a wave as it changes.
// tolerance: 0.06

vec4 transition(vec2 uv) {
  float x = uv.x + sin(uv.y * 12.0 + progress * 10.0) * 0.04 * sin(progress * 3.14159265);
  vec2 q = vec2(clamp(x, 0.0, 1.0), uv.y);
  return mix(getFromColor(q), getToColor(q), smoothstep(0.3, 0.7, progress));
}
