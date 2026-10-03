// name: Circle close
// category: shape
// description: The outgoing clip closes into a shrinking circle.

vec4 transition(vec2 uv) {
  vec2 d = uv - vec2(0.5);
  d.x *= ratio;
  float r = (1.0 - progress) * (length(vec2(0.5 * ratio, 0.5)) + 0.02);
  float t = smoothstep(r - 0.02, r, length(d));
  return mix(getFromColor(uv), getToColor(uv), t);
}
