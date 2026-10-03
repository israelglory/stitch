// name: Bounce
// category: fun
// description: The incoming clip drops in from the top and bounces.

float bounceOut(float t) {
  if (t < 1.0 / 2.75) return 7.5625 * t * t;
  if (t < 2.0 / 2.75) {
    float u = t - 1.5 / 2.75;
    return 7.5625 * u * u + 0.75;
  }
  if (t < 2.5 / 2.75) {
    float u = t - 2.25 / 2.75;
    return 7.5625 * u * u + 0.9375;
  }
  float u = t - 2.625 / 2.75;
  return 7.5625 * u * u + 0.984375;
}

vec4 transition(vec2 uv) {
  float off = 1.0 - bounceOut(progress);
  return uv.y >= off ? getToColor(vec2(uv.x, uv.y - off)) : getFromColor(uv);
}
