// name: Swirl
// category: zoom
// description: The picture twists into a swirl and out again.
// tolerance: 0.06

vec4 transition(vec2 uv) {
  float strength = sin(progress * 3.14159265) * 6.0;
  vec2 d = uv - vec2(0.5);
  d.x *= ratio;
  float a = strength * max(0.0, 0.5 - length(d));
  float c = cos(a);
  float s = sin(a);
  vec2 q = vec2(c * d.x - s * d.y, s * d.x + c * d.y);
  q.x /= ratio;
  q = clamp(q + vec2(0.5), vec2(0.0), vec2(1.0));
  return mix(getFromColor(q), getToColor(q), smoothstep(0.3, 0.7, progress));
}
