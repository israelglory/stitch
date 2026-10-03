// name: Fade to black
// category: basic
// description: Fades out to black, then in from black.

vec4 transition(vec2 uv) {
  vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
  return progress < 0.5
    ? mix(getFromColor(uv), black, progress * 2.0)
    : mix(black, getToColor(uv), progress * 2.0 - 1.0);
}
