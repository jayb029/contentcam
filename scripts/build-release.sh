#!/bin/bash

set -euo pipefail

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' ContentCam/Info.plist)"
build_number="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' ContentCam/Info.plist)"
derived_data_path="$PWD/build/DerivedData"
output_directory="$PWD/build/release"
archive_name="ContentCam-${version}-${build_number}.zip"

rm -rf "$derived_data_path" "$output_directory"
mkdir -p "$output_directory"

xcodebuild \
  -project ContentCam.xcodeproj \
  -scheme ContentCam \
  -configuration Release \
  -derivedDataPath "$derived_data_path" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

/usr/bin/ditto \
  -c \
  -k \
  --sequesterRsrc \
  --keepParent \
  "$derived_data_path/Build/Products/Release/ContentCam.app" \
  "$output_directory/$archive_name"

echo "Built $output_directory/$archive_name"
