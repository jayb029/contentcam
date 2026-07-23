#!/bin/bash

set -euo pipefail

release_name="${1:-}"
commit_changelog_file="${2:-}"
full_changelog_url="${3:-}"

if [[ -z "$release_name" || -z "$commit_changelog_file" || -z "$full_changelog_url" ]]; then
  echo "Usage: in-app-release-notes <release-name> <commit-changelog-file> <full-changelog-url>" >&2
  exit 1
fi

if [[ ! -f "$commit_changelog_file" ]]; then
  echo "Commit changelog file ${commit_changelog_file} does not exist." >&2
  exit 1
fi

printf '%s\n\n' \
  "${release_name} is a native macOS camera studio for creating a clean, content-ready camera feed for OBS, meetings, streams, and vertical video. All camera processing stays on your Mac."

cat "$commit_changelog_file"

printf '\n[View the full changelog](%s)\n' "$full_changelog_url"
