#!/usr/bin/env bash
# Fast, offline tests for the actual GHCR decision scripts; no Docker/GHCR credentials needed.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
prepare="$root/scripts/ci/ghcr-prepare.sh"
decide="$root/scripts/ci/ghcr-promotion-decision.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

passed=0
check_equals() {
  local title=$1 expected=$2 actual=$3
  if [[ "$expected" != "$actual" ]]; then
    printf 'FAIL: %s\nExpected: %s\nActual: %s\n' "$title" "$expected" "$actual" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$title"
  ((passed += 1))
}
check_contains() {
  local title=$1 result=$2 fragment=$3
  if [[ "$result" != *"$fragment"* ]]; then
    printf 'FAIL: %s (missing %s)\nOutput: %s\n' "$title" "$fragment" "$result" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$title"
  ((passed += 1))
}
expect_failure() {
  local title=$1
  shift
  if "$@" > "$tmp/out" 2>&1; then
    printf 'FAIL: %s (unexpected success)\n' "$title" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$title"
  ((passed += 1))
}

sha_a=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
sha_b=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

check_equals 'first successful image becomes latest' promote "$(bash "$decide" '' "$sha_a" '')"
check_equals 'newer successful image advances latest' promote "$(bash "$decide" "$sha_a" "$sha_b" ahead)"
check_equals 'older completed build does not overwrite latest' skip "$(bash "$decide" "$sha_b" "$sha_a" behind)"
check_equals 'repeat promotion is idempotent' skip "$(bash "$decide" "$sha_a" "$sha_a" '')"
expect_failure 'diverged commits fail closed' bash "$decide" "$sha_a" "$sha_b" diverged
expect_failure 'missing revision annotation fails closed' bash "$decide" malformed "$sha_b" ahead
expect_failure 'bad comparison status fails closed' bash "$decide" "$sha_a" "$sha_b" unexpected
expect_failure 'invalid candidate SHA fails closed' bash "$decide" '' invalid ''

repo="$tmp/repo"
mkdir -p "$repo"
git -C "$repo" init -q
git -C "$repo" config user.email ci-tests@example.invalid
git -C "$repo" config user.name 'CI Tests'
printf '0.1.0\n' > "$repo/VERSION"
git -C "$repo" add VERSION
git -C "$repo" commit -qm initial
base_sha=$(git -C "$repo" rev-parse HEAD)

git -C "$repo" checkout -qb release/v0.2.0
run_prepare() {
  (cd "$repo" && GITHUB_REPOSITORY='Expertiza/reimplementation-back-end' \
    GITHUB_SHA="$base_sha" GITHUB_REF="$1" BEFORE_SHA="$2" \
    bash "$prepare")
}

result=$(run_prepare refs/heads/main "$base_sha")
check_contains 'main push emits normalized image' "$result" 'image_name=expertiza/reimplementation-back-end'
check_contains 'main push emits SHA tag' "$result" "sha_tag=sha-${base_sha::7}"
check_contains 'main push does not publish release' "$result" 'is_release=false'

result=$(run_prepare refs/heads/release/v0.2.0 0000000000000000000000000000000000000000)
check_contains 'new release branch does not immediately release' "$result" 'is_release=false'

result=$(run_prepare refs/heads/release/v0.2.0 "$base_sha")
check_contains 'unchanged VERSION does not trigger a release' "$result" 'is_release=false'

printf '0.2.0\n' > "$repo/VERSION"
result=$(run_prepare refs/heads/release/v0.2.0 "$base_sha")
check_contains 'changed VERSION triggers versioned release' "$result" 'is_release=true'
check_contains 'changed VERSION provides release tag' "$result" 'release_tag=v0.2.0'

printf '0.2.0-rc.1\n' > "$repo/VERSION"
result=$(run_prepare refs/heads/release/v0.2.0 "$base_sha")
check_contains 'prerelease detected' "$result" 'is_prerelease=true'
check_contains 'prerelease tag is correct' "$result" 'release_tag=v0.2.0-rc.1'

printf '0.3.0\n' > "$repo/VERSION"
expect_failure 'release branch and VERSION must match' run_prepare refs/heads/release/v0.2.0 "$base_sha"

printf 'bad-version\n' > "$repo/VERSION"
expect_failure 'invalid VERSION fails' run_prepare refs/heads/main "$base_sha"

printf '\n%s GHCR workflow tests passed.\n' "$passed"
