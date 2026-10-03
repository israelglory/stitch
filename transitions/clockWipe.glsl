// name: Clock
// category: wipe
// description: The incoming clip sweeps in like a clock hand.

#define PI 3.14159265

vec4 transition(vec2 uv) {
  vec2 d = uv - vec2(0.5);
  d.x *= ratio;
  float a = atan(d.x, d.y);
  if (a < 0.0) a += 2.0 * PI;
  return a / (2.0 * PI) < progress ? getToColor(uv) : getFromColor(uv);
}
