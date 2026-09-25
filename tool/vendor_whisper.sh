#!/bin/sh
# Copies the parts of whisper.cpp that captions need (the CPU backend
# only) into third_party/whisper.cpp. The build hook (hook/build.dart)
# compiles them for each target. Run it again with a new tag to upgrade,
# then run the caption tests.
set -eu
tag="${1:-v1.9.4}"
root="$(cd "$(dirname "$0")/.." && pwd)"
dest="$root/third_party/whisper.cpp"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

curl -sSfL "https://github.com/ggml-org/whisper.cpp/archive/refs/tags/$tag.tar.gz" |
  tar xz -C "$work"
src="$work/whisper.cpp-${tag#v}"

rm -rf "$dest"
mkdir -p "$dest/include" "$dest/src" "$dest/ggml/include" "$dest/ggml/src"
cp "$src/LICENSE" "$dest/"
cp "$src/include/whisper.h" "$dest/include/"
cp "$src/src/whisper.cpp" "$src/src/whisper-arch.h" "$dest/src/"

for h in ggml.h ggml-alloc.h ggml-backend.h ggml-cpp.h ggml-cpu.h ggml-opt.h gguf.h; do
  cp "$src/ggml/include/$h" "$dest/ggml/include/"
done
( cd "$src/ggml/src" && cp ./*.c ./*.cpp ./*.h "$dest/ggml/src/" )

cpu="$dest/ggml/src/ggml-cpu"
mkdir -p "$cpu/arch"
( cd "$src/ggml/src/ggml-cpu" && cp ./*.c ./*.cpp ./*.h "$cpu/" && cp -R amx llamafile "$cpu/" )
cp -R "$src/ggml/src/ggml-cpu/arch/arm" "$src/ggml/src/ggml-cpu/arch/x86" "$cpu/arch/"

version="${tag#v}"
cat > "$dest/ggml/src/ggml-version.h" <<EOF
#pragma once

#define GGML_VERSION "$version"
#define GGML_COMMIT  "$tag"
EOF
echo "$tag" > "$dest/VERSION"
echo "Vendored whisper.cpp $tag into third_party/whisper.cpp"
