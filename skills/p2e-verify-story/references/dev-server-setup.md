# Dev Server Setup

The harness reaps background tasks across turn boundaries, and ports collide between projects. Both failures look identical to the user (a broken UAT report), but the root causes differ. This reference documents the patterns for bringing the app up reliably.

## The two failure modes

### 1. Reaped background task

```
$ bun run dev  (run_in_background: true)
... server starts ...
... agent does other work, turn ends ...
... next turn begins ...
... server is GONE (SIGTERM during reap)
```

Symptom: Chrome MCP's `new_page` returns `net::ERR_CONNECTION_REFUSED`, or earlier-running curl commands fail with exit 7.

Cause: the harness aggressively reaps tracked background tasks. Even `Bash run_in_background: true` is subject to this — the task exists in the harness's task list, and the reaper SIGTERMs it.

Fix: use `nohup ... & disown` to detach the process from the shell session entirely. The harness no longer tracks it, so the reaper can't kill it.

### 2. Port-clash with stale code

```
$ lsof -iTCP:8765 -sTCP:LISTEN
... PID owned by ANOTHER instance of the same app (e.g. another worktree) ...
$ bun run dev:server
... falls through to port 8766 because 8765 is held ...
$ # but Vite's proxy still targets 8765 (hardcoded in vite.config.ts)
... browser hits 8765 → stale main-branch backend (no new route!)
```

Symptom: the new endpoint returns 404 / 500 with stale-shape body. Or the UI behavior is the OLD behavior despite source-level changes.

Cause: dev servers fall through to alternate ports on collision, but client-side proxies are typically hardcoded to the default. The browser ends up talking to whichever process bound the default port first — which may be a different project's dev server.

Fix: BEFORE driving the browser, verify the actually-bound ports with `lsof -iTCP:<port> -sTCP:LISTEN`. If the expected port is held by an unfamiliar PID, either kill the stale process (with the user's blessing) or pass the actual port via env var.

This is the `feedback_uat_verify_running_code` failure mode. Never trust "the server started" output alone; verify the listener.

## The detached-launch pattern

```bash
LOG=.claude/verify-story-pids/dev
mkdir -p .claude/verify-story-pids

# Backend
nohup bun run dev:server > $LOG-server.log 2>&1 &
echo $! > .claude/verify-story-pids/server.pid
disown

# Client
nohup bun run dev:client > $LOG-client.log 2>&1 &
echo $! > .claude/verify-story-pids/client.pid
disown

# Verify ports
sleep 5
lsof -iTCP:8765 -sTCP:LISTEN
lsof -iTCP:5173 -sTCP:LISTEN
```

The `scripts/start-dev-detached.sh` helper does this generically — it reads `package.json` for the dev scripts and probes a candidate port list to find what bound.

## Reading the actual URL from dev banners

Vite prints its bound URL like `http://localhost:5174/`. Other dev tools (webpack-dev-server, Next.js, etc.) emit similar lines. Wait for the log to contain a URL pattern, then extract:

```bash
until grep -oE 'http://localhost:[0-9]+' $LOG-client.log | head -1; do sleep 0.5; done
```

This is the URL Chrome MCP must hit. Do not assume the default port — port-clash mitigation requires reading what actually got bound.

## Pre-staging app state

Many apps require state to be set before the verification flow begins: a docs root chosen, a user logged in, a file opened. The browser's file-picker dialog and other user-gesture-required APIs cannot be driven from MCP. Workarounds:

### Via backend API

If the app exposes an internal endpoint to set state, prefer it:

```bash
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"path":"/path/to/docs"}' \
  "http://127.0.0.1:8765/api/set-root"
```

Probe the running server for relevant endpoints by reading the source — search for `app.post|router.post` in the backend code. Common patterns: `/api/set-root`, `/api/login`, `/api/state/restore`.

### Via localStorage seeding

If state lives client-side, set localStorage before page load via `mcp__chrome-devtools__evaluate_script`:

```js
() => {
  localStorage.setItem("app:open-files", JSON.stringify(["a.md", "b.md"]));
  localStorage.setItem("app:active-file", "a.md");
  return { set: true };
}
```

Then reload via `mcp__chrome-devtools__navigate_page({ type: "reload" })`. The app reads the seeded state on hydration.

Note: localStorage is **port-scoped**. State seeded on `:5174` does not appear on `:5173`. If you switch ports mid-flow, you must re-seed.

### Via cookie setting

Same approach using `document.cookie` in evaluate_script, or via `mcp__chrome-devtools__evaluate_script` with the cookies-API equivalent. Less common; usually session tokens.

## Project-specific setup hook

Some repos document a fixtures/seed/login script in their README or CONTRIBUTING (common names: `setup.sh`, `scripts/seed.sh`, `.claude/release-setup.sh`). If one exists and is relevant to the AC you're verifying, run it BEFORE Phase 3. When in doubt, ask the user.

## Teardown

After verification, kill the dev processes via the PID file:

```bash
for f in .claude/verify-story-pids/*.pid; do
  pid=$(cat "$f")
  kill "$pid" 2>/dev/null
  rm -f "$f"
done
```

The `scripts/stop-dev.sh` helper kills the processes and removes the per-process `.pid` files, but **leaves the `.claude/verify-story-pids/` directory and its `.log` files on disk** for post-mortem review. If you want a clean teardown, `rm -rf .claude/verify-story-pids/` after the script returns.

Leave the artifacts dir on disk — it's the deliverable.

## When pre-staging is not possible

Some apps require true user-gesture-only state (e.g., a file picker for a folder outside the browser sandbox). Document this in the report's "What was NOT verified" section and ask the user to perform that step manually before starting verification — the skill is then driving an already-staged app, not setting it up from scratch.
