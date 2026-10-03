// name: Dissolve
// category: basic
// description: Small blocks of the incoming clip appear in random order.
// tolerance: 0.08

float hash(vec2 p) {
  vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
  p3 += dot(p3, vec3(p3.y, p3.z, p3.x) + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

#define CELLS 80.0

vec4 transition(vec2 uv) {
  float n = hash(floor(uv * vec2(CELLS * ratio, CELLS)));
  float t = smoothstep(n - 0.05, n + 0.05, progress * 1.1 - 0.05);
  return mix(getFromColor(uv), getToColor(uv), t);
}
