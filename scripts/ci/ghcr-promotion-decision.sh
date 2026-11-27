#!/usr/bin/env bash
# Determine whether a successful main-branch image should advance :latest.
# Args: existing-latest-revision (empty when missing), candidate-revision, compare-status.
# When both SHAs differ, compare-status is GitHub's compare/<previous>...<candidate>.status.
# Outputs exactly "promote" or "skip" on success, fails closed on unsafe states.
set -euo pipefail

if (( $# != 3 )); then
  echo 'Usage: ghcr-promotion-decision.sh PREVIOUS_SHA CANDIDATE_SHA COMPARE_STATUS' >&2
  exit 2
fi
previous_sha=$1
candidate_sha=$2
status=$3

if [[ ! "$candidate_sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo '::error::Candidate revision must be a full 40-character SHA' >&2
  exit 2
fi

if [[ -z "$previous_sha" ]]; then
  # Caller must only pass an empty previous SHA when :latest is confirmed absent.
  echo promote
  exit 0
fi

if [[ ! "$previous_sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo '::error::Existing latest image lacks a valid revision annotation' >&2
  exit 2
fi

if [[ "$previous_sha" == "$candidate_sha" ]]; then
  echo skip
  exit 0
fi

case "$status" in
  ahead) echo promote ;;
  behind|identical) echo skip ;;
  diverged) echo '::error::Candidate and latest revisions have diverged' >&2; exit 2 ;;
  *) echo "::error::Unexpected GitHub comparison status: $status" >&2; exit 2 ;;
esac
