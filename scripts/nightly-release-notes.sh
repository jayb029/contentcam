#!/bin/bash

set -euo pipefail

version="${1:-}"
build_number="${2:-}"
commit_sha="${3:-}"
branch_name="${4:-}"
repository_url="${5:-}"
comparison_label="${6:-}"

if [[ -z "$version" || -z "$build_number" || -z "$commit_sha" || -z "$branch_name" || -z "$repository_url" || -z "$comparison_label" ]]; then
  echo "Usage: nightly-release-notes <version> <build> <commit> <branch> <repository-url> <comparison-label>" >&2
  exit 1
fi

short_sha="${commit_sha:0:7}"

printf '%s\n' \
  "This Nightly is an automated preview of ContentCam changes that have not shipped in a Production release yet. It is intended for testing and may be less stable." \
  "" \
  "## Download and install" \
  "" \
  "1. Download **ContentCam-${version}-${build_number}.dmg** below." \
  "2. Open the DMG and drag **ContentCam** onto the **Applications** shortcut." \
  "3. Open ContentCam from Applications and allow camera access when macOS asks." \
  "4. If Gatekeeper blocks the first launch, Control-click ContentCam, choose **Open**, then confirm. This build is not yet notarized." \
  "" \
  "## Nightly build details" \
  "" \
  "- **Source branch:** \`${branch_name}\`" \
  "- **Version:** ${version} (${build_number})" \
  "- **Source:** [${short_sha}](${repository_url}/commit/${commit_sha})" \
  "- **Compared with:** ${comparison_label}" \
  "" \
  "## What ContentCam includes" \
  "" \
  "- Landscape (16:9), vertical (9:16), and square (1:1) output layouts" \
  "- Mirrored preview and composition guides" \
  "- Local face blur and pixelation using Apple Vision" \
  "- Tracked cat, dog, and bear privacy covers" \
  "- Rounded transparent output designed for OBS window capture" \
  "- No accounts, uploads, or analytics" \
  "" \
  "## Compatibility and privacy" \
  "" \
  "- **Requires:** macOS 14 or newer" \
  "- **Architectures:** Apple Silicon and Intel" \
  "" \
  "ContentCam processes camera frames locally with AVFoundation, Core Image, and Vision. It does not record, upload, or transmit your video."
