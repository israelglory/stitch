#!/bin/sh
# Draws the app icon (tool/icon/render_icon_test.dart) and writes every
# size iOS and Android need. Uses sips (macOS).
set -eu
cd "$(dirname "$0")/.."
out="build/icon"
flutter test tool/icon/render_icon_test.dart --dart-define=ICON_OUT="$out" >/dev/null

# iOS: no alpha channel allowed, so each size goes through JPEG and back.
ios="ios/Runner/Assets.xcassets/AppIcon.appiconset"
for spec in 20:1 20:2 20:3 29:1 29:2 29:3 40:1 40:2 40:3 60:2 60:3 76:1 76:2 83.5:2 1024:1; do
  size=${spec%%:*}; scale=${spec##*:}
  px=$(python3 -c "print(round($size*$scale))")
  sips -s format jpeg -s formatOptions 100 -z "$px" "$px" "$out/icon_1024.png" --out "$out/tmp.jpg" >/dev/null
  sips -s format png "$out/tmp.jpg" --out "$ios/Icon-App-${size}x${size}@${scale}x.png" >/dev/null
done

# Android: legacy icons, and the adaptive foreground (background is a color).
for d in mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432; do
  name=${d%%:*}; rest=${d#*:}; legacy=${rest%%:*}; fg=${rest#*:}
  sips -z "$legacy" "$legacy" "$out/icon_1024.png" --out "android/app/src/main/res/mipmap-$name/ic_launcher.png" >/dev/null
  sips -z "$fg" "$fg" "$out/foreground_432.png" --out "android/app/src/main/res/mipmap-$name/ic_launcher_foreground.png" >/dev/null
done
echo "Icons written."
