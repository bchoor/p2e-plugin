# p2e-plugin — Claude Code, Codex, and Cursor plugin for P2E

This plugin connects [P2E](https://github.com/bchoor/p2e) story-map work to the P2E MCP server on Claude Code, Codex, and Cursor.

**v0.12+ ships a single skill: `p2e-mode`.** Read it at session start for entity model, MCP tools, story lifecycle, and the Coder→Verifier→Auditor→Human review pipeline. Legacy `/p2e-*` slash commands and granular workflow skills are removed.

It tracks the P2E **Patton v3 Flow/Foundation model**: every project is a *Product* with two seeded Flows — a persona Flow (the user-journey lane) and an immutable Foundation Flow (8 platform/infra slots). Stories carry a `priority` (`P0`…`P3`) that orders open work. See [Flow / Foundation model](#flow--foundation-model) below.

## How it works

| Surface | Path |
|---|---|
| Codex | `skills/p2e-mode/SKILL.md` |
| Cursor | `.cursor/skills/p2e-mode/SKILL.md` |
| Claude Code | read the same skill content via plugin install |

**Story lifecycle:** `DRAFT → OPEN → IN_PROGRESS → IN_REVIEW → DONE` (+ `BLOCKED`). The coder implements and ends at **IN_REVIEW**; verifier and auditor propose per-AC assessments; the human **Mark DONE** is the sole acceptance gate. Details in [`p2e-mode`](skills/p2e-mode/SKILL.md).

Product repos may own their own copy of `p2e-mode` under `.cursor/skills/` — the plugin sync skips linking when a repo-owned copy exists.

## Install in Claude Code

From inside a Claude Code session:

```text
/plugin marketplace add bchoor/p2e-plugin
/plugin install p2e@p2e-plugins
```

Pin the marketplace to a tag for stability:

```text
/plugin marketplace add bchoor/p2e-plugin@v0.12.2
/plugin install p2e@p2e-plugins
```

The marketplace is named `p2e-plugins`; the plugin itself is named `p2e`.

## Install in Codex

This repository includes a native Codex plugin manifest at [`.codex-plugin/plugin.json`](./.codex-plugin/plugin.json) plus the shared MCP config at [`.mcp.json`](./.mcp.json).

Codex uses the **`p2e-mode`** skill as the sole entry point. Read it at session start before any P2E MCP operations.

## Install in Cursor

Cursor reads the `.cursor/` directory directly. Clone or sync this repo so `.cursor/skills/p2e-mode/` and `.cursor/rules/p2e-policy.mdc` are visible from your project root.

- Read **`p2e-mode`** at session start — it replaces the legacy `/p2e-*` command menu
- The always-applied rule `.cursor/rules/p2e-policy.mdc` keeps Cursor aligned with Claude and Codex
- Point Cursor at the P2E MCP server via `.cursor/mcp.json` (or your global Cursor MCP config) using the same URL as [`.mcp.json`](./.mcp.json) — `https://p2e-mocha.vercel.app/api/mcp` by default

### Cloud Agents (product repos)

Do **not** put a skill path in `.env`. Hook the same `.cursor/environment.json` `install` / `start` scripts that already materialize `.env`:

```json
{
  "install": "git clone --depth 1 https://github.com/bchoor/p2e-plugin.git \"$HOME/p2e-plugin\" && bash \"$HOME/p2e-plugin/scripts/install-p2e-cursor-skills.sh\"",
  "start": "bash \"$HOME/p2e-plugin/scripts/install-p2e-cursor-skills.sh\" --update",
  "repositoryDependencies": ["github.com/bchoor/p2e-plugin"]
}
```

Append those commands to your existing `install` / `start` (keep your `.env` and dependency steps). `install` snapshots the clone into the Build; `start --update` pulls `main` at the beginning of each session so new Cloud Agents pick up plugin changes without a rebuild. The script symlinks **`p2e-mode`**, the always-apply rule, and merges MCP config into the product workspace. Symlinks are listed in `.git/info/exclude` so they are not committed.

Commit a `p2e` entry in the product repo's `.cursor/mcp.json` (same URL as [`.mcp.json`](./.mcp.json)) so MCP is present even before the script merges it.

## Bind a repo (`.p2e/project.json`)

Create `.p2e/project.json` at the repo root with your P2E product binding:

```json
{
  "slug": "your-product-slug",
  "github_repo": "owner/name"
}
```

Derive `github_repo` from `git remote get-url origin` and match `slug` against the P2E products you are a member of. Commit this file so all team members share the same binding.

Once the file is present, two plugin hooks activate automatically on Claude Code:

- **SessionStart** — injects a system-reminder at the start of every session naming the bound `project_slug` and `github_repo`.
- **PreToolUse** — intercepts every `mcp__plugin_p2e_p2e__*` tool call and blocks it if `project_slug` does not match the bound slug, printing a clear mismatch error with the bound value.

Neither hook does anything in repos that lack `.p2e/project.json` — non-P2E repos are unaffected.

## Configure

The plugin talks to a running P2E instance. It defaults to the hosted production endpoint at `https://p2e-mocha.vercel.app/api/mcp`. Point it at your own instance with `P2E_MCP_URL`:

```bash
export P2E_MCP_URL="https://<your-p2e-instance>/api/mcp"
```

Auth is handled by the host application's MCP flow on first use.

For Codex specifically, the plugin ships with the hosted production URL as its default MCP endpoint. If you want to point Codex at a different P2E instance, update the installed MCP entry or re-add it with a concrete URL rather than relying on shell-style `${VAR:-fallback}` expansion.

## MCP tool surface

The plugin exposes the P2E MCP server tools via `mcp__plugin_p2e_p2e__*`. Each tool accepts an `op` parameter to select the operation.

| Tool | Ops | Summary |
|------|-----|---------|
| `stories` | `list`, `get`, `create`, `update`, `delete`, `move` | Core story CRUD. `create` / `update` use an `items:[{...}]` array payload and accept `priority` (`"P0"`…`"P3"` or `null` = unprioritized). `update` also accepts `github_pr_url` (string or `null`) to manually set or clear a story's PR link. `list` supports multi-value filters (see below). `get` returns full detail including audit log, capabilities, and acceptance criteria. `move` re-parents a story to another UXO. |
| `criteria` | `list`, `get`, `create`, `update`, `delete`, `propose` | Acceptance criteria attached to a story. Agents use `op=propose` for verifier/auditor assessments. |
| `capabilities` | `list`, `get`, `create`, `update`, `delete` | Story capabilities (INTRODUCES / MODIFIES / DEPRECATES change entries). |
| `relations` | `list`, `get`, `create`, `delete` | Inter-story relations (BUILDS_ON, DEPENDS_ON, SUPERSEDES, FIXES, etc.). |
| `products` | `list`, `get`, `create`, `update` | Product management — UXO health summary, member roster, seeded Flows. **Canonical** as of Patton v3. |
| `projects` | `list`, `get`, `create`, `update` | Deprecated alias for `products`, kept for one release. Prefer `products` in new calls. |
| `flows` | `list`, `create`, `update`, `delete`, `reorder` | Flow CRUD. Every Product is seeded with a persona Flow and an immutable Foundation Flow. |
| `uxos` | `list`, `get`, `create`, `update`, `delete` | UXO (feature objective) CRUD. Flow membership (persona vs Foundation) is the meaningful structural axis. |
| `phases` | `list`, `get`, `create`, `update`, `delete` | Journey phases that contain UXOs. Foundation phase slots are seeded and immutable. |
| `features` | `list`, `get`, `create`, `update`, `delete` | Features that group UXOs across phases. |
| `tags` | `list` | Project-scoped tag registry derived from story tags. |
| `members` | `list`, `invite`, `remove`, `update` | Product membership management. |
| `coverage` | `get` | UXO coverage report: counts of DONE/partial/gap stories per UXO. |
| `story_assets` | `list`, `get`, `upload_url`, `link`, `create`, `delete` | File assets attached to a story. Preferred upload path for binary evidence: `op=upload_url` (signed-URL PUT to Vercel Blob). |
| `story_log` | `append` | Append a narrative log entry to a story. Append-only — no `update` or `delete`. |
| `evidence` | `validate_proof`, `template` | AC evidence proof contract validation and template generation. |
| `validate` | `run` | Run the P2E story-thickness predicate against a story and return failing clauses. |
| `create_github_issue` | — | Create a linked GitHub issue for a story (one-shot). |
| `sync_github_status` | — | Reconcile P2E story status with the linked GitHub issue label. |

> Note: only the `products`/`projects` tool changed its key parameter under Patton v3. Every other tool still takes `project_slug`. The `.p2e/project.json` binding anchors that one slug value.

### Multi-value `stories.list` example

Single-value filters (legacy, still work):

```json
{ "op": "list", "project_slug": "p2e", "status": "DONE", "release": "v0.9", "tag": "auth" }
```

Multi-value filters:

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
- `tags` + `tag_mode` — `tags` is a `string[]`; `tag_mode` is `"any"` (default, OR) or `"all"` (AND). Overrides single `tag`.

All three filters compose with AND semantics against each other and with other filters (`phase`, `uxo_id`, `feature_id`).

## Flow / Foundation model

P2E's Patton v3 ontology, which this plugin tracks:

- A project is a **Product** (`mcp__p2e__products`, `product_slug`). The legacy `mcp__p2e__projects` tool still works for one deprecation window.
- Every Product is seeded with exactly two **Flows** — a **persona Flow** (`type=persona`, the user-journey lane) and a **Foundation Flow** (`type=foundation`, name "Foundation"). The Foundation Flow and the earliest persona Flow are **system-immutable**.
- The Foundation Flow owns **8 fixed phase slots**: `Surfaces`, `Security`, `Data`, `Compute`, `Build-Deploy`, `Distribution`, `Observability`, `Cross-cutting`. Never create Foundation phases via MCP.
- The story graph is **Story → UXO → Phase → Flow → Product**. A story's Flow membership is derived by following `story.uxo.phase.flow`.
- The **tier** axis is deprecated. Flow membership (persona vs Foundation) is the meaningful structural axis.
- **`Story.priority`** (`P0` urgent → `P3` lowest, or `null` = unprioritized) orders open work across all Flows, sorted `P0 → P1 → P2 → P3 → null`, then oldest-first. `priority` is separate from `sizing`.

## Documentation map

| Location | What it covers |
|---|---|
| **This repo** (`p2e-plugin`) | Install, MCP config, `p2e-mode` skill, platform schema reference |
| **Product repos** | Domain depth: `docs/P2E-lifecycle.md`, `docs/P2E-handover.md`, review-view design |
| **`docs/archive/`** | Pre-v0.12 historical feature docs (work-on-next v2, rich-html-docs, etc.) |

## Requirements

- a host that supports the plugin surface you want to use: Claude Code, Codex, or Cursor
- access to the P2E MCP server (a Patton v3 build for the `flows` / `products` tools)
- `gh` CLI authenticated against the target P2E GitHub repo for issue / PR / label operations

## Links

- P2E main repo: https://github.com/bchoor/p2e
- Hosted demo: https://p2e-mocha.vercel.app
- Issue tracker: https://github.com/bchoor/p2e/issues
