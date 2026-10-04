#!/bin/sh
# Uploads the sound library built by tool/sound_catalog/build.dart to the
# Internet Archive item stitch-sound-library. Needs the `ia` tool configured
# with upload keys (~/.config/internetarchive/ia.ini). Files already there
# with the same checksum are skipped, so it can be rerun after changes.
set -e
cd "$(dirname "$0")/../.."
IA="${IA:-ia}"
ITEM=stitch-sound-library
OUT=build/sound_catalog/out

if [ ! -f "$OUT/catalog.json" ]; then
  echo "Build first: dart run tool/sound_catalog/build.dart" >&2
  exit 1
fi

cd "$OUT"
"$IA" upload "$ITEM" music effects previews catalog.json \
  --checksum \
  --retries 10 \
  --sleep 30 \
  --metadata="mediatype:audio" \
  --metadata="collection:opensource_audio" \
  --metadata="title:Stitch sound library" \
  --metadata="creator:Stitch" \
  --metadata="licenseurl:http://creativecommons.org/publicdomain/zero/1.0/" \
  --metadata="subject:sound effects;music;cc0;public domain;video editing" \
  --metadata="description:Music and sound effects for the Stitch video editor (open source, GPL-3.0). Every file is dedicated to the public domain under CC0 1.0. Sources: Komiku and Loyalty Freak Music (archive.org), Kenney (kenney.nl), and Freesound users (freesound.org); catalog.json lists each sound's source page. Re-encoded to AAC with even loudness."

echo "Published: https://archive.org/details/$ITEM"
