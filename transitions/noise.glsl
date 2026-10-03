// name: Static
// category: glitch
// description: A burst of TV static covers the cut.
// tolerance: 0.1

float hash(vec2 p) {
  vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
  p3 += dot(p3, vec3(p3.y, p3.z, p3.x) + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec4 transition(vec2 uv) {
  vec4 c = progress < 0.5 ? getFromColor(uv) : getToColor(uv);
  float k = sin(progress * 3.14159265);
  float n = hash(floor(uv * vec2(180.0 * ratio, 180.0)) + floor(progress * 30.0) * vec2(13.0, 7.0));
  return mix(c, vec4(n, n, n, 1.0), k * k * 0.85);
}
