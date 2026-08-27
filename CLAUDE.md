# CLAUDE.md — p2e-plugin

Project-specific instructions for Claude Code (and any AI agent reading this file). Personal/global rules in `~/.claude/CLAUDE.md` apply on top of these — when the two conflict, project rules win for repo-specific concerns and personal rules win for general behavior.

## What this repo is

A multi-platform plugin that surfaces P2E story-map guidance on Claude Code, Codex, and Cursor — all backed by the shared P2E MCP server.

**v0.12+:** Single **`p2e-mode`** skill. Legacy `/p2e-*` commands, granular workflow skills, and `workflows/` are removed. See CHANGELOG v0.12.0.

## The p2e-mode contract (mandatory)

Read **`skills/p2e-mode/SKILL.md`** (Codex) or **`.cursor/skills/p2e-mode/SKILL.md`** (Cursor) at session start. Product repos may extend with their own docs under `docs/`.

When changing P2E operating rules, update **p2e-mode** in both `skills/` and `.cursor/skills/`, plus `CHANGELOG.md` and plugin manifests.

### Where to find reference material

- `reference/cross-platform-pattern.md` — historical pattern (pre-v0.12); kept for schema reference
- `reference/claude-code-plugins.md` — Claude Code plugin schema (distilled)
- `reference/codex-plugins.md` — Codex plugin schema (distilled)
- `reference/cursor-skills-rules.md` — Cursor skills/rules schema (distilled)

## Source-of-truth layout

```
skills/p2e-mode/            ← sole Codex skill (entry point)
.cursor/skills/p2e-mode/    ← Cursor mirror
.cursor/rules/              ← Cursor always-apply rules
agents/                     ← subagents + CONTRACTS.md (reference-only orchestration contracts)
hooks/                      ← Claude Code hooks (project-slug validator, session start)
.mcp.json                   ← shared MCP server config
.claude-plugin/plugin.json  ← Claude Code manifest
.codex-plugin/plugin.json   ← Codex manifest
AGENTS.md                   ← always-on orientation file
reference/                  ← platform schema reference
docs/archive/               ← pre-v0.12 historical feature docs
```

## Hard rules

- **Behavior lives in `p2e-mode`.** Domain posture and invariants go in the skill; agent-executable contracts go in `agents/CONTRACTS.md`.
- **MCP is authoritative.** P2E reads/writes go through `mcp__p2e__*`. No parallel REST or local-file paths.
- **Bind first.** If `.p2e/project.json` is missing in a target repo, create a binding before any project-scoped MCP operation.
- **No platform forks of behavior.** Document asymmetries (hooks not on Codex/Cursor; agents invoked differently) in the skill or agent files, not as silent fallbacks.

## Known platform asymmetries

These differences are real and documented — don't try to paper over them:

| Capability | Claude Code | Codex | Cursor |
|---|---|---|---|
| Skills | yes (`skills/`) | yes (`skills/`) | yes (`.cursor/skills/`) |
| Subagents | yes (`agents/`) | invoke via skill content | invoke via skill content |
| `PreToolUse` hooks | yes | no | no |
| `SessionStart` hooks | yes | partial | no |
| MCP servers | yes (`.mcp.json`) | yes (`.mcp.json`) | yes (`.cursor/mcp.json` or shared) |
| Task primitive (orchestrator progress board) | yes (`TaskCreate`/`TaskUpdate`) | yes (`update_plan` or equivalent) | no — fall back to per-step `kind: NOTE` `story_log` entries |

Workflows that depend on a hook (e.g. the P2E project-slug validator) must degrade gracefully on platforms that lack it.

## P2E Flow/Foundation model (Patton v3)

This plugin tracks the P2E backend's Patton v3 ontology — keep skill prose consistent with it:

- A project is a **Product**: `mcp__p2e__products` / `product_slug` is canonical; `mcp__p2e__projects` / `project_slug` is a deprecated alias kept for one release. **Every other MCP tool still takes `project_slug`** — do not rename it. The `.p2e/project.json` binding anchors that one slug value.
- Every Product is seeded with two **Flows**: a **persona Flow** (`type=persona`, user-journey lane) and an immutable **Foundation Flow** (`type=foundation`, 8 fixed phase slots). Never create Foundation phases via MCP.
- Story graph: **Story → UXO → Phase → Flow → Product**. `Story.priority` (`P0`…`P3` / `null`) orders open work and is distinct from `sizing`.
- Tech-stack decisions live as ADRs linked from Foundation UXOs via `spec_file`.

## When you change something

| Change | Files to touch |
|---|---|
| p2e-mode behavior | Both `skills/p2e-mode/` mirrors + CHANGELOG + manifests |
| Agent contract | `agents/CONTRACTS.md` + affected `agents/*.md` |
| Cursor policy | `.cursor/rules/p2e-policy.mdc` |
| Platform schema change (upstream) | Matching `reference/<platform>.md` (refresh date + source URL in the header) |
| New hook (Claude only) | `hooks/hooks.json` + document the asymmetry in affected agent/skill files |

## Commit and PR conventions

- Branch naming: `<type>/<topic-kebab>` per the personal CLAUDE.md (`feat/`, `spec/`, `design/`).
- Repo allowlist: stay in `bchoor/*` — this repo is `bchoor/p2e-plugin`.
- "Cut a release" → use the repo release workflow (do not improvise version bumps; the marketplace and Codex install surface both pin from version tags).
- Markdown: no hard wraps in paragraphs. Front-matter required on `docs/feat-*` files.

## Pointers

- README: install + MCP tool surface
- `skills/p2e-mode/SKILL.md`: operating mode (entry point)
- `agents/CONTRACTS.md`: orchestration contracts for subagents
- `reference/`: platform schemas + historical cross-platform pattern
- `agents/`: subagent definitions
- `hooks/`: project-slug validator + session start (Claude Code only)
