---
title: Cross-platform compliance pattern
hash: ref-xplat-pattern
status: historical
date: 2026-05-10
owner: bchoor
---

# Cross-platform compliance pattern

> **Historical (pre-v0.12):** Superseded by the single **`p2e-mode`** skill in v0.12.0. Kept for schema reference only — do not add new workflows using this pattern.

**The rule (v0.11 and earlier):** every workflow this plugin shipped had to be invocable from Claude Code, Codex, AND Cursor — without behavior drift. The way we achieved that was the **shared-workflow + thin-wrapper** pattern.

## The shape

```
workflows/<name>.md             ← single source of truth (behavior)
commands/<name>.md              ← Claude Code slash command (thin wrapper)
skills/<name>/SKILL.md          ← Codex skill (thin wrapper)
.cursor/skills/<name>/SKILL.md  ← Cursor skill (thin wrapper)
```

Every wrapper is ~10 lines: frontmatter + a sentence saying "read `workflows/<name>.md` and execute it exactly." No domain logic in the wrappers.

## Why this works

- **Behavior lives once** — fixing a bug in the workflow updates all three platforms simultaneously.
- **Each platform's discovery mechanism is honored** — Claude finds `commands/`, Codex finds `skills/` via `.codex-plugin/plugin.json`, Cursor finds `.cursor/skills/`.
- **No platform forks** — no `if-codex` branches, no Claude-only fallbacks inside workflow logic. Platform-specific behavior (e.g. agent invocation syntax, hook availability) is documented in the workflow itself or hidden behind a small adapter section.

## The checklist

When adding a new workflow `<name>`, you MUST create all four files:

- [ ] `workflows/<name>.md` — full behavior (inputs, phases, MCP calls, GitHub side effects, output)
- [ ] `commands/<name>.md` — Claude command, frontmatter `name`/`description`/`argument-hint`
- [ ] `skills/<name>/SKILL.md` — Codex skill, frontmatter `name`/`description`
- [ ] `.cursor/skills/<name>/SKILL.md` — Cursor skill, frontmatter `name`/`description` (+ optional `paths`)

Plus update:

- [ ] `skills/p2e/SKILL.md` AND `.cursor/skills/p2e/SKILL.md` — add a routing line to BOTH routers so Codex and Cursor can dispatch plain-language requests
- [ ] `.cursor/rules/p2e-policy.mdc` — if the workflow changes scope or surface, reflect it
- [ ] `scripts/validate-plugin.py` — add the new files to `expected_commands` / `expected_workflows` / `expected_skill_paths` / `expected_cursor_skill_paths` and to `workflow_map`; extend the router-reference tuple
- [ ] `README.md` — add a row to the commands-and-skills table (with the Cursor column)
- [ ] `CHANGELOG.md` — note the new surface

If any of those is missing, the workflow is non-compliant — even if it works in your editor today. Run `python3 scripts/validate-plugin.py` to confirm.

## Wrapper templates

**Claude command (`commands/<name>.md`):**

```markdown
---
name: <name>
description: <one-line>
argument-hint: <args>
---

# /<name>

This command is a thin wrapper over `workflows/p2e-policy.md` and `workflows/<name>.md`.
Follow the shared workflow contract exactly.
```

**Codex skill (`skills/<name>/SKILL.md`):**

```markdown
---
name: <name>
description: Explicit Codex entrypoint for the <name> workflow.
---

# <name>

Read:
- `workflows/p2e-policy.md`
- `workflows/<name>.md`

Execute the shared workflow exactly.
```

**Cursor skill (`.cursor/skills/<name>/SKILL.md`):**

```markdown
---
name: <name>
description: Cursor entrypoint for the <name> workflow.
---

# <name>

Read:
- `workflows/p2e-policy.md`
- `workflows/<name>.md`

Execute the shared workflow exactly.
```

## Platform asymmetries (documented, not fixed)

These differences are real and intentional. Don't try to paper over them:

| Surface | Claude Code | Codex | Cursor |
|---|---|---|---|
| Slash commands | yes (`commands/`) | no — use skills | yes (skills are `/`-invokable) |
| Skills | yes (`skills/`) | yes (`skills/`) | yes (`.cursor/skills/`) |
| `PreToolUse` hooks | yes | no | no |
| `SessionStart` hooks | yes | partial | no |
| MCP servers | yes (`.mcp.json`) | yes (`.mcp.json`) | yes (`.cursor/mcp.json` or shared) |

When a workflow depends on a hook (e.g. the project-slug validator), document the asymmetry in the workflow itself and degrade gracefully on platforms that lack the hook.

## When to deviate

Hand-roll a per-platform wrapper only when:

1. The platform's invocation syntax forces it (e.g. agent dispatch differs).
2. A capability is missing on one platform AND the workflow can degrade safely.

In both cases, the deviation goes in the wrapper, NOT the shared workflow. The shared workflow stays platform-neutral.
