#!/bin/bash

set -euo pipefail

archive_directory="${1:-}"
release_notes_file="${2:-}"

if [[ -z "$archive_directory" || -z "$release_notes_file" ]]; then
  echo "Usage: attach-release-notes <archive-directory> <release-notes-file>" >&2
  exit 1
fi

if [[ ! -f "$release_notes_file" ]]; then
  echo "Release notes file ${release_notes_file} does not exist." >&2
  exit 1
fi

shopt -s nullglob
archives=("$archive_directory"/*.dmg)

if [[ "${#archives[@]}" -ne 1 ]]; then
  echo "Expected exactly one DMG in ${archive_directory}; found ${#archives[@]}." >&2
  exit 1
fi

destination="${archives[0]%.dmg}.md"
cp "$release_notes_file" "$destination"
echo "Attached release notes at $destination"
