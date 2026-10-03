// name: Flash
// category: light
// description: A bright white flash covers the cut.

vec4 transition(vec2 uv) {
  vec4 c = progress < 0.5 ? getFromColor(uv) : getToColor(uv);
  float f = 1.0 - abs(progress - 0.5) * 2.0;
  return mix(c, vec4(1.0), f * f * f);
}
