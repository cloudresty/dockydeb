#!/usr/bin/env bash
#
# DockyDEB image fingerprint.
#
# Measures what is actually inside a built image — the resolved base image
# digest, every installed package with its exact version, and the commit each
# vendored repository was cloned at — and reduces that to a single sha256.
#
# The same fingerprint means the container is the same and there is nothing to
# publish. A different fingerprint means something genuinely changed.
#
# This measures the built artefact on purpose. The previous approach queried
# apt separately and kept the answer in a state file, which could drift away
# from the image it was supposed to describe — and did, for six months.
#
# Usage:
#   image-fingerprint.sh <image-ref> [manifest.json]
#
# Prints the fingerprint on stdout. Writes the full manifest to manifest.json
# when a path is given.

set -euo pipefail

IMAGE="${1:-}"
OUTPUT="${2:-}"

if [[ -z "$IMAGE" ]]; then
    echo "usage: ${0##*/} <image-ref> [manifest.json]" >&2
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKERFILE="$PROJECT_ROOT/Dockerfile"

for tool in docker jq; do
    command -v "$tool" >/dev/null || { echo "required tool not found: $tool" >&2; exit 1; }
done

sha256() {
    if command -v sha256sum >/dev/null; then
        sha256sum | cut -d' ' -f1
    else
        shasum -a 256 | cut -d' ' -f1
    fi
}

in_image() {
    docker run --rm "$IMAGE" "$@"
}

# The base image is read from the Dockerfile so this can never end up
# describing a different Debian release from the one actually built.
base_ref="$(awk '$1 == "FROM" { print $2; exit }' "$DOCKERFILE")"
[[ -n "$base_ref" ]] || { echo "no FROM instruction found in $DOCKERFILE" >&2; exit 1; }

docker pull --quiet "$base_ref" >/dev/null
base_digest="$(docker image inspect "$base_ref" \
    --format '{{ if .RepoDigests }}{{ index .RepoDigests 0 }}{{ end }}')"
base_digest="${base_digest#*@}"
[[ -n "$base_digest" ]] || { echo "could not resolve a digest for $base_ref" >&2; exit 1; }

# Every installed package, not only the ones named in the Dockerfile: a
# security patch to a transitive dependency is exactly the kind of change a
# debugging container exists to carry.
# shellcheck disable=SC2016  # dpkg-query's own format syntax; must not expand here.
packages="$(in_image dpkg-query -W -f '${Package}\t${Version}\n' | LC_ALL=C sort)"
[[ -n "$packages" ]] || { echo "no packages read from $IMAGE" >&2; exit 1; }

repositories=(
    "ohmyzsh:/root/.oh-my-zsh"
    "powerlevel10k:/root/.oh-my-zsh/custom/themes/powerlevel10k"
    "zsh-autosuggestions:/root/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    "zsh-syntax-highlighting:/root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
)

repositories_json='{}'
for entry in "${repositories[@]}"; do
    name="${entry%%:*}"
    path="${entry#*:}"

    if ! sha="$(in_image git -C "$path" rev-parse HEAD 2>/dev/null)" || [[ -z "$sha" ]]; then
        echo "could not read a commit for ${name} at ${path}" >&2
        exit 1
    fi

    repositories_json="$(jq -n --argjson acc "$repositories_json" \
        --arg key "$name" --arg value "$sha" '$acc + {($key): $value}')"
done

manifest="$(jq -n \
    --arg ref "$base_ref" \
    --arg digest "$base_digest" \
    --argjson repositories "$repositories_json" \
    --arg packages "$packages" \
    '{
        base_image: { ref: $ref, digest: $digest },
        git_repositories: $repositories,
        packages: (
            $packages
            | split("\n")
            | map(select(length > 0) | split("\t") | { key: .[0], value: .[1] })
            | from_entries
        )
    }')"

fingerprint="$(printf '%s' "$manifest" | jq -Sc . | sha256)"

if [[ -n "$OUTPUT" ]]; then
    jq -n \
        --arg fingerprint "$fingerprint" \
        --arg last_updated "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --argjson manifest "$manifest" \
        '{ fingerprint: $fingerprint, last_updated: $last_updated } + $manifest' \
        > "$OUTPUT"
fi

printf '%s\n' "$fingerprint"
