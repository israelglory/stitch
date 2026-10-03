// name: Glitch
// category: glitch
// description: Rows jump and colors split, as on a damaged tape.
// tolerance: 0.08

float hash(vec2 p) {
  vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
  p3 += dot(p3, vec3(p3.y, p3.z, p3.x) + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec4 pick(vec2 p) {
  return progress < 0.5 ? getFromColor(p) : getToColor(p);
}

vec4 transition(vec2 uv) {
  float k = sin(progress * 3.14159265);
  float row = floor(uv.y * 24.0);
  float step12 = floor(progress * 12.0);
  float jump = (hash(vec2(row, step12)) - 0.5) * 0.2 * k;
  float on = step(0.6, hash(vec2(step12, row + 7.0)));
  vec2 q = vec2(clamp(uv.x + jump * on, 0.0, 1.0), uv.y);
  float split = 0.02 * k;
  float r = pick(vec2(clamp(q.x + split, 0.0, 1.0), q.y)).r;
  vec4 g = pick(q);
  float b = pick(vec2(clamp(q.x - split, 0.0, 1.0), q.y)).b;
  return vec4(r, g.g, b, 1.0);
}
