# p2e-plugin — Claude Code, Codex, and Cursor plugin for P2E

This plugin routes [P2E](https://github.com/bchoor/p2e) story-map work through the P2E MCP server on Claude Code, Codex, and Cursor. Behavior lives once in `workflows/<name>.md`; each platform gets a thin wrapper (`commands/` for Claude, `skills/` for Codex, `.cursor/skills/` for Cursor) — see [`CLAUDE.md`](./CLAUDE.md) and [`reference/cross-platform-pattern.md`](./reference/cross-platform-pattern.md).

It tracks the P2E **Patton v3 Flow/Foundation model**: every project is now a *Product* with two seeded Flows — a persona Flow (the user-journey lane) and an immutable Foundation Flow (8 platform/infra slots: Surfaces, Security, Data, Compute, Build-Deploy, Distribution, Observability, Cross-cutting). Stories carry a `priority` (`P0`…`P3`) that orders the `/p2e-work-on-next` queue. See [Flow / Foundation model](#flow--foundation-model) below.

Primary workflows:

- `p2e` — Codex / Cursor plain-language router
- `/p2e-bootstrap` and `p2e-bootstrap` — supports `--mode={new,onboarding}`, `--backfill-built`, and `--all`
- `/p2e-add-story` and `p2e-add-story`
- `/p2e-update-story` and `p2e-update-story` — thicken or steer any existing story (replaces `/p2e-add-story --fill`)
- `/p2e-work-on-next` and `p2e-work-on-next` — picks the top story by priority, then orchestrates implementation
- `/p2e-sync-labels`, `/p2e-sync`, `/p2e-manage-uxo`, `/p2e-archaeology` — label/drift reconciliation, UXO authoring, autonomous repo onboarding
- `/p2e-fix` and `p2e-fix` — fix one or more bugs by uprooting and re-implementing, not by layering patches (per-bug fix-shape gate)
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
- `work-on-next` selects planned work — the OPEN queue is ordered by `Story.priority` (`P0` → `P1` → `P2` → `P3` → unprioritized), then oldest-first — classifies it, orchestrates implementation, and performs normal end-of-run label reconciliation when context is sufficient.
- `sync-labels` remains available as an explicit standalone repair/reconcile workflow when automatic sync is incomplete or external changes need cleanup.
- `fix` resolves a batch of bugs with a per-bug discipline: identify what to **delete** before what to **add**, name (and reject) the band-aid alternative, then verify both the original problem and the absence of regressions before completing.

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
- direct alias skills for `p2e-bootstrap`, `p2e-add-story`, `p2e-update-story`, `p2e-work-on-next`, `p2e-sync-labels`, `p2e-sync`, `p2e-bind`, `p2e-manage-uxo`, `p2e-archaeology`, and `p2e-fix`
- the `writing-rich-docs` skill (auto-discovered under `skills/`)
- the same shared `workflows/` definitions used by the Claude wrappers

## Install in Cursor

Cursor reads the `.cursor/` directory directly — it does not load `.claude-plugin/plugin.json` or `.codex-plugin/plugin.json`. Clone or vendor this repo (or add it as a submodule) so that `.cursor/skills/` and `.cursor/rules/` are visible from your project root, then:

- invoke any workflow with `/p2e-<name>` in agent chat — `/p2e-work-on-next`, `/p2e-bootstrap`, `/p2e-add-story`, `/p2e-update-story`, `/p2e-fix`, `/p2e-bind`, `/p2e-sync`, `/p2e-sync-labels`, `/p2e-manage-uxo`, `/p2e-archaeology`, or the plain-language `/p2e` router
- the always-applied rule `.cursor/rules/p2e-policy.mdc` keeps Cursor aligned with the same `workflows/p2e-policy.md` contract Claude and Codex follow
- point Cursor at the P2E MCP server via `.cursor/mcp.json` (or your global Cursor MCP config) using the same URL as [`.mcp.json`](./.mcp.json) — `https://p2e-mocha.vercel.app/api/mcp` by default, override with your own instance

The `/p2e-html`, `/p2e-md`, and `/p2e-md-to-html` doc-output override commands are Claude-Code-specific (they override the default rich-Markdown output set in `~/.claude/CLAUDE.md`) and have no Codex or Cursor equivalent — the `writing-rich-docs` skill is the cross-platform doc-rendering surface (default output: Markdown with embedded HTML blocks). See [`reference/cross-platform-pattern.md`](./reference/cross-platform-pattern.md) for the full asymmetry table.

## Configure

The plugin talks to a running P2E instance. It defaults to the hosted production endpoint at `https://p2e-mocha.vercel.app/api/mcp`. Point it at your own instance with `P2E_MCP_URL`:

```bash
export P2E_MCP_URL="https://<your-p2e-instance>/api/mcp"
```

Auth is handled by the host application's MCP flow on first use.

For Codex specifically, the plugin ships with the hosted production URL as its default MCP endpoint. If you want to point Codex at a different P2E instance, update the installed MCP entry or re-add it with a concrete URL rather than relying on shell-style `${VAR:-fallback}` expansion.

## Commands and skills at a glance

Every workflow below is one shared `workflows/<name>.md`. Claude invokes it via `commands/<name>.md`, Codex via `skills/<name>/SKILL.md` (or the plain-language `p2e` router), Cursor via `.cursor/skills/<name>/SKILL.md` (also `/p2e-<name>`).

| Workflow | Claude | Codex | Cursor | When to use |
|---|---|---|---|---|
| Bootstrap | `/p2e-bootstrap <doc-or-repo> [project=<slug>] [--mode={new,onboarding}] [--backfill-built] [--all] [--dry-run]` | `p2e-bootstrap` / NL | `/p2e-bootstrap` / NL | Start a new project map from a PRD (`--mode=new`, default) or onboard an existing repo (`--mode=onboarding`). Discovers the seeded persona + Foundation Flows; never creates Foundation phases. `--backfill-built` proposes DONE layers from merged PRs; `--all` fans story drafting across every UXO. |
| Add story | `/p2e-add-story <description>` | `p2e-add-story` / NL | `/p2e-add-story` / NL | Create a new story (`priority` defaults to unprioritized; stated urgency maps to `P0`/`P1`). The legacy `--fill <storyId>` path is deprecated and delegates to `/p2e-update-story` for one release. |
| Update story | `/p2e-update-story <story_id> [source=<prd-or-issue>] [--dry-run]` | `p2e-update-story` / NL | `/p2e-update-story` / NL | Thicken empty fields, steer populated ones, rename, re-parent, retag, adjust release, or re-prioritize on any existing story. Enforces the P-07-L1 thickness predicate on DRAFT → OPEN. |
| Work next | `/p2e-work-on-next [story_id=X-YY-LZ] [--full-team] [--dry-run]` | `p2e-work-on-next` / NL | `/p2e-work-on-next` / NL | Pick the top OPEN story by priority (`P0`→`P3`→null, then oldest-first; one global queue across all Flows), classify it, orchestrate implementation, and run the normal sync path. |
| Fix bugs | `/p2e-fix <bug-1>[, <bug-2>, …] [--dry-run] [--allow-band-aid="<bug-id>=<reason>"]` | `p2e-fix` / NL | `/p2e-fix` / NL | Resolve a batch of bugs by uprooting and re-implementing — per-bug fix-shape gate (Deleted / Replaced / Preserved / Band-aid rejected), root-cause discipline, verify-both-directions before completing. |
| Sync labels | `/p2e-sync-labels` | `p2e-sync-labels` / NL | `/p2e-sync-labels` / NL | Run explicit label reconciliation after external changes, partial runs, or missed automatic sync. |
| Sync drift | `/p2e-sync <story_id>` | `p2e-sync` / NL | `/p2e-sync` / NL | On-demand field-level reconciliation between a P2E story and its linked GitHub issue body (three directions — update GH from story, update story from GH, cherry-pick per field — plus abort; cherry-pick is Claude-only). |
| Manage UXO | `/p2e-manage-uxo <uxo_id> [--edit \| --add] [--phase=<title>] [--tier=<name>] [--dry-run]` | `p2e-manage-uxo` / NL | `/p2e-manage-uxo` / NL | Edit (`--edit`, default) or add (`--add`) a UXO via the canonical writing recipe with an annotated preview/confirm gate. The preview shows which Flow + phase the UXO sits in. |
| Archaeology | `/p2e-archaeology [repo-path] project=<slug> [--dry-run] [--max-pr-age=<days>] [--todo-age=<days>]` | `p2e-archaeology` / NL | `/p2e-archaeology` / NL | Autonomously onboard an existing repo — infer Flows/phases/UXOs, DONE layers from merged PRs, DRAFT stories from open gaps — no human interview. |
| Bind repo | `/p2e-bind` | `p2e-bind` / NL | `/p2e-bind` / NL | Derive `owner/name` from git remote, match against your P2E products, and write `.p2e/project.json`. Run once per checkout; commit the file. |
| Force pure HTML doc | `/p2e-html <followed by doc-producing skill>` | — | — | Force the next doc-producing skill to write a pure single-file HTML doc instead of the default rich Markdown. Claude-Code-specific. |
| Force plain MD doc | `/p2e-md <followed by doc-producing skill>` | — | — | Force the next doc-producing skill to write plain Markdown — no `<style>` preamble, no embedded HTML blocks (use for trivial config-only ADRs). Claude-Code-specific. |
| Convert MD → HTML | `/p2e-md-to-html <file.md>` | — | — | Convert a Markdown spec/design/ADR (plain or rich) to a pure single-file HTML doc using the `writing-rich-docs` HTML template. Source `.md` preserved. Claude-Code-specific. |
| Rich docs | (via `writing-rich-docs` skill) | `writing-rich-docs` skill | `/writing-rich-docs` | Rich human-review docs: Markdown carries structure/prose, embedded HTML blocks carry high-fidelity content (decision cards, comparison matrices, grids, callouts, inline-SVG diagrams). Bundled template + component snippets + a promote-or-not menu. The cross-platform doc-rendering surface (the three commands above are Claude-only overrides on top of it). |

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

The hook is Claude Code-only. Neither Codex nor Cursor implements `PreToolUse` hooks; this asymmetry is intentional and documented here (and in `reference/cross-platform-pattern.md`) rather than wired into `.codex-plugin/plugin.json` or `.cursor/`. On those hosts the `/p2e-work-on-next` workflow self-enforces the move-to-`IN_PROGRESS`-before-spawn discipline.

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
| `stories` | `list`, `get`, `create`, `update`, `delete`, `move` | Core story CRUD. `create` / `update` use an `items:[{...}]` array payload and accept `priority` (`"P0"`…`"P3"` or `null` = unprioritized; orders the `/p2e-work-on-next` queue). `list` supports multi-value filters (see below). `get` returns full detail including audit log, capabilities, and acceptance criteria. `move` re-parents a story to another UXO. |
| `criteria` | `list`, `get`, `create`, `update`, `delete` | Acceptance criteria attached to a story. |
| `capabilities` | `list`, `get`, `create`, `update`, `delete` | Story capabilities (INTRODUCES / MODIFIES / DEPRECATES change entries). |
| `relations` | `list`, `get`, `create`, `delete` | Inter-story relations (BUILDS_ON, DEPENDS_ON, SUPERSEDES, FIXES, etc.). |
| `products` | `list`, `get`, `create`, `update` | Product management (formerly *projects*) — UXO health summary, member roster, seeded Flows. `get` keys on `product_slug`. **Canonical** as of Patton v3. |
| `projects` | `list`, `get`, `create`, `update` | Deprecated alias for `products`, kept for one release. Keys on `project_slug`. Prefer `products` in new calls. |
| `flows` | `list`, `create`, `update`, `delete`, `reorder` | Flow CRUD. A Flow is a typed (`persona` \| `foundation`), ordered lane of phases under a Product. Every Product is seeded with a persona Flow and an immutable Foundation Flow; mutating a seeded Flow returns `FLOW_IMMUTABLE`. `get` is not implemented — use `list`. |
| `uxos` | `list`, `get`, `create`, `update`, `delete` | UXO (feature objective) CRUD. A UXO lives in a Phase, which lives in a Flow. `tier`/`tier_name` are still accepted on `create`/`update` but the tier axis is deprecated under Patton v3 — Flow membership (persona vs Foundation) is the meaningful structural axis. |
| `phases` | `list`, `get`, `create`, `update`, `delete` | Journey phases that contain UXOs. Each phase belongs to a Flow (the MCP tool does not yet expose a `flow_id` param — new persona phases land on the persona Flow's journey; the 8 Foundation phase slots are seeded and immutable). |
| `features` | `list`, `get`, `create`, `update`, `delete` | Features that group UXOs across phases. |
| `tags` | `list` | Project-scoped tag registry derived from story tags. |
| `members` | `list`, `invite`, `remove`, `update` | Product membership management. |
| `coverage` | `get` | UXO coverage report: counts of DONE/partial/gap stories per UXO. |
| `story_assets` | `list`, `get`, `create`, `delete` | File assets attached to a story (e.g. screenshots, specs). |
| `story_log` | `append` | Append a narrative log entry to a story (AC change, verification, blocker, decision). Append-only — no `update` or `delete`. Used by `/p2e-work-on-next` checkpoints and by `/p2e-fix` discipline-log entries. |
| `validate` | `run` | Run the P2E story-thickness predicate against a story and return failing clauses. |
| `create_github_issue` | — | Create a linked GitHub issue for a story (one-shot). |
| `sync_github_status` | — | Reconcile P2E story status with the linked GitHub issue label. |

> Note: only the `products`/`projects` tool changed its key parameter under Patton v3. Every other tool — `stories`, `uxos`, `phases`, `criteria`, `capabilities`, `coverage`, … — still takes `project_slug`. The `.p2e/project.json` binding anchors that one slug value (the same string serves as `project_slug` and `product_slug`).

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

All three filters compose with AND semantics against each other and with other filters (`phase`, `tier`, `uxo_id`, `feature_id`). `tier`/`tier_name` still filter but the tier axis is deprecated — filter by `phase` (which determines the Flow) instead.

## Flow / Foundation model

P2E's Patton v3 ontology, which this plugin tracks:

- A project is a **Product** (`mcp__p2e__products`, `product_slug`). The legacy `mcp__p2e__projects` tool / `project_slug` still works for one deprecation window.
- Every Product is seeded with exactly two **Flows** — a **persona Flow** (`type=persona`, the user-journey lane; named after the persona, e.g. "User" or "Default") and a **Foundation Flow** (`type=foundation`, name "Foundation"). The Foundation Flow and the earliest persona Flow are **system-immutable** — renaming, editing, deleting, or reordering them returns `FLOW_IMMUTABLE`.
- The Foundation Flow owns **8 fixed phase slots**: `Surfaces`, `Security`, `Data`, `Compute`, `Build-Deploy`, `Distribution`, `Observability`, `Cross-cutting`. Platform/infra UXOs live in those slots; user-journey UXOs live in persona-Flow phases. Tech-stack decisions are recorded as ADRs (`docs/adrs/`, MADR format) and linked from the relevant Foundation UXO via its `spec_file`.
- The story graph is **Story → UXO → Phase → Flow → Product**. A story's Flow membership is derived by following `story.uxo.phase.flow` — you never set a Flow on a story directly; you move its UXO to a phase on the target Flow.
- The **tier** axis is deprecated. `tier`/`tier_name` are still accepted by the MCP for back-compat, but Flow membership (persona vs Foundation) is now the meaningful structural axis.
- **`Story.priority`** (`P0` urgent → `P3` lowest, or `null` = unprioritized) orders the `/p2e-work-on-next` work queue: one global queue across all Flows, sorted `P0 → P1 → P2 → P3 → null`, then oldest-first. `priority` is separate from `sizing` (the effort estimate) and is never part of the thickness predicate.

`/p2e-bootstrap` and `/p2e-archaeology` discover the seeded Flows via `mcp__p2e__flows op=list` and route inferred phases/UXOs to the persona Flow or the matching Foundation slot — they never create new Foundation phases. `/p2e-work-on-next`'s first-turn briefing names the Flow (persona vs Foundation + slot) the story belongs to and follows any ADR linked from its UXO.

## Requirements

- a host that supports the plugin surface you want to use: Claude Code, Codex, or Cursor
- access to the P2E MCP server (a Patton v3 build for the `flows` / `products` tools — the plugin still works against older builds via the legacy `projects` tool, just without Flow discovery)
- `gh` CLI authenticated against the target P2E GitHub repo for issue / PR / label operations

## Links

- P2E main repo: https://github.com/bchoor/p2e
- Hosted demo: https://p2e-mocha.vercel.app
- Issue tracker: https://github.com/bchoor/p2e/issues
