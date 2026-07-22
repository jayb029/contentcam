#!/bin/bash

set -euo pipefail

build_number="${1:-}"

if [[ ! "$build_number" =~ ^[1-9][0-9]*$ ]]; then
  echo "Build number must be a positive integer." >&2
  exit 1
fi

export CONTENTCAM_BUILD_NUMBER="$build_number"
/usr/bin/perl -0pi -e 's/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $ENV{CONTENTCAM_BUILD_NUMBER};/g' ContentCam.xcodeproj/project.pbxproj
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" ContentCam/Info.plist

echo "ContentCam build number is now $build_number."
