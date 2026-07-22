#!/bin/bash

set -euo pipefail

version="${1:-}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
  echo "Version must use the form 1.0 or 1.2.3." >&2
  exit 1
fi

export CONTENTCAM_MARKETING_VERSION="$version"
/usr/bin/perl -0pi -e 's/MARKETING_VERSION = [0-9]+\.[0-9]+(?:\.[0-9]+)?;/MARKETING_VERSION = $ENV{CONTENTCAM_MARKETING_VERSION};/g' ContentCam.xcodeproj/project.pbxproj
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" ContentCam/Info.plist

echo "ContentCam marketing version is now $version."
