// name: Burn
// category: light
// description: The picture overexposes to near white, then settles on the incoming clip.

vec4 transition(vec2 uv) {
  float k = sin(progress * 3.14159265);
  vec4 c = mix(getFromColor(uv), getToColor(uv), smoothstep(0.4, 0.6, progress));
  vec3 burned = c.rgb * (1.0 + k * 3.0) + vec3(k * 0.2);
  return vec4(min(burned, vec3(1.0)), 1.0);
}
