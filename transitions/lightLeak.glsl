// name: Light leak
// category: light
// description: A warm glow of light sweeps across the cut.

vec4 transition(vec2 uv) {
  vec4 c = mix(getFromColor(uv), getToColor(uv), smoothstep(0.35, 0.65, progress));
  float x = (uv.x + uv.y * 0.3 - mix(-0.3, 1.6, progress)) * 3.0;
  float glow = exp(-x * x) * sin(progress * 3.14159265);
  vec3 leak = vec3(1.0, 0.6, 0.25) * glow;
  return vec4(vec3(1.0) - (vec3(1.0) - c.rgb) * (vec3(1.0) - leak), 1.0);
}
