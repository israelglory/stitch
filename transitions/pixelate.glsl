// name: Pixelate
// category: glitch
// description: The picture breaks into big pixels and back.
// tolerance: 0.06

vec4 transition(vec2 uv) {
  float k = min(progress, 1.0 - progress) * 2.0;
  vec2 block = vec2(k * 0.06 / ratio, k * 0.06);
  vec2 q = uv;
  if (block.y > 0.0005) {
    q = clamp((floor(uv / block) + vec2(0.5)) * block, vec2(0.0), vec2(1.0));
  }
  return progress < 0.5 ? getFromColor(q) : getToColor(q);
}
