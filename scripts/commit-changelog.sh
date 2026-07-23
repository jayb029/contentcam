#!/bin/bash

set -euo pipefail

from_ref="${1:-}"
to_ref="${2:-}"
repository_url="${3:-}"
heading="${4:-}"

if [[ -z "$to_ref" || -z "$repository_url" || -z "$heading" ]]; then
  echo "Usage: commit-changelog [from-ref] <to-ref> <repository-url> <heading>" >&2
  exit 1
fi

if ! git rev-parse --verify --quiet "${to_ref}^{commit}" >/dev/null; then
  echo "Target commit ${to_ref} is not available in the checkout." >&2
  exit 1
fi

if [[ -n "$from_ref" ]]; then
  if ! git rev-parse --verify --quiet "${from_ref}^{commit}" >/dev/null; then
    echo "Comparison commit ${from_ref} is not available in the checkout." >&2
    exit 1
  fi

  if ! git merge-base --is-ancestor "$from_ref" "$to_ref"; then
    echo "Comparison commit ${from_ref} is not an ancestor of ${to_ref}." >&2
    exit 1
  fi

  range="${from_ref}..${to_ref}"
else
  range="$to_ref"
fi

printf '## %s\n\n' "$heading"

commit_count=0
while IFS=$'\t' read -r sha subject; do
  printf -- '- [`%s`](%s/commit/%s) %s\n' \
    "$sha" "$repository_url" "$sha" "$subject"
  commit_count=$((commit_count + 1))
done < <(git log --reverse --format='%H%x09%s' "$range")

if [[ "$commit_count" -eq 0 ]]; then
  echo "- No source commits changed."
fi
