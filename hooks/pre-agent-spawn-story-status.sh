#!/usr/bin/env bash
# pre-agent-spawn-story-status.sh — PreToolUse hook: blocks Agent spawn against stories not yet IN_PROGRESS/IN_REVIEW
#
# Claude Code invokes this hook via stdin with the tool-call JSON payload when the Agent tool is called.
# Exit 0  = allow the Agent spawn.
# Exit 1  = block the Agent spawn (stderr message shown to user).
#
# Short-circuit conditions (exit 0 without checking):
#   1. P2E_SKIP_STATUS_GATE=1 is set in environment
#   2. No P2E story id matching /[A-Z]{1,2}-[0-9]+(-L[0-9]+)?/ found in the prompt
#   3. subagent_type is one of: p2e-architect, p2e-staff-engineer, rescue
#
# Cache: ~/.cache/p2e/<slug>/<story_id>.json  { "status": "...", "ts": <unix-epoch> }
#        TTL = 30 seconds (warm-cache p99 < 500ms; cold cache may exceed due to MCP HTTP round trip)
#
# MCP endpoint: $P2E_MCP_URL (default https://p2e-mocha.vercel.app/api/mcp)
# Auth: MCP requires OAuth; if a token cannot be found, the hook fails-closed (blocks)
#       unless P2E_SKIP_STATUS_GATE=1 or subagent_type is in the allowlist.

set -uo pipefail

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #
P2E_MCP_URL="${P2E_MCP_URL:-https://p2e-mocha.vercel.app/api/mcp}"
CACHE_BASE="${HOME}/.cache/p2e"
CACHE_TTL=30  # seconds
ALLOWED_STATUSES="IN_PROGRESS IN_REVIEW"
ALLOWLIST_SUBAGENT_TYPES="p2e-architect p2e-staff-engineer rescue"

# --------------------------------------------------------------------------- #
# Short-circuit 1: skip gate env var
# --------------------------------------------------------------------------- #
if [ "${P2E_SKIP_STATUS_GATE:-}" = "1" ]; then
  exit 0
fi

# --------------------------------------------------------------------------- #
# Read stdin payload (Claude Code PreToolUse hook format)
# --------------------------------------------------------------------------- #
PAYLOAD="$(cat)"

if [ -z "$PAYLOAD" ]; then
  exit 0
fi

# --------------------------------------------------------------------------- #
# Short-circuit 3: allowlisted subagent_type
# --------------------------------------------------------------------------- #
SUBAGENT_TYPE="$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null || true)"
if [ -n "${SUBAGENT_TYPE:-}" ]; then
  for allowed in $ALLOWLIST_SUBAGENT_TYPES; do
    if [ "$SUBAGENT_TYPE" = "$allowed" ]; then
      exit 0
    fi
  done
fi

# --------------------------------------------------------------------------- #
# Short-circuit 2: extract story_id from prompt
# --------------------------------------------------------------------------- #
PROMPT="$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.prompt // empty' 2>/dev/null || true)"
if [ -z "${PROMPT:-}" ]; then
  exit 0
fi

STORY_ID="$(printf '%s' "$PROMPT" | grep -oE '[A-Z]{1,2}-[0-9]+(-L[0-9]+)?' | head -1 || true)"
if [ -z "${STORY_ID:-}" ]; then
  exit 0
fi

# --------------------------------------------------------------------------- #
# Derive cache slug from story id prefix (e.g. B-05 → b-05)
# --------------------------------------------------------------------------- #
SLUG="$(printf '%s' "$STORY_ID" | sed 's/-L[0-9]*$//' | tr '[:upper:]' '[:lower:]')"
CACHE_DIR="${CACHE_BASE}/${SLUG}"
CACHE_FILE="${CACHE_DIR}/${STORY_ID}.json"

