// name: Zoom blur
// category: zoom
// description: A burst of zoom blur carries one clip into the other.
// tolerance: 0.06

#define SAMPLES 12

vec4 transition(vec2 uv) {
  float strength = sin(progress * 3.14159265) * 0.3;
  vec2 dir = uv - vec2(0.5);
  vec4 a = vec4(0.0);
  vec4 b = vec4(0.0);
  for (int i = 0; i < SAMPLES; i++) {
    vec2 q = vec2(0.5) + dir * (1.0 - strength * float(i) / float(SAMPLES));
    a += getFromColor(q);
    b += getToColor(q);
  }
  return mix(a / float(SAMPLES), b / float(SAMPLES), smoothstep(0.3, 0.7, progress));
}
