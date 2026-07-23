#!/bin/bash

set -euo pipefail

app_path="${1:-}"
output_path="${2:-}"

if [[ ! -d "$app_path" || "$app_path" != *.app ]]; then
  echo "The first argument must be a built .app bundle." >&2
  exit 1
fi

if [[ -z "$output_path" || "$output_path" != *.dmg ]]; then
  echo "The second argument must be a .dmg output path." >&2
  exit 1
fi

volume_name="ContentCam Installer"
work_directory="$PWD/build/dmg"
staging_directory="$work_directory/staging"
background_directory="$staging_directory/.background"
read_write_image="$work_directory/ContentCam-rw.dmg"
background_path="$background_directory/background.png"
renderer_path="$work_directory/render-dmg-background"
device=""

cleanup() {
  if [[ -n "$device" ]]; then
    hdiutil detach "$device" -quiet || hdiutil detach "$device" -force -quiet || true
  fi
}

trap cleanup EXIT

rm -rf "$work_directory" "$output_path"
mkdir -p "$background_directory" "$(dirname "$output_path")"
cp -R "$app_path" "$staging_directory/ContentCam.app"
ln -s /Applications "$staging_directory/Applications"

xcrun swiftc \
  -module-cache-path "$work_directory/SwiftModuleCache" \
  scripts/render-dmg-background.swift \
  -o "$renderer_path"
"$renderer_path" "$background_path"

chmod -Rf go-w "$staging_directory"
hdiutil create \
  -volname "$volume_name" \
  -srcfolder "$staging_directory" \
  -ov \
  -format UDRW \
  "$read_write_image" \
  -quiet

attach_output="$(hdiutil attach \
  "$read_write_image" \
  -readwrite \
  -noverify \
  -noautoopen)"
device="$(awk '/\/Volumes\// { print $1 }' <<< "$attach_output" | tail -n 1)"

if [[ -z "$device" ]]; then
  echo "Unable to determine the mounted DMG device." >&2
  exit 1
fi

layout_succeeded=false
for attempt in 1 2 3; do
  if osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$volume_name"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set pathbar visible of container window to false
    set the bounds of container window to {120, 120, 840, 560}

    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 112
    set text size of viewOptions to 14
    set background picture of viewOptions to file ".background:background.png"

    set position of item "ContentCam.app" of container window to {190, 230}
    set position of item "Applications" of container window to {530, 230}

    close
    open
    update without registering applications
    delay 2
  end tell
end tell
APPLESCRIPT
  then
    layout_succeeded=true
    break
  fi
  sleep 2
done

if [[ "$layout_succeeded" != true ]]; then
  echo "Unable to apply the Finder layout to the DMG." >&2
  exit 1
fi

sync
hdiutil detach "$device" -quiet
device=""

hdiutil convert \
  "$read_write_image" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$output_path" \
  -quiet

echo "Created $output_path"
