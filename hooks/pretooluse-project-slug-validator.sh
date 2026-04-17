#!/usr/bin/env bash
# pretooluse-project-slug-validator.sh — PreToolUse hook: blocks mcp__plugin_p2e_p2e__* calls
# whose project_slug does not match the repo-bound slug in .p2e/project.json.
#
# Claude Code invokes this hook via stdin with the tool-call JSON payload.
# Exit 0  = allow the tool call.
# Exit 1  = block the tool call (stderr message shown to user).
#
# Short-circuit conditions (exit 0):
#   1. Tool name does not match the mcp__plugin_p2e_p2e__* prefix.
#   2. .p2e/project.json does not exist in the project directory.
#   3. tool_input.project_slug is absent from the payload.
#   4. The slug in the payload matches the bound slug.

set -uo pipefail

# --------------------------------------------------------------------------- #
# Read stdin payload
# --------------------------------------------------------------------------- #
PAYLOAD="$(cat)"

if [ -z "$PAYLOAD" ]; then
  exit 0
fi

# --------------------------------------------------------------------------- #
# Short-circuit 1: only validate p2e MCP tool calls
# --------------------------------------------------------------------------- #
TOOL_NAME="$(printf '%s' "$PAYLOAD" | jq -r '.tool_name // empty' 2>/dev/null || true)"
case "${TOOL_NAME:-}" in
  mcp__plugin_p2e_p2e__*)
    : # falls through to validation
    ;;
  *)
    exit 0
    ;;
esac

# --------------------------------------------------------------------------- #
# Short-circuit 2: no-op when binding file is absent
# --------------------------------------------------------------------------- #
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${PWD}}"
BINDING_FILE="${PROJECT_DIR}/.p2e/project.json"

if [ ! -f "$BINDING_FILE" ]; then
  exit 0
fi

# --------------------------------------------------------------------------- #
# Parse bound slug from binding file
# --------------------------------------------------------------------------- #
BOUND_SLUG="$(jq -r '.slug // empty' "$BINDING_FILE" 2>/dev/null || true)"

if [ -z "${BOUND_SLUG:-}" ]; then
  # Malformed binding — warn but allow (do not block on corrupted anchor).
  echo "WARNING [pretooluse-project-slug-validator]: .p2e/project.json exists but 'slug' field is missing or empty — skipping slug validation. Run /p2e-bind to regenerate." >&2
  exit 0
fi

# --------------------------------------------------------------------------- #
# Short-circuit 3: no project_slug in the tool call payload — allow
# --------------------------------------------------------------------------- #
CALL_SLUG="$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.project_slug // empty' 2>/dev/null || true)"

if [ -z "${CALL_SLUG:-}" ]; then
  exit 0
fi

# --------------------------------------------------------------------------- #
# Short-circuit 4: slug matches — allow
# --------------------------------------------------------------------------- #
if [ "$CALL_SLUG" = "$BOUND_SLUG" ]; then
  exit 0
fi

# --------------------------------------------------------------------------- #
# Block: slug mismatch
# --------------------------------------------------------------------------- #
GITHUB_REPO="$(jq -r '.github_repo // "unknown"' "$BINDING_FILE" 2>/dev/null || echo "unknown")"

echo "BLOCKED [pretooluse-project-slug-validator]: tool '${TOOL_NAME}' was called with project_slug='${CALL_SLUG}' but this repo is bound to '${BOUND_SLUG}' (GitHub: ${GITHUB_REPO})." >&2
echo "  Fix: pass project_slug=\"${BOUND_SLUG}\" in the tool call, or update the binding by running /p2e-bind." >&2
echo "  Binding source: ${BINDING_FILE}" >&2
exit 1
