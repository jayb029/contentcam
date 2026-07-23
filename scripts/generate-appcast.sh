#!/bin/bash

set -euo pipefail

archive_directory="${1:-}"
output_file="${2:-}"
download_url_prefix="${3:-}"
full_release_notes_url="${4:-}"

if [[ -z "$archive_directory" || -z "$output_file" || -z "$download_url_prefix" ]]; then
  echo "Usage: generate-appcast <archive-directory> <output-file> <download-url-prefix>" >&2
  exit 1
fi

if [[ -z "${SPARKLE_PRIVATE_KEY:-}" ]]; then
  echo "SPARKLE_PRIVATE_KEY is required to sign app updates." >&2
  exit 1
fi

generate_appcast="${SPARKLE_GENERATE_APPCAST:-}"

if [[ -z "$generate_appcast" ]]; then
  generate_appcast="$(find build/DerivedData/SourcePackages/artifacts -type f -name generate_appcast -perm -111 -print -quit)"
fi

if [[ -z "$generate_appcast" || ! -x "$generate_appcast" ]]; then
  echo "Sparkle's generate_appcast tool was not found after the release build." >&2
  exit 1
fi

appcast_arguments=(
  --ed-key-file -
  --download-url-prefix "$download_url_prefix"
  --embed-release-notes
  --maximum-versions 1
  --maximum-deltas 0
  -o "$output_file"
)

if [[ -n "$full_release_notes_url" ]]; then
  appcast_arguments+=(--full-release-notes-url "$full_release_notes_url")
fi

printf '%s' "$SPARKLE_PRIVATE_KEY" | "$generate_appcast" \
  "${appcast_arguments[@]}" \
  "$archive_directory"

echo "Generated signed update feed at $output_file"
