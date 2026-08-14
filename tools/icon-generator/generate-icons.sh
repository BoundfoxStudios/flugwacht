#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ -z "${FLUGWACHT_ICONS_CONTAINER:-}" ]; then
  if ! command -v docker >/dev/null; then
    echo "docker is required" >&2
    exit 1
  fi
  docker build --quiet --file "$repository_root/tools/icon-generator/icons.dockerfile" \
    --tag flugwacht-icons "$repository_root/tools/icon-generator" >/dev/null
  exec docker run --rm --user "$(id -u):$(id -g)" \
    --env FLUGWACHT_ICONS_CONTAINER=1 \
    --volume "$repository_root:/workspace" \
    --workdir /workspace \
    flugwacht-icons tools/icon-generator/generate-icons.sh
fi

masters="$repository_root/assets/icon"
staging="$repository_root/assets/icon/generated"
ios_icon_set="$repository_root/app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
android_resources="$repository_root/app/android/app/src/main/res"

render() {
  local master="$1" size="$2" target="$3"
  mkdir -p "$(dirname "$target")"
  rsvg-convert --width "$size" --height "$size" --output "$target" "$masters/$master"
}

render tile.svg 1024 "$staging/ios/app-icon-1024.png"
render ios-dark.svg 1024 "$staging/ios/app-icon-1024-dark.png"
render ios-tinted.svg 1024 "$staging/ios/app-icon-1024-tinted.png"
python3 "$repository_root/tools/icon-generator/strip_png_alpha.py" \
  "$staging/ios/app-icon-1024.png" \
  "$staging/ios/app-icon-1024-tinted.png"

for density_and_sizes in mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432; do
  density="${density_and_sizes%%:*}"
  sizes="${density_and_sizes#*:}"
  legacy_size="${sizes%%:*}"
  adaptive_size="${sizes#*:}"
  render android-legacy.svg "$legacy_size" "$staging/android/mipmap-$density/ic_launcher.png"
  render android-foreground.svg "$adaptive_size" "$staging/android/mipmap-$density/ic_launcher_foreground.png"
  render android-monochrome.svg "$adaptive_size" "$staging/android/mipmap-$density/ic_launcher_monochrome.png"
done

render tile.svg 512 "$staging/store/play-store-512.png"

cp "$staging/ios/"*.png "$ios_icon_set/"
for density_directory in "$staging/android/"mipmap-*; do
  mkdir -p "$android_resources/$(basename "$density_directory")"
  cp "$density_directory/"*.png "$android_resources/$(basename "$density_directory")/"
done
