# p2e-plugin — Claude Code and Codex plugin for P2E

This plugin routes [P2E](https://github.com/bchoor/p2e) story-map work through the P2E MCP server on both Claude Code and Codex.

Primary workflows:

- `p2e` — Codex plain-language router
- `/p2e-bootstrap` and `p2e-bootstrap` — supports `--mode={new,onboarding}`, `--backfill-built`, and `--all`
- `/p2e-add-story` and `p2e-add-story`
- `/p2e-update-story` and `p2e-update-story` — thicken or steer any existing story (replaces `/p2e-add-story --fill`)
- `/p2e-work-on-next` and `p2e-work-on-next`
- `/p2e-sync-labels` and `p2e-sync-labels`

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

## Requirements

- a host that supports the plugin surface you want to use: Claude Code or Codex
- access to the P2E MCP server
- `gh` CLI authenticated against the target P2E GitHub repo for issue / PR / label operations

## Links

- P2E main repo: https://github.com/bchoor/p2e
- Hosted demo: https://p2e-mocha.vercel.app
- Issue tracker: https://github.com/bchoor/p2e/issues
