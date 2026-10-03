// name: Fade to white
// category: basic
// description: Fades out to white, then in from white.

vec4 transition(vec2 uv) {
  vec4 white = vec4(1.0, 1.0, 1.0, 1.0);
  return progress < 0.5
    ? mix(getFromColor(uv), white, progress * 2.0)
    : mix(white, getToColor(uv), progress * 2.0 - 1.0);
}
