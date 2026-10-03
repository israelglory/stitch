// name: Brightness fade
// category: basic
// description: Bright parts of the picture change first, dark parts last.

vec4 transition(vec2 uv) {
  vec4 a = getFromColor(uv);
  vec4 b = getToColor(uv);
  float l = 1.0 - dot(a.rgb, vec3(0.299, 0.587, 0.114));
  float t = smoothstep(l - 0.1, l + 0.1, progress * 1.2 - 0.1);
  return mix(a, b, t);
}
