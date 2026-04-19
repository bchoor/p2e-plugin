#!/usr/bin/env bash
# parse-gh-issue-body.sh — parse a P2E-synced GitHub issue body into JSON
#
# Usage: parse-gh-issue-body.sh <repo> <issue_number>
#
# <repo>          GitHub repo in owner/name form (e.g. bchoor/p2e)
# <issue_number>  GitHub issue number (integer)
#
# Output: JSON object with keys:
#   storyAs, storyWant, storySoThat, background,
#   acceptanceCriteria (array of {text, checked}),
#   capabilities (array of {name, action, isBreaking, description}),
#   release
#
# Exit codes:
#   0 — success; JSON printed to stdout
#   1 — usage error, gh error, or parse failure (fence missing)
#
# Requires: gh CLI (authenticated), node or bun in PATH.
# The canonical parser lives in src/lib/github.ts (parseIssueBody).
# This script is a thin shell wrapper that fetches the body via gh api
# and pipes it through the TypeScript parser via bun.
#
# Template-mismatch abort: if the body is missing <!-- p2e-sync:start v1 -->
# the TypeScript parser throws with a diagnostic; this script forwards the
# error to stderr and exits 1.

set -euo pipefail

REPO="${1:-}"
ISSUE="${2:-}"

usage() {
  echo "Usage: $0 <repo> <issue_number>" >&2
  echo "  Parses the p2e-sync body of a GitHub issue into JSON." >&2
  echo "  Requires gh CLI authenticated and bun in PATH." >&2
  exit 1
}

[ -n "${REPO}" ] || usage
[ -n "${ISSUE}" ] || usage

# Fetch the issue body via gh api
BODY="$(gh api "repos/${REPO}/issues/${ISSUE}" --jq '.body' 2>&1)" || {
  echo "ERROR: parse-gh-issue-body.sh: gh api failed: ${BODY}" >&2
  exit 1
}

if [ -z "${BODY}" ] || [ "${BODY}" = "null" ]; then
  echo "ERROR: parse-gh-issue-body.sh: issue #${ISSUE} has no body" >&2
  exit 1
fi

# Locate the project root (two levels up from this script: scripts/ -> p2e-plugin/ -> repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
# The TypeScript source lives in the main repo alongside the plugin submodule.
# Walk up from the plugin dir to find src/lib/github.ts
MAIN_REPO="$(cd "${PLUGIN_DIR}/.." && pwd)"

GITHUB_TS="${MAIN_REPO}/src/lib/github.ts"
if [ ! -f "${GITHUB_TS}" ]; then
  echo "ERROR: parse-gh-issue-body.sh: cannot find src/lib/github.ts at ${GITHUB_TS}" >&2
  echo "  Run this script from within the p2e worktree or set the correct path." >&2
  exit 1
fi

# Invoke the TypeScript parser via bun, passing the body via stdin
# The inline script imports parseIssueBody and prints the result as JSON.
PARSE_SCRIPT="$(cat <<'TSEOF'
import { parseIssueBody } from './src/lib/github.ts'
const chunks: Buffer[] = []
process.stdin.on('data', (c) => chunks.push(c))
process.stdin.on('end', () => {
  const body = Buffer.concat(chunks).toString('utf8')
  try {
    const result = parseIssueBody(body)
    process.stdout.write(JSON.stringify(result, null, 2) + '\n')
    process.exit(0)
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err)
    process.stderr.write('ERROR: parse-gh-issue-body.sh: ' + msg + '\n')
    process.exit(1)
  }
})
TSEOF
)"

echo "${BODY}" | bun run --cwd "${MAIN_REPO}" - <<< "${PARSE_SCRIPT}" 2>&1 || {
  # Fallback: if bun run - doesn't work, use a temp file
  TMPFILE="$(mktemp /tmp/p2e-parse-XXXXXX.ts)"
  trap 'rm -f "${TMPFILE}"' EXIT
  echo "${PARSE_SCRIPT}" > "${TMPFILE}"
  echo "${BODY}" | bun run --cwd "${MAIN_REPO}" "${TMPFILE}"
}
