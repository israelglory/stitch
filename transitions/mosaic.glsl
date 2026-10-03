// name: Mosaic
// category: glitch
// description: Tiles of the incoming clip appear in random order.
// tolerance: 0.08

float hash(vec2 p) {
  vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
  p3 += dot(p3, vec3(p3.y, p3.z, p3.x) + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

#define GRID 6.0

vec4 transition(vec2 uv) {
  float order = hash(floor(uv * vec2(GRID * ratio, GRID)) + vec2(3.0, 5.0));
  return progress > order ? getToColor(uv) : getFromColor(uv);
}
