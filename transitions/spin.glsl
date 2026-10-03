// name: Spin
// category: zoom
// description: The outgoing clip spins away into the middle.
// tolerance: 0.06

#define PI 3.14159265

vec2 turn(vec2 v, float a) {
  float c = cos(a);
  float s = sin(a);
  return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

vec4 transition(vec2 uv) {
  vec4 to = getToColor(uv);
  float scale = 1.0 - progress;
  if (scale < 0.001) return to;
  vec2 d = uv - vec2(0.5);
  d.x *= ratio;
  vec2 q = turn(d, -progress * PI) / scale;
  q.x /= ratio;
  q += vec2(0.5);
  if (q.x < 0.0 || q.x > 1.0 || q.y < 0.0 || q.y > 1.0) return to;
  return mix(getFromColor(q), to, progress * progress);
}
