// name: Punch zoom
// category: zoom
// description: Zooms deep into the outgoing clip and out of the incoming one.

vec4 transition(vec2 uv) {
  if (progress < 0.5) {
    return getFromColor((uv - vec2(0.5)) / (1.0 + progress * 4.0) + vec2(0.5));
  }
  return getToColor((uv - vec2(0.5)) / (1.0 + (1.0 - progress) * 4.0) + vec2(0.5));
}
