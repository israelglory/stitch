// name: Cube
// category: fun
// description: The clips turn like two sides of a cube.
// tolerance: 0.06

#define DEPTH 0.2

vec4 face(vec2 p, float scale, bool incoming) {
  float y = (p.y - 0.5) / scale + 0.5;
  if (y < 0.0 || y > 1.0) return vec4(0.0, 0.0, 0.0, 1.0);
  return incoming ? getToColor(vec2(p.x, y)) : getFromColor(vec2(p.x, y));
}

vec4 transition(vec2 uv) {
  float split = 1.0 - progress;
  if (uv.x < split) {
    float x = uv.x / split;
    return face(vec2(x, uv.y), mix(1.0 - DEPTH * progress, 1.0, x), false);
  }
  float x = (uv.x - split) / max(progress, 0.0001);
  return face(vec2(x, uv.y), mix(1.0, 1.0 - DEPTH * (1.0 - progress), x), true);
}
