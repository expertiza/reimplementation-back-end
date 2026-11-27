#!/usr/bin/env bash
# Determine GHCR publishing metadata for main and release branches.
set -euo pipefail

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_SHA:?GITHUB_SHA is required}"
: "${GITHUB_REF:?GITHUB_REF is required}"

version=$(tr -d '\r\n' < "${VERSION_FILE:-VERSION}")
if [[ ! "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z][0-9A-Za-z.-]*)?$ ]]; then
  echo '::error::VERSION must use MAJOR.MINOR.PATCH or MAJOR.MINOR.PATCH-prerelease' >&2
  exit 1
fi

image_name=$(printf '%s' "$GITHUB_REPOSITORY" | tr '[:upper:]' '[:lower:]')
sha_tag="sha-${GITHUB_SHA::7}"
release_tag="v${version}"
is_release=false
is_prerelease=false

[[ "$version" != *-* ]] || is_prerelease=true

if [[ "$GITHUB_REF" == refs/heads/release/v* ]]; then
  # Initial release-branch push has no previous version to compare.
  if [[ -n "${BEFORE_SHA:-}" && ! "${BEFORE_SHA}" =~ ^0+$ ]] &&
     git cat-file -e "${BEFORE_SHA}:VERSION" 2>/dev/null; then
    previous_version=$(git show "${BEFORE_SHA}:VERSION" | tr -d '\r\n')
    if [[ "$version" != "$previous_version" ]]; then
      release_series="${GITHUB_REF#refs/heads/release/v}"
      if [[ "$release_series" != "${version%%-*}" ]]; then
        echo "::error::Release branch must match VERSION (release/v${version%%-*})" >&2
        exit 1
      fi
      is_release=true
    fi
  fi
fi

if ! git check-ref-format "refs/tags/$release_tag"; then
  echo "::error::Invalid Git tag: $release_tag" >&2
  exit 1
fi

printf 'image_name=%s\nsha_tag=%s\nrelease_tag=%s\nis_release=%s\nis_prerelease=%s\n' \
  "$image_name" "$sha_tag" "$release_tag" "$is_release" "$is_prerelease"
