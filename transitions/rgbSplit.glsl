// name: Color split
// category: glitch
// description: Red and blue drift apart and come back together.

vec4 pick(vec2 p) {
  return mix(getFromColor(p), getToColor(p), smoothstep(0.4, 0.6, progress));
}

vec4 transition(vec2 uv) {
  float offset = 0.03 * sin(progress * 3.14159265);
  float r = pick(vec2(clamp(uv.x + offset, 0.0, 1.0), uv.y)).r;
  vec4 g = pick(uv);
  float b = pick(vec2(clamp(uv.x - offset, 0.0, 1.0), uv.y)).b;
  return vec4(r, g.g, b, 1.0);
}
