#!/usr/bin/env bash
#
# Describes, as markdown bullets, what changed between two DockyDEB fingerprint
# manifests. Feeds the commit message and the release notes, so a release
# always states what is actually in it rather than a fixed blurb.
#
# Usage:
#   fingerprint-diff.sh <previous.json> <current.json> [max-lines]

set -euo pipefail

PREVIOUS="${1:-}"
CURRENT="${2:-}"
MAX_LINES="${3:-30}"

if [[ ! -f "$CURRENT" ]]; then
    echo "usage: ${0##*/} <previous.json> <current.json> [max-lines]" >&2
    exit 2
fi

# A missing or first-run previous manifest is not an error: everything is new.
if [[ ! -f "$PREVIOUS" ]]; then
    PREVIOUS=/dev/null
fi

changes="$(jq -rn \
    --slurpfile previous "$PREVIOUS" \
    --slurpfile current "$CURRENT" '
    ($previous[0] // {}) as $old
    | ($current[0] // {}) as $new
    | ($old.packages // {}) as $old_packages
    | ($new.packages // {}) as $new_packages
    | [
        (
            if ($old.base_image.digest // "") != ($new.base_image.digest // "")
            then "- Base image `\($new.base_image.ref)` rebuilt on a new digest"
            else empty end
        ),
        (
            ($new.git_repositories // {})
            | to_entries[]
            | . as $entry
            | (($old.git_repositories // {})[$entry.key] // "") as $before
            | if $before == "" then
                  "- Repository `\($entry.key)` pinned at `\($entry.value[0:7])`"
              elif $before != $entry.value then
                  "- Repository `\($entry.key)` `\($before[0:7])` → `\($entry.value[0:7])`"
              else empty end
        ),
        (
            $new_packages
            | to_entries[]
            | . as $entry
            | ($old_packages[$entry.key] // "") as $before
            | if $before == "" then
                  "- Package `\($entry.key)` added at `\($entry.value)`"
              elif $before != $entry.value then
                  "- Package `\($entry.key)` `\($before)` → `\($entry.value)`"
              else empty end
        ),
        (
            $old_packages
            | to_entries[]
            | select($new_packages[.key] == null)
            | "- Package `\(.key)` removed (was `\(.value)`)"
        )
      ]
    | .[]
')"

if [[ -z "$changes" ]]; then
    echo "- No component changes detected."
    exit 0
fi

total="$(printf '%s\n' "$changes" | wc -l | tr -d ' ')"

if (( total > MAX_LINES )); then
    printf '%s\n' "$changes" | head -n "$MAX_LINES"
    printf -- '- …and %d further component change(s).\n' "$(( total - MAX_LINES ))"
else
    printf '%s\n' "$changes"
fi
