#!/usr/bin/env bash
# start-dev-detached.sh — launch dev server(s) in a way that survives
# Claude Code's background-task reaper across turn boundaries.
#
# Usage:
#   bash skills/p2e-verify-story/scripts/start-dev-detached.sh \
#     [--workspace-dir <path>] [--server-script <name>] [--client-script <name>]
#
# Defaults:
#   --workspace-dir:  cwd (else scan down to 3 levels for a package.json)
#   --server-script:  dev:server  (falls back to start, then dev)
#   --client-script:  dev:client  (falls back to dev, then start)
#
# Side effects:
#   - Writes PID files to .claude/verify-story-pids/{server,client}.pid
#   - Writes server/client logs to .claude/verify-story-pids/{server,client}.log
#   - Prints the actually-bound app URL on success

set -euo pipefail

PIDS_DIR=".claude/verify-story-pids"
mkdir -p "$PIDS_DIR"

# --- args ---
WORKSPACE_DIR=""
SERVER_SCRIPT=""
CLIENT_SCRIPT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace-dir) WORKSPACE_DIR="$2"; shift 2 ;;
    --server-script) SERVER_SCRIPT="$2"; shift 2 ;;
    --client-script) CLIENT_SCRIPT="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

# --- resolve workspace dir ---
# Precedence: explicit --workspace-dir → cwd's package.json → scan down 3 levels.
# When the scan finds MULTIPLE candidates, refuse with the list and ask for
# --workspace-dir rather than silently picking one (the doc-reviewer original
# silently took head -1, which led to wrong-workspace launches in polyrepos).
if [[ -n "$WORKSPACE_DIR" ]]; then
  if [[ ! -d "$WORKSPACE_DIR" ]]; then
    echo "ERROR: --workspace-dir $WORKSPACE_DIR does not exist or is not a directory" >&2
    exit 1
  fi
  cd "$WORKSPACE_DIR"
  echo "workspace pinned by --workspace-dir: $(pwd)"
fi

if [[ ! -f package.json ]]; then
  CANDIDATES=()
  while IFS= read -r line; do
    CANDIDATES+=("$line")
  done < <(find . -maxdepth 3 -name package.json -not -path '*/node_modules/*' 2>/dev/null)

  case ${#CANDIDATES[@]} in
    0)
      echo "ERROR: no package.json in cwd ($(pwd)) or up to 3 directory levels deep" >&2
      echo "  cd into the workspace dir, or pass --workspace-dir <path>." >&2
      exit 1
      ;;
    1)
      cd "$(dirname "${CANDIDATES[0]}")"
      echo "package.json not in starting dir — descended into $(pwd)"
      ;;
    *)
      echo "ERROR: multiple package.json candidates under $(pwd):" >&2
      printf '  - %s\n' "${CANDIDATES[@]}" >&2
      echo "" >&2
      echo "  Pass --workspace-dir <path> to pick one explicitly (e.g. --workspace-dir apps/web)." >&2
      exit 1
      ;;
  esac
fi

read_script() {
  local name=$1
  jq -r ".scripts.\"$name\" // empty" package.json
}

# Resolve server script
if [[ -z "$SERVER_SCRIPT" ]]; then
  for candidate in "dev:server" "server" "start:server" "backend"; do
    if [[ -n "$(read_script "$candidate")" ]]; then
      SERVER_SCRIPT="$candidate"
      break
    fi
  done
fi

# Resolve client script
if [[ -z "$CLIENT_SCRIPT" ]]; then
  for candidate in "dev:client" "dev" "start" "client" "frontend"; do
    if [[ -n "$(read_script "$candidate")" ]]; then
      CLIENT_SCRIPT="$candidate"
      break
    fi
  done
fi

# --- pick package runner ---
if [[ -f bun.lockb ]] || [[ -f bun.lock ]]; then
  PM="bun run"
elif [[ -f pnpm-lock.yaml ]]; then
  PM="pnpm"
elif [[ -f yarn.lock ]]; then
  PM="yarn"
else
  PM="npm run"
fi

echo "Package runner: $PM"
echo "Server script:  ${SERVER_SCRIPT:-<none>}"
echo "Client script:  ${CLIENT_SCRIPT:-<none>}"

# --- launch ---
launch_detached() {
  local label=$1
  local script=$2
  local logfile="$PIDS_DIR/$label.log"
  : > "$logfile"
  nohup $PM "$script" > "$logfile" 2>&1 &
  local pid=$!
  disown
  echo "$pid" > "$PIDS_DIR/$label.pid"
  echo "Launched $label (script=$script, pid=$pid, log=$logfile)"
}

if [[ -n "$SERVER_SCRIPT" ]]; then
  launch_detached "server" "$SERVER_SCRIPT"
fi
if [[ -n "$CLIENT_SCRIPT" ]] && [[ "$CLIENT_SCRIPT" != "$SERVER_SCRIPT" ]]; then
  launch_detached "client" "$CLIENT_SCRIPT"
fi

# --- wait for client to print its URL ---
URL=""
if [[ -f "$PIDS_DIR/client.log" ]]; then
  echo "Waiting for app URL..."
  for i in $(seq 1 30); do
    URL=$(grep -oE 'https?://(localhost|127\.0\.0\.1):[0-9]+' "$PIDS_DIR/client.log" | head -1 || true)
    if [[ -n "$URL" ]]; then break; fi
    sleep 0.5
  done
fi
if [[ -z "$URL" ]] && [[ -f "$PIDS_DIR/server.log" ]]; then
  URL=$(grep -oE 'https?://(localhost|127\.0\.0\.1):[0-9]+' "$PIDS_DIR/server.log" | head -1 || true)
fi

if [[ -z "$URL" ]]; then
  echo "WARN: could not detect app URL from logs after 15s. Check logs in $PIDS_DIR/." >&2
  exit 0
fi

# --- verify the port is actually bound (port-clash mitigation) ---
PORT=$(echo "$URL" | sed -E 's/.*:([0-9]+).*/\1/')
if ! lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "WARN: $URL detected in logs but nothing is LISTEN on $PORT — may be a port-clash." >&2
fi

echo
echo "=========================================="
echo "App URL: $URL"
echo "=========================================="
echo
echo "To tear down: bash $(dirname "$0")/stop-dev.sh"
