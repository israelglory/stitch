// name: Blur
// category: light
// description: Blurs out of the outgoing clip and into the incoming one.
// tolerance: 0.06

#define TAPS 16
#define GOLDEN 2.39996323

vec4 blurFrom(vec2 uv, float radius) {
  vec4 sum = vec4(0.0);
  for (int i = 0; i < TAPS; i++) {
    float fi = float(i);
    float r = radius * sqrt((fi + 0.5) / float(TAPS));
    vec2 q = uv + vec2(cos(fi * GOLDEN) / ratio, sin(fi * GOLDEN)) * r;
    sum += getFromColor(clamp(q, vec2(0.0), vec2(1.0)));
  }
  return sum / float(TAPS);
}

vec4 blurTo(vec2 uv, float radius) {
  vec4 sum = vec4(0.0);
  for (int i = 0; i < TAPS; i++) {
    float fi = float(i);
    float r = radius * sqrt((fi + 0.5) / float(TAPS));
    vec2 q = uv + vec2(cos(fi * GOLDEN) / ratio, sin(fi * GOLDEN)) * r;
    sum += getToColor(clamp(q, vec2(0.0), vec2(1.0)));
  }
  return sum / float(TAPS);
}

vec4 transition(vec2 uv) {
  float radius = sin(progress * 3.14159265) * 0.04;
  return mix(blurFrom(uv, radius), blurTo(uv, radius), smoothstep(0.4, 0.6, progress));
}
