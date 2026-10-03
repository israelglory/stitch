#!/bin/sh
# Compiles every transition's Metal on this Mac: a quick check after
# editing transitions/*.glsl and running tool/gen_transitions.dart.
set -e
cd "$(dirname "$0")/.."
out=$(mktemp -d)
swiftc -O -o "$out/check" \
  ios/Runner/Engine/TransitionSources.swift \
  ios/Runner/Engine/Transitions.swift \
  tool/metal_check/main.swift
"$out/check"
