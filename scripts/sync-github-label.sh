#!/usr/bin/env bash
# sync-github-label.sh — reconcile a GitHub issue label on a P2E lifecycle transition
#
# Usage: sync-github-label.sh <repo> <issue_number> <from_status> <to_status>
#
# <repo>         GitHub repo in owner/name form (e.g. bchoor/p2e)
# <issue_number> GitHub issue number (integer)
# <from_status>  P2E status being transitioned FROM (OPEN|IN_PROGRESS|IN_REVIEW|DONE|BLOCKED)
# <to_status>    P2E status being transitioned TO
#
# Label map: OPEN=ready  IN_PROGRESS=in-progress  IN_REVIEW=review  DONE=done  BLOCKED=blocked
# Unknown status → stderr warning, exit 0 (not a failure).
# "Label not found on repo" → stderr warning, exit 0.
# Other gh errors → stderr message, exit 1.
# Idempotent: removing an absent label and adding a present label are both safe no-ops.

set -euo pipefail

REPO="${1:-}"
ISSUE="${2:-}"
FROM_STATUS="${3:-}"
TO_STATUS="${4:-}"

usage() {
  echo "Usage: $0 <repo> <issue_number> <from_status> <to_status>" >&2
  exit 1
}

[ -n "${REPO}" ] || usage
[ -n "${ISSUE}" ] || usage
[ -n "${FROM_STATUS}" ] || usage
[ -n "${TO_STATUS}" ] || usage

# Label map
status_to_label() {
  local status="$1"
  case "$status" in
    OPEN)        echo "ready" ;;
    IN_PROGRESS) echo "in-progress" ;;
    IN_REVIEW)   echo "review" ;;
    DONE)        echo "done" ;;
    BLOCKED)     echo "blocked" ;;
    *)           echo "" ;;
  esac
}

FROM_LABEL="$(status_to_label "$FROM_STATUS")"
TO_LABEL="$(status_to_label "$TO_STATUS")"

if [ -z "$TO_LABEL" ]; then
  echo "WARNING: sync-github-label.sh: no label mapping for status '${TO_STATUS}' — skipping label update" >&2
  exit 0
fi

# Build gh args: always add the to-label; only remove the from-label if it maps to something
GH_ARGS=("issue" "edit" "$ISSUE" "--repo" "$REPO" "--add-label" "$TO_LABEL")
if [ -n "$FROM_LABEL" ] && [ "$FROM_LABEL" != "$TO_LABEL" ]; then
  GH_ARGS+=("--remove-label" "$FROM_LABEL")
fi

# Run gh; distinguish "label does not exist" from hard failures
GH_OUTPUT="$(gh "${GH_ARGS[@]}" 2>&1)" && EXIT_CODE=0 || EXIT_CODE=$?

if [ "$EXIT_CODE" -ne 0 ]; then
  # gh returns non-zero if a label doesn't exist on the repo; treat that as a warning
  if echo "$GH_OUTPUT" | grep -qi "label.*not.*found\|could not find\|does not exist\|unknown label"; then
    echo "WARNING: sync-github-label.sh: label not found on repo '${REPO}' — ${GH_OUTPUT}" >&2
    echo "  To create the missing label: gh label create '${TO_LABEL}' --repo '${REPO}'" >&2
    exit 0
  fi
  echo "ERROR: sync-github-label.sh: gh command failed (exit ${EXIT_CODE}): ${GH_OUTPUT}" >&2
  exit 1
fi

echo "sync-github-label.sh: issue #${ISSUE} on ${REPO}: ${FROM_STATUS}(${FROM_LABEL}) → ${TO_STATUS}(${TO_LABEL})" >&2
exit 0
