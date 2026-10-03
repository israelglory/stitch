// name: Doorway
// category: fun
// description: The outgoing clip opens like two doors onto the incoming one.

vec4 transition(vec2 uv) {
  float gap = 0.5 * progress;
  if (uv.x < 0.5 - gap) return getFromColor(vec2(uv.x + gap, uv.y));
  if (uv.x > 0.5 + gap) return getFromColor(vec2(uv.x - gap, uv.y));
  float s = 0.8 + 0.2 * progress;
  vec2 q = (uv - vec2(0.5)) / s + vec2(0.5);
  if (q.x < 0.0 || q.x > 1.0 || q.y < 0.0 || q.y > 1.0) return vec4(0.0, 0.0, 0.0, 1.0);
  return getToColor(q);
}