# --------------------------------------------------------------------------- #
# Cache lookup (TTL 30s)
# --------------------------------------------------------------------------- #
CACHED_STATUS=""
NOW="$(date +%s)"
if [ -f "$CACHE_FILE" ]; then
  CACHE_TS="$(jq -r '.ts // 0' "$CACHE_FILE" 2>/dev/null || echo 0)"
  CACHE_AGE=$(( NOW - CACHE_TS ))
  if [ "$CACHE_AGE" -le "$CACHE_TTL" ]; then
    CACHED_STATUS="$(jq -r '.status // empty' "$CACHE_FILE" 2>/dev/null || true)"
  fi
fi

if [ -n "${CACHED_STATUS:-}" ]; then
  CURRENT_STATUS="$CACHED_STATUS"
else
  # --------------------------------------------------------------------------- #
  # Cache miss: call MCP via HTTP (2-second timeout)
  # --------------------------------------------------------------------------- #
  MCP_BODY="{\"method\":\"tools/call\",\"params\":{\"name\":\"stories\",\"arguments\":{\"op\":\"get\",\"story_id\":\"${STORY_ID}\"}}}"

  MCP_RESPONSE="$(curl -sf --max-time 2 \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$MCP_BODY" \
    "$P2E_MCP_URL" 2>&1)" && CURL_EXIT=0 || CURL_EXIT=$?

  if [ "$CURL_EXIT" -ne 0 ]; then
    echo "WARNING [pre-agent-spawn-story-status]: hook could not verify status for ${STORY_ID} (MCP unreachable or auth required — set P2E_SKIP_STATUS_GATE=1 to override)" >&2
    # Fail-closed: block when we cannot verify
    echo "BLOCKED [pre-agent-spawn-story-status]: cannot confirm ${STORY_ID} is IN_PROGRESS or IN_REVIEW." >&2
    echo "  Remediation: run '/p2e-update-story ${STORY_ID} status=IN_PROGRESS' first, or set P2E_SKIP_STATUS_GATE=1 to bypass." >&2
    exit 1
  fi

  CURRENT_STATUS="$(printf '%s' "$MCP_RESPONSE" | jq -r '.result.status // .status // empty' 2>/dev/null || true)"

  if [ -z "${CURRENT_STATUS:-}" ]; then
    echo "WARNING [pre-agent-spawn-story-status]: could not parse status for ${STORY_ID} from MCP response — failing closed" >&2
    echo "BLOCKED [pre-agent-spawn-story-status]: cannot confirm ${STORY_ID} is IN_PROGRESS or IN_REVIEW." >&2
    echo "  Remediation: run '/p2e-update-story ${STORY_ID} status=IN_PROGRESS' first, or set P2E_SKIP_STATUS_GATE=1 to bypass." >&2
    exit 1
  fi

  # Refresh cache
  mkdir -p "$CACHE_DIR"
  printf '{"status":"%s","ts":%s}\n' "$CURRENT_STATUS" "$NOW" > "$CACHE_FILE" || true
fi

# --------------------------------------------------------------------------- #
# Gate check
# --------------------------------------------------------------------------- #
IS_ALLOWED=0
for s in $ALLOWED_STATUSES; do
  if [ "$CURRENT_STATUS" = "$s" ]; then
    IS_ALLOWED=1
    break
  fi
done

if [ "$IS_ALLOWED" -eq 1 ]; then
  exit 0
fi

# --------------------------------------------------------------------------- #
# Block with remediation message
# --------------------------------------------------------------------------- #
echo "BLOCKED [pre-agent-spawn-story-status]: story ${STORY_ID} is at status '${CURRENT_STATUS}' — implementer spawn requires IN_PROGRESS or IN_REVIEW." >&2
echo "  Remediation: run '/p2e-update-story ${STORY_ID} status=IN_PROGRESS' to move it to IN_PROGRESS, then retry." >&2
echo "  To bypass this gate (not recommended): set P2E_SKIP_STATUS_GATE=1." >&2
exit 1
