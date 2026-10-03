// name: Heart
// category: shape
// description: The incoming clip opens as a growing heart.

bool inHeart(vec2 p) {
  float a = p.x * p.x + p.y * p.y - 1.0;
  return a * a * a - p.x * p.x * p.y * p.y * p.y <= 0.0;
}

vec4 transition(vec2 uv) {
  if (progress >= 0.999) return getToColor(uv);
  // Grows slowly at first so the shape shows; 1.5 covers every corner, in
  // portrait and landscape.
  float s = progress * progress * 1.5;
  if (s < 0.0001) return getFromColor(uv);
  vec2 d = uv - vec2(0.5);
  d.x *= ratio;
  return inHeart(d / s) ? getToColor(uv) : getFromColor(uv);
}
