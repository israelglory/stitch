// name: Circle open
// category: shape
// description: The incoming clip opens as a growing circle.

vec4 transition(vec2 uv) {
  vec2 d = uv - vec2(0.5);
  d.x *= ratio;
  float r = progress * (length(vec2(0.5 * ratio, 0.5)) + 0.02);
  float t = 1.0 - smoothstep(r - 0.02, r, length(d));
  return mix(getFromColor(uv), getToColor(uv), t);
}
