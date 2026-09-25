#!/bin/sh
# Builds the app icon from assets/light.png and assets/dark.png
# (tool/icon/render_icon_test.dart) and puts it in place:
#
# - iOS: one 1024 px icon, with dark and tinted variants for iOS 18.
#   Xcode makes the smaller sizes.
# - Android: an adaptive icon (letters over a background color), light by
#   default and dark in night mode, with a monochrome layer for themed
#   icons (Android 13 and later).
#
# Uses sips (macOS).
set -eu
cd "$(dirname "$0")/.."
out="build/icon"
rm -rf "$out"
flutter test tool/icon/render_icon_test.dart --dart-define=ICON_OUT="$out" >/dev/null
read -r light_bg dark_bg < "$out/backgrounds.txt"

# iOS. The App Store rejects an icon with an alpha channel, so each goes
# through JPEG and back.
ios="ios/Runner/Assets.xcassets/AppIcon.appiconset"
rm -f "$ios"/*.png
opaque() {
  sips -s format jpeg -s formatOptions 100 "$1" --out "$out/tmp.jpg" >/dev/null
  sips -s format png "$out/tmp.jpg" --out "$2" >/dev/null
}
opaque "$out/ios_light.png" "$ios/AppIcon.png"
opaque "$out/ios_dark.png" "$ios/AppIcon-dark.png"
# The tinted icon is read as grayscale; the dark artwork already is.
opaque "$out/ios_dark.png" "$ios/AppIcon-tinted.png"
cat > "$ios/Contents.json" <<'JSON'
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "AppIcon-dark.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "tinted"
        }
      ],
      "filename" : "AppIcon-tinted.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

# Android. minSdk is 26, so the adaptive icon is always used.
res="android/app/src/main/res"
for d in mdpi:108 hdpi:162 xhdpi:216 xxhdpi:324 xxxhdpi:432; do
  name=${d%%:*}; px=${d#*:}
  rm -f "$res/mipmap-$name/ic_launcher.png"
  mkdir -p "$res/mipmap-$name" "$res/mipmap-night-$name"
  sips -z "$px" "$px" "$out/android_foreground_light.png" --out "$res/mipmap-$name/ic_launcher_foreground.png" >/dev/null
  sips -z "$px" "$px" "$out/android_foreground_dark.png" --out "$res/mipmap-night-$name/ic_launcher_foreground.png" >/dev/null
  # Themed icons use only the monochrome layer's shape.
  sips -z "$px" "$px" "$out/android_foreground_dark.png" --out "$res/mipmap-$name/ic_launcher_monochrome.png" >/dev/null
done
mkdir -p "$res/values-night"
for pair in "values:$light_bg" "values-night:$dark_bg"; do
  cat > "$res/${pair%%:*}/ic_launcher_background.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Behind the app icon's letters. Made by tool/make_icons.sh. -->
    <color name="ic_launcher_background">${pair#*:}</color>
</resources>
XML
done
cat > "$res/mipmap-anydpi-v26/ic_launcher.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<!-- Adaptive icon: light by default, dark in night mode (mipmap-night and
     values-night). Made by tool/make_icons.sh. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
XML
echo "Icons written (backgrounds $light_bg and $dark_bg)."
