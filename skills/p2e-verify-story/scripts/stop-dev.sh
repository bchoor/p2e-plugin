#!/usr/bin/env bash
# stop-dev.sh — kill the detached dev processes started by start-dev-detached.sh.
#
# Reads PIDs from .claude/verify-story-pids/*.pid, sends SIGTERM, removes the pid file.
# Idempotent — safe to run multiple times.

set -u

PIDS_DIR=".claude/verify-story-pids"
if [[ ! -d "$PIDS_DIR" ]]; then
  echo "No PIDs dir at $PIDS_DIR — nothing to stop."
  exit 0
fi

found=0
for pidfile in "$PIDS_DIR"/*.pid; do
  [[ -e "$pidfile" ]] || continue
  pid=$(cat "$pidfile" 2>/dev/null || echo "")
  label=$(basename "$pidfile" .pid)
  if [[ -z "$pid" ]]; then
    echo "$label: empty pid file — removing"
    rm -f "$pidfile"
    continue
  fi
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    echo "$label: killed pid $pid"
    found=$((found + 1))
  else
    echo "$label: pid $pid already gone"
  fi
  rm -f "$pidfile"
done

# Also remove logs older than this run? Keep them — useful for post-mortem.
echo "Done. ($found process(es) signalled)"
