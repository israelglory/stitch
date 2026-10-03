// name: Zoom in
// category: zoom
// description: The outgoing clip grows as it fades out.

vec4 transition(vec2 uv) {
  vec4 grown = getFromColor((uv - vec2(0.5)) / (1.0 + 0.6 * progress) + vec2(0.5));
  return mix(grown, getToColor(uv), progress);
}
