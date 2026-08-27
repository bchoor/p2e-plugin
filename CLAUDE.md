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
agents/                     ← subagents (story-lead, verifier, auditor, architect, staff-engineer)
hooks/                      ← Claude Code hooks (project-slug validator, session start)
.mcp.json                   ← shared MCP server config
.claude-plugin/plugin.json  ← Claude Code manifest
.codex-plugin/plugin.json   ← Codex manifest
AGENTS.md                   ← always-on orientation file
reference/                  ← platform schema reference
```

## Hard rules

- **Behavior lives in `workflows/`.** Never put domain logic in a wrapper file.
- **MCP is authoritative.** P2E reads/writes go through `mcp__p2e__*`. No parallel REST or local-file paths.
- **Bind first.** If `.p2e/project.json` is missing in a target repo, run `/p2e-bind` before any project-scoped MCP operation.
- **Cross-platform compliance on every change.** New workflow → four files. Behavior change → update the workflow once; all three platforms inherit. Schema/wrapper change on one platform → update the matching reference doc in `reference/`.
- **No platform forks of behavior.** Document asymmetries (hooks not on Codex/Cursor; agents invoked differently) in the workflow body or wrapper, not as silent fallbacks.

## Known platform asymmetries

These are real and documented — don't try to paper over them.

| Capability | Claude Code | Codex | Cursor |
|---|---|---|---|
| Slash commands | yes (`commands/`) | no — use skills | yes (skills are `/`-invokable) |
| Skills | yes (`skills/`) | yes (`skills/`) | yes (`.cursor/skills/`) |
| Subagents | yes (`agents/`) | invoke via skill content | invoke via skill content |
| `PreToolUse` hooks | yes | no | no |
| `SessionStart` hooks | yes | partial | no |
| MCP servers | yes (`.mcp.json`) | yes (`.mcp.json`) | yes (`.cursor/mcp.json` or shared) |
| Task primitive (orchestrator progress board) | yes (`TaskCreate`/`TaskUpdate`) | yes (`update_plan` or equivalent) | no — fall back to per-step `kind: NOTE` `story_log` entries |

Workflows that depend on a hook (e.g. the P2E project-slug validator) must degrade gracefully on platforms that lack it.

Doc-rendering surface: the cross-platform skill is `writing-rich-docs` (`skills/writing-rich-docs/`, mirrored at `.cursor/skills/writing-rich-docs/`), which any host can invoke. Its **default output is rich Markdown** — a `.md` file with embedded HTML blocks: Markdown carries the structure/prose (the cheap ~50%), HTML blocks carry the high-fidelity rest (decision cards, comparison matrices, grids, callouts, inline-SVG diagrams). The skill ships a bundled template (`references/template.md` — front-matter + a scoped `<style>` preamble + a section scaffold), component snippets (`references/components.md` — each with its MD-native alternative and a "promote when" trigger), and a promote-or-not menu (`references/strategies.md`). The behavior contract is `workflows/p2e-rich-docs.md`.

One more documented asymmetry: the `/p2e-html`, `/p2e-md`, and `/p2e-md-to-html` commands are **Claude-Code-specific** — they override that default rich-Markdown output (`/p2e-html` → pure single-file HTML from `references/template.html`; `/p2e-md` → plain Markdown, no `<style>` preamble or HTML blocks; `/p2e-md-to-html` → convert a Markdown doc to pure HTML). They rely on `~/.claude/CLAUDE.md`, which only Claude Code reads, and are NOT mirrored to Codex or Cursor.

## P2E Flow/Foundation model (Patton v3)

This plugin tracks the P2E backend's Patton v3 ontology — keep workflow prose consistent with it:

- A project is a **Product**: `mcp__p2e__products` / `product_slug` is canonical; `mcp__p2e__projects` / `project_slug` is a deprecated alias kept for one release. **Every other MCP tool (`stories`, `uxos`, `phases`, `criteria`, `capabilities`, `coverage`, …) is unchanged and still takes `project_slug`** — do not rename it. The `.p2e/project.json` binding anchors that one slug value.
- Every Product is seeded with two **Flows**: a **persona Flow** (`type=persona`, user-journey lane) and an immutable **Foundation Flow** (`type=foundation`, 8 fixed phase slots: `Surfaces`, `Security`, `Data`, `Compute`, `Build-Deploy`, `Distribution`, `Observability`, `Cross-cutting`). The Foundation Flow and the earliest persona Flow are system-immutable (`FLOW_IMMUTABLE`). New tool: `mcp__p2e__flows` (`list`/`create`/`update`/`delete`/`reorder`; no `get` — use `list`). Never create new Foundation phases via MCP.
- Story graph: **Story → UXO → Phase → Flow → Product**. The tier axis is deprecated (`tier`/`tier_name` still accepted, but Flow membership persona-vs-Foundation is the meaningful axis). `Story.priority` (`P0`…`P3` / `null`) orders the `/p2e-work-on-next` queue (one global queue across all Flows; `P0`→`P3`→`null`, then oldest-first) and is distinct from `sizing` (the effort estimate).
- Tech-stack decisions live as ADRs (`docs/adrs/`, MADR format) linked from Foundation UXOs via `spec_file`; the first-turn briefing follows those links.

## When you change something

| Change | Files to touch |
|---|---|
| New workflow | All four wrappers + workflow + p2e router skill + README + CHANGELOG |
| Workflow behavior change | `workflows/<name>.md` only (all platforms inherit) |
| New shared rule across workflows | `workflows/p2e-policy.md` + cross-reference from any affected workflow |
| Platform schema change (upstream) | Matching `reference/<platform>.md` (refresh date + source URL in the header) |
| New always-on guidance for Cursor | `.cursor/rules/<name>.mdc` (alwaysApply or globs) |
| New hook (Claude only) | `hooks/hooks.json` + document the asymmetry in any workflow that depends on it |

## Commit and PR conventions

- Branch naming: `<type>/<topic-kebab>` per the personal CLAUDE.md (`feat/`, `spec/`, `design/`).
- Repo allowlist: stay in `bchoor/*` — this repo is `bchoor/p2e-plugin`.
- "Cut a release" → `/cut-release` (do not improvise version bumps; the marketplace and Codex install surface both pin from version tags).
- Markdown: no hard wraps in paragraphs. Front-matter required on `docs/feat-*` files.

## Pointers

- README: install + command table + MCP tool surface
- `workflows/p2e-policy.md`: shared operating rules (MCP access, status lifecycle, escalation, thick-gate, two-strike rule)
- `reference/`: platform schemas + cross-platform pattern
- `agents/`: `p2e-architect`, `p2e-staff-engineer` subagents
- `hooks/`: project-slug validator + session start (Claude Code only)
