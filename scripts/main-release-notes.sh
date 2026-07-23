#!/bin/bash

set -euo pipefail

version="${1:-}"
build_number="${2:-}"
commit_sha="${3:-}"
repository_url="${4:-}"

if [[ -z "$version" || -z "$build_number" || -z "$commit_sha" || -z "$repository_url" ]]; then
  echo "Usage: main-release-notes <version> <build> <commit> <repository-url>" >&2
  exit 1
fi

short_sha="${commit_sha:0:7}"

printf '%s\n' \
  "ContentCam ${version} is a native macOS camera studio for creating a clean, content-ready camera feed for OBS, meetings, streams, and vertical video. All camera processing stays on your Mac." \
  "" \
  "## Download and install" \
  "" \
  "1. Download **ContentCam-${version}-${build_number}.dmg** below." \
  "2. Open the DMG and drag **ContentCam** onto the **Applications** shortcut." \
  "3. Open ContentCam from Applications and allow camera access when macOS asks." \
  "4. If Gatekeeper blocks the first launch, Control-click ContentCam, choose **Open**, then confirm. This build is not yet notarized." \
  "" \
  "## What ContentCam includes" \
  "" \
  "- Landscape (16:9), vertical (9:16), and square (1:1) output layouts" \
  "- Mirrored preview and composition guides" \
  "- Local face blur and pixelation using Apple Vision" \
  "- Tracked cat, dog, and bear privacy covers" \
  "- Rounded transparent output designed for OBS window capture" \
  "- No accounts, uploads, or analytics; Sparkle only contacts GitHub to retrieve signed app updates" \
  "" \
  "## Compatibility and build" \
  "" \
  "- **Requires:** macOS 14 or newer" \
  "- **Architectures:** Apple Silicon and Intel" \
  "- **Version:** ${version} (${build_number})" \
  "- **Source:** [${short_sha}](${repository_url}/commit/${commit_sha})" \
  "" \
  "## Privacy" \
  "" \
  "ContentCam processes camera frames locally with AVFoundation, Core Image, and Vision. It does not record, upload, or transmit your video." \
  "" \
  "GitHub's generated change list for this version appears below."
