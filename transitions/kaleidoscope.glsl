// name: Kaleidoscope
// category: fun
// description: The picture folds into a turning kaleidoscope and back.
// tolerance: 0.08

#define PI 3.14159265
#define SEGMENT 1.04719755

vec4 transition(vec2 uv) {
  float k = sin(progress * PI);
  vec2 d = uv - vec2(0.5);
  d.x *= ratio;
  float r = length(d);
  float a = mod(atan(d.y, d.x) + progress * 2.0, SEGMENT);
  a = abs(a - SEGMENT * 0.5);
  float turn = a + progress * PI;
  vec2 kd = vec2(cos(turn), sin(turn)) * r * (1.0 + k);
  kd.x /= ratio;
  vec2 q = mix(uv, clamp(kd + vec2(0.5), vec2(0.0), vec2(1.0)), k);
  return mix(getFromColor(q), getToColor(q), smoothstep(0.4, 0.6, progress));
}
