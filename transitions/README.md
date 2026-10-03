# Transitions

Each `.glsl` file here is one transition. It is written once and runs everywhere:

- in the Android engine, as GLSL ES 1.00;
- in the iOS engine, as Metal;
- in the Transitions sheet previews, as a Flutter fragment shader.

`tool/gen_transitions.dart` generates the code for each platform. The output is checked in.

## Adding or changing a transition

1. Write or edit `transitions/<id>.glsl`. The id is camelCase; projects store it, so never rename one that has shipped.
2. Add the id to `order.txt` where it should appear in its category.
3. Generate and check:

   ```sh
   dart run tool/gen_transitions.dart        # all generated files
   tool/check_transitions_metal.sh           # compiles the Metal on this Mac
   UPDATE_TRANSITION_REFERENCES=1 flutter test test/features/transitions/transition_references_test.dart
   ```

   The last command renders reference images to `test_media/transitions/`. The Kotlin and Swift engine tests compare exported video to them.

4. Run the engine tests on both platforms (see the README). `everyTransitionCompiles` and `everyTransitionMatchesItsReference` cover every transition.

## The file

```glsl
// name: Circle open
// category: shape
// description: The incoming clip opens as a growing circle.
// tolerance: 0.06

vec4 transition(vec2 uv) {
  ...
}
```

- **name:** the English name. The generator adds it to `lib/l10n/app_en.arb` as `transition<Id>` if missing. It never overwrites names already there.
- **category:** one of `basic`, `slide`, `wipe`, `zoom`, `shape`, `light`, `glitch`, `fun`.
- **description:** what it looks like, for translators.
- **tolerance** (optional): how far an export may differ from the reference images, as the mean difference per channel from 0 to 1. The default is 0.04. Give noisy transitions more.

## What a transition gets

- `uv`: the position on the canvas, 0 to 1, with y up.
- `getFromColor(p)` and `getToColor(p)`: the outgoing and incoming frames at `p`. Each frame is a whole canvas: the clip over its background.
- `progress`: 0 to 1, linear over the transition. It must return exactly the outgoing frame at 0 and the incoming frame at 1, or the cut jumps. The reference test checks both ends.
- `ratio`: canvas width over height, for shapes that should stay round or square.

## Rules

The code must compile as GLSL ES 1.00, Metal, and Flutter's GLSL. The generator rejects most breaches. Metal and Android compile errors show up in `tool/check_transitions_metal.sh` and `everyTransitionCompiles`.

- Use `#define` for constants, not `const`.
- Top-level functions start at the beginning of a line with their return type (`float`, `vec2`, `vec3`, `vec4`, `bool`, `int`, `mat2`). Declare them before use.
- No `in`, `out`, or `inout` parameters. No arrays. No `%`, `round`, or `trunc`. No precision qualifiers.
- No `pow`: it is undefined for negative numbers. Multiply instead.
- Loops need constant bounds: `for (int i = 0; i < N; i++)`.
- Write float literals with a decimal point (`1.0`, not `1`).
- Sample only inside 0 to 1: `clamp` the coordinate, or return black yourself. Platforms disagree about what lies outside.
- Avoid names reserved by Metal or by the hosts: `half`, `kernel`, `sampler`, `texture`, `inside`, `main`, and the rest listed in the generator.
- Every transition samples both frames.
- For noise, use the `hash` in `dissolve.glsl`. Sine-based hashes come out differently on different GPUs.
