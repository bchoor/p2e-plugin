# p2e-plugin — Claude Code and Codex plugin for P2E

This plugin routes [P2E](https://github.com/bchoor/p2e) story-map work through the P2E MCP server on both Claude Code and Codex.

Primary workflows:

- `p2e` — Codex plain-language router
- `/p2e-bootstrap` and `p2e-bootstrap` — supports `--mode={new,onboarding}`, `--backfill-built`, and `--all`
- `/p2e-add-story` and `p2e-add-story`
- `/p2e-update-story` and `p2e-update-story` — thicken or steer any existing story (replaces `/p2e-add-story --fill`)
- `/p2e-work-on-next` and `p2e-work-on-next`
- `/p2e-sync-labels` and `p2e-sync-labels`
- `/p2e-bind` and `p2e-bind` — bind this repo checkout to a P2E project for automatic slug calibration

## Auto-calibration via `.p2e/project.json`

Run `/p2e-bind` once per repo checkout. It derives `owner/name` from `git remote get-url origin`, matches against the P2E projects you are a member of, and writes `.p2e/project.json` at the repo root. Commit this file so all team members share the same binding.

Once the file is present, two plugin hooks activate automatically:

- **SessionStart** — injects a system-reminder at the start of every Claude Code session naming the bound `project_slug` and `github_repo`.
- **PreToolUse** — intercepts every `mcp__plugin_p2e_p2e__*` tool call and blocks it if `project_slug` does not match the bound slug, printing a clear mismatch error with the bound value.

Neither hook does anything in repos that lack `.p2e/project.json` — non-P2E repos are unaffected.

## What it does

- `bootstrap` turns a PRD into a 2D P2E story map (`--mode=new`, default) or onboards an existing repo via a brainstorming interview that reads docs, route tree, tests, recent git history, and open GH issues (`--mode=onboarding`). `--backfill-built` proposes DONE layers from merged PRs; `--all` fans story drafting across every UXO with one combined accept.
- `add-story` creates a new story through the P2E MCP and links its GitHub issue.
- `update-story` thickens empty fields or steers populated ones on any existing story — rename, re-parent, retag, adjust release, thicken from source — with an annotated preview/confirm loop and the same fail-fast MCP write path. Enforces the P-07-L1 thickness predicate on DRAFT → OPEN.
- `work-on-next` selects planned work, classifies it, orchestrates implementation, and performs normal end-of-run label reconciliation when context is sufficient.
- `sync-labels` remains available as an explicit standalone repair/reconcile workflow when automatic sync is incomplete or external changes need cleanup.

## Install in Claude Code

From inside a Claude Code session:

```text
/plugin marketplace add bchoor/p2e-plugin
/plugin install p2e@p2e-plugins
```

Pin the marketplace to a tag for stability:

```text
/plugin marketplace add bchoor/p2e-plugin@v0.6.0
/plugin install p2e@p2e-plugins
```

The marketplace is named `p2e-plugins`; the plugin itself is named `p2e`.

## Install in Codex

This repository includes a native Codex plugin manifest at [`.codex-plugin/plugin.json`](./.codex-plugin/plugin.json) plus the shared MCP config at [`.mcp.json`](./.mcp.json).

Codex uses:

- the top-level `p2e` skill for plain-language routing
- direct alias skills for `p2e-bootstrap`, `p2e-add-story`, `p2e-update-story`, `p2e-work-on-next`, and `p2e-sync-labels`
- the same shared `workflows/` definitions used by the Claude wrappers

## Configure

The plugin talks to a running P2E instance. It defaults to the hosted production endpoint at `https://p2e-mocha.vercel.app/api/mcp`. Point it at your own instance with `P2E_MCP_URL`:

```bash
export P2E_MCP_URL="https://<your-p2e-instance>/api/mcp"
```

Auth is handled by the host application's MCP flow on first use.

For Codex specifically, the plugin ships with the hosted production URL as its default MCP endpoint. If you want to point Codex at a different P2E instance, update the installed MCP entry or re-add it with a concrete URL rather than relying on shell-style `${VAR:-fallback}` expansion.

## Commands and skills at a glance

| Workflow | Claude | Codex | When to use |
|---|---|---|---|
| Bootstrap | `/p2e-bootstrap <doc-or-repo> [--mode={new,onboarding}] [--backfill-built] [--all]` | `p2e-bootstrap` or natural-language request | Start a new project map from a PRD (`--mode=new`, default) or onboard an existing repo (`--mode=onboarding`). `--backfill-built` proposes DONE layers from merged PRs; `--all` fans story drafting across every UXO. |
| Add story | `/p2e-add-story <description>` | `p2e-add-story` or natural-language request | Create a new story. The legacy `--fill <storyId>` path is deprecated and delegates to `/p2e-update-story` for one release. |
| Update story | `/p2e-update-story <story_id> [source=<prd-or-issue>] [--dry-run]` | `p2e-update-story` or natural-language request | Thicken empty fields, steer populated ones, rename, re-parent, retag, or adjust release on any existing story. Enforces the P-07-L1 thickness predicate on DRAFT → OPEN. |
| Work next | `/p2e-work-on-next [story_id=X-YY-LZ] [--full-team] [--dry-run]` | `p2e-work-on-next` or natural-language request | Pick up planned work, classify it, orchestrate implementation, and run the normal sync path. |
| Sync labels | `/p2e-sync-labels` | `p2e-sync-labels` or natural-language request | Run explicit label reconciliation after external changes, partial runs, or missed automatic sync. |
| Bind repo | `/p2e-bind` | `p2e-bind` or natural-language request | Derive `owner/name` from git remote, match against your P2E projects, and write `.p2e/project.json`. Run once per checkout; commit the file. |

## Sync behavior

`work-on-next` now performs normal end-of-run label reconciliation when it has enough issue and merge context to do so safely.

Use `sync-labels` separately when:

- the orchestrator did not have enough context to finish reconciliation
- a PR merged outside the normal workflow
- you need targeted repair for a story or batch

## Track mapping

When `work-on-next` classifies a story, it routes it through the shared track logic:

| Track | Implementer tier |
|---|---|
| Fast | lightweight implementer |
| Standard | general implementer plus architect |
| Architectural | general implementer plus architect and staff-engineer planning |

Specialist prompts remain:

- `p2e-architect`
- `p2e-staff-engineer`

Those prompts are shared across Claude orchestration and Codex subagent orchestration.

## Status gate hook (PreToolUse)

### What it does

The `hooks/pre-agent-spawn-story-status.sh` hook fires on every `Agent` tool call (implementer spawn). It reads the P2E story id from the agent prompt, checks the story's current status via a local cache or the P2E MCP, and **blocks the spawn** (exit 1) if the story is not yet `IN_PROGRESS` or `IN_REVIEW`. This enforces the `/p2e-work-on-next` dispatch discipline: a story must be moved to `IN_PROGRESS` before an implementer is spawned against it.

The hook is Claude Code-only. Codex does not implement `PreToolUse` hooks; this asymmetry is intentional and documented here rather than wired into `.codex-plugin/plugin.json`.

### Story-id regex

The hook scans the agent prompt for a P2E story id matching:

```
[A-Z]{1,2}-[0-9]+(-L[0-9]+)?
```

Examples: `B-05-L15`, `P-01`, `AB-3`. The first match is used. If no match is found, the hook exits 0 (allow).

### Label map

| P2E status  | GitHub label |
|-------------|--------------|
| OPEN        | `ready`      |
| IN_PROGRESS | `in-progress`|
| IN_REVIEW   | `review`     |
| DONE        | `done`       |
| BLOCKED     | `blocked`    |

Label reconciliation is performed by `scripts/sync-github-label.sh` and is invoked by `workflows/p2e-update-story.md` on every lifecycle-boundary status transition. If a label does not exist on the target repo, a warning is printed and the step exits 0.

### Escape hatch

Set `P2E_SKIP_STATUS_GATE=1` to bypass the hook entirely:

```bash
P2E_SKIP_STATUS_GATE=1 claude ...
```

Use this when bootstrapping, running architect/staff-engineer agents, or during pre-hook setup.

### Auto-short-circuit subagent types

The hook exits 0 (allow) automatically when `subagent_type` in the tool input is one of:

- `p2e-architect`
- `p2e-staff-engineer`
- `rescue`

These subagent types operate before or outside the implementer lifecycle, so the gate does not apply.

### Cache

The hook caches MCP responses locally at:

```
~/.cache/p2e/<slug>/<story_id>.json
```

Format: `{"status":"IN_PROGRESS","ts":1713340800}`

TTL: **30 seconds**. A warm-cache read completes in <500ms (p99). Cold-cache reads make an HTTP round trip to the P2E MCP endpoint (`$P2E_MCP_URL`, default `https://p2e-mocha.vercel.app/api/mcp`) and may exceed 500ms depending on network latency. The hook uses a 2-second curl timeout; on timeout it fails closed (blocks) unless `P2E_SKIP_STATUS_GATE=1`.

`/p2e-update-story` refreshes the cache on every lifecycle-boundary status write, so the hook reads the correct status immediately after a transition without waiting for TTL expiry.

### Fail-closed behavior

If the hook cannot verify the story status (MCP unreachable, auth required, or unparseable response), it **blocks** the spawn with a remediation message. This is intentional: a missing gate check is treated as a failed check.

## MCP tool surface

The plugin exposes the P2E MCP server tools via `mcp__plugin_p2e_p2e__*`. Each tool accepts an `op` parameter to select the operation.

| Tool | Ops | Summary |
|------|-----|---------|
| `stories` | `list`, `get`, `create`, `update`, `delete`, `move` | Core story CRUD. `list` supports multi-value filters (see below). `get` returns full detail including audit log, capabilities, and acceptance criteria. `create` / `update` use an `items:[{...}]` array payload. `move` re-parents a story to another UXO. |
| `criteria` | `list`, `get`, `create`, `update`, `delete` | Acceptance criteria attached to a story. |
| `capabilities` | `list`, `get`, `create`, `update`, `delete` | Story capabilities (INTRODUCES / MODIFIES / DEPRECATES change entries). |
| `relations` | `list`, `get`, `create`, `delete` | Inter-story relations (BUILDS_ON, DEPENDS_ON, SUPERSEDES, FIXES, etc.). |
| `projects` | `list`, `get`, `create`, `update` | Project management including UXO health summary and member roster. |
| `uxos` | `list`, `get`, `create`, `update`, `delete` | UXO (feature objective) CRUD. UXOs live in a Phase × Tier cell. |
| `phases` | `list`, `get`, `create`, `update`, `delete` | Journey phases that contain UXOs. |
| `features` | `list`, `get`, `create`, `update`, `delete` | Features that group UXOs across phases. |
| `tags` | `list` | Project-scoped tag registry derived from story tags. |
| `members` | `list`, `invite`, `remove`, `update` | Project membership management. |
| `coverage` | `get` | UXO coverage report: counts of DONE/partial/gap stories per UXO. |
| `story_assets` | `list`, `get`, `create`, `delete` | File assets attached to a story (e.g. screenshots, specs). |
| `validate` | `run` | Run the P2E story-thickness predicate against a story and return failing clauses. |
| `create_github_issue` | — | Create a linked GitHub issue for a story (one-shot). |
| `sync_github_status` | — | Reconcile P2E story status with the linked GitHub issue label. |

### Multi-value `stories.list` example

Single-value filters (legacy, still work):

```json
{ "op": "list", "project_slug": "p2e", "status": "DONE", "release": "v0.9", "tag": "auth" }
```

Multi-value filters (B-01-L10):

```json
{
  "op": "list",
  "project_slug": "p2e",
  "statuses": ["DONE", "IN_REVIEW"],
  "releases": ["v0.9", "v1.0", null],
  "tags": ["auth", "ui"],
  "tag_mode": "all"
}
```

- `statuses` — `StoryStatus[]`; matches stories whose status is in the array (IN semantics). Overrides single `status`.
- `releases` — `(string | null)[]`; matches stories whose release is in the array. A `null` entry matches stories with no release set. Overrides single `release`.
- `tags` + `tag_mode` — `tags` is a `string[]`; `tag_mode` is `"any"` (default, OR) or `"all"` (AND — story must carry every listed tag). Overrides single `tag`.

All three filters compose with AND semantics against each other and with other filters (`phase`, `tier`, `uxo_id`, `feature_id`).

## Requirements

- a host that supports the plugin surface you want to use: Claude Code or Codex
- access to the P2E MCP server
- `gh` CLI authenticated against the target P2E GitHub repo for issue / PR / label operations

## Links

- P2E main repo: https://github.com/bchoor/p2e
- Hosted demo: https://p2e-mocha.vercel.app
- Issue tracker: https://github.com/bchoor/p2e/issues
