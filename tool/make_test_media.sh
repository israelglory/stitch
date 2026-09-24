#!/bin/sh
# Regenerates the small media corpus in test_media/ used by the native
# engine tests. Requires ffmpeg with libx264, libx265, and libmp3lame.
set -eu
cd "$(dirname "$0")/../test_media"
q="-hide_banner -loglevel error -y"
tone="sine=frequency=440:sample_rate=48000"

# Variable frame rate, like phone video in low light: 30 fps for 2 s,
# then 12 fps for 2 s.
ffmpeg $q -f lavfi -i "testsrc2=size=360x640:rate=30" -f lavfi -i "$tone" -t 4 \
  -vf "select='lt(t,2)+gte(t,2)*not(mod(n,5))*0+gte(t,2)*lt(mod(n,5),2)',setpts='if(lt(N,60),N/30,2+(N-60)/12)/TB'" \
  -fps_mode passthrough -c:v libx264 -pix_fmt yuv420p -c:a aac -ar 48000 -shortest vfr.mp4

# 10-bit HEVC HDR (HLG, BT.2020), as iPhones record.
ffmpeg $q -f lavfi -i "testsrc2=size=540x960:rate=30" -t 3 \
  -c:v libx265 -pix_fmt yuv420p10le -tag:v hvc1 \
  -x265-params "colorprim=bt2020:transfer=arib-std-b67:colormatrix=bt2020nc:log-level=error" \
  -color_primaries bt2020 -color_trc arib-std-b67 -colorspace bt2020nc hevc_hdr.mov

# Portrait video stored landscape with a 90 degree rotation flag: encode
# landscape, then set the display matrix while copying the stream.
ffmpeg $q -f lavfi -i "testsrc2=size=640x360:rate=30" -f lavfi -i "$tone" -t 3 \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest _landscape.mp4
ffmpeg $q -display_rotation 90 -i _landscape.mp4 -c copy rotated_portrait.mp4
rm _landscape.mp4

# Video with no audio track.
ffmpeg $q -f lavfi -i "smptebars=size=360x640:rate=30" -t 3 \
  -c:v libx264 -pix_fmt yuv420p no_audio.mp4

# A long clip (60 s), small and cheap.
ffmpeg $q -f lavfi -i "testsrc2=size=180x320:rate=15" -f lavfi -i "$tone" -t 60 \
  -c:v libx264 -preset veryslow -crf 40 -pix_fmt yuv420p -c:a aac -b:a 32k \
  -shortest long.mp4

# Above 1080p, so it gets a preview proxy.
ffmpeg $q -f lavfi -i "testsrc2=size=1440x2560:rate=30" -t 1 \
  -c:v libx264 -crf 38 -pix_fmt yuv420p large_1440p.mp4

# Audio in the formats and sample rates users bring.
ffmpeg $q -f lavfi -i "sine=frequency=330:sample_rate=44100" -t 3 -c:a aac audio_44k.m4a
ffmpeg $q -f lavfi -i "sine=frequency=550:sample_rate=48000" -t 2 -ac 2 -c:a pcm_s16le audio_48k.wav
ffmpeg $q -f lavfi -i "sine=frequency=262:sample_rate=44100" -t 5 -c:a libmp3lame -b:a 64k music.mp3

# A still photo.
ffmpeg $q -f lavfi -i "testsrc2=size=1200x1600" -frames:v 1 -q:v 5 still.jpg
