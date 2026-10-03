// name: Crossfade
// category: basic
// description: The incoming clip fades in over the outgoing one.

vec4 transition(vec2 uv) {
  return mix(getFromColor(uv), getToColor(uv), progress);
}
