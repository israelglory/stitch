#!/bin/sh
# Downloads the tiny caption model into .cache/models, where the speech
# recognition tests look for it. The tests that need it skip without it.
set -eu
root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$root/.cache/models"
out="$root/.cache/models/ggml-tiny-q8_0.bin"
sum="c2085835d3f50733e2ff6e4b41ae8a2b8d8110461e18821b09a15c40c42d1cca"
if [ -f "$out" ] && echo "$sum  $out" | shasum -a 256 -c - >/dev/null 2>&1; then
  exit 0
fi
curl -sSfL -o "$out.part" \
  "https://huggingface.co/ggerganov/whisper.cpp/resolve/5359861c739e955e79d9a303bcbc70fb988958b1/ggml-tiny-q8_0.bin"
echo "$sum  $out.part" | shasum -a 256 -c - >/dev/null
mv "$out.part" "$out"
