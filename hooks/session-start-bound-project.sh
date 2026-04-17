#!/usr/bin/env bash
# session-start-bound-project.sh — SessionStart hook: injects system-reminder naming the bound P2E project.
#
# Claude Code invokes this hook at session start. If .p2e/project.json exists in the project
# directory, we emit a system-reminder block so every subsequent turn knows which P2E project
# this repo is bound to. If the file is absent (non-p2e repo), this hook is a no-op.
#
# Output format: Claude Code SessionStart hooks write to stdout; the runtime appends the output
# as a system-reminder in the conversation.
#
# Exit 0 in all cases — a missing or unreadable binding file is not an error.

set -uo pipefail

# --------------------------------------------------------------------------- #
# Locate the project directory
# --------------------------------------------------------------------------- #
# Claude Code sets CLAUDE_PROJECT_DIR to the repo root (the directory that was
# opened in the session). Fall back to PWD if the variable is not set.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${PWD}}"
BINDING_FILE="${PROJECT_DIR}/.p2e/project.json"

# --------------------------------------------------------------------------- #
# No-op when the binding file is absent
# --------------------------------------------------------------------------- #
if [ ! -f "$BINDING_FILE" ]; then
  exit 0
fi

# --------------------------------------------------------------------------- #
# Parse binding file with jq
# --------------------------------------------------------------------------- #
SLUG="$(jq -r '.slug // empty' "$BINDING_FILE" 2>/dev/null || true)"
GITHUB_REPO="$(jq -r '.github_repo // empty' "$BINDING_FILE" 2>/dev/null || true)"

if [ -z "${SLUG:-}" ] || [ -z "${GITHUB_REPO:-}" ]; then
  # Malformed file — warn but do not block.
  echo "WARNING [session-start-bound-project]: .p2e/project.json is present but missing 'slug' or 'github_repo' fields. Run /p2e-bind to regenerate." >&2
  exit 0
fi

# --------------------------------------------------------------------------- #
# Emit system-reminder
# --------------------------------------------------------------------------- #
cat <<EOF
<system-reminder>
## P2E project binding

This repo is bound to P2E project **${SLUG}** (GitHub: ${GITHUB_REPO}).

Every \`mcp__plugin_p2e_p2e__*\` (and \`mcp__p2e__*\`) tool call in this session
must use \`project_slug: "${SLUG}"\`. The PreToolUse validator hook will block any
call whose \`project_slug\` does not match the bound slug.

Source of truth: \`${BINDING_FILE}\`
</system-reminder>
EOF

exit 0
