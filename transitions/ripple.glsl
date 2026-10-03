// name: Ripple
// category: fun
// description: Ripples spread through the picture as it changes.
// tolerance: 0.06

vec4 transition(vec2 uv) {
  vec2 d = uv - vec2(0.5);
  d.x *= ratio;
  float dist = length(d);
  vec2 dir = dist > 0.0001 ? d / dist : vec2(0.0);
  vec2 off = dir * sin(dist * 40.0 - progress * 20.0) * sin(progress * 3.14159265) * 0.03;
  off.x /= ratio;
  vec2 q = clamp(uv + off, vec2(0.0), vec2(1.0));
  return mix(getFromColor(q), getToColor(q), smoothstep(0.3, 0.7, progress));
}
