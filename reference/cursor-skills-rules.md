---
title: Cursor skills and rules reference (distilled)
hash: ref-cursor
status: living
date: 2026-05-10
owner: bchoor
sources:
  - https://cursor.com/docs/context/rules
  - https://cursor.com/docs/agent/chat/skills
---

# Cursor skills and rules reference

Distilled from Cursor docs. Refresh when upstream changes.

Cursor's surface is closer to Claude than Codex: it has both **skills** (`/`-invokable workflows, the modern equivalent of slash commands) and **rules** (always-on or context-attached guidance). It does not natively load Claude or Codex plugin manifests, so cross-platform compliance means shipping equivalent files in `.cursor/`.

## Layout

```
my-repo/
├── .cursor/
│   ├── skills/
│   │   └── <skill-name>/
│   │       └── SKILL.md
│   └── rules/
│       ├── <rule>.mdc
│       └── nested/<rule>.mdc
└── AGENTS.md           # optional, simplified always-on instructions
```

Cursor also reads from `~/.cursor/skills/` (global) and nested project paths like `apps/web/.cursor/skills/`.

## Skills (`.cursor/skills/<name>/SKILL.md`)

Frontmatter:

```yaml
---
name: skill-name
description: When and what this skill does.
paths:
  - "**/*.tsx"     # optional glob list — limits applicability
---
```

Invocation: type `/skill-name` in agent chat. Cursor migrated legacy slash commands to skills via `/migrate-to-skills`; new work should ship as skills, not commands.

## Rules (`.cursor/rules/<name>.mdc`)

Frontmatter (three fields, all optional but they determine how the rule activates):

```yaml
---
description: Explain rule purpose for agent relevance detection
globs: src/**/*.tsx, docs/**/*.md
alwaysApply: false
---
```

| Type | `alwaysApply` | `description` | `globs` | Trigger |
|------|---------------|---------------|---------|---------|
| Always Apply | `true` | — | — | Every chat session |
| Apply Intelligently | `false` | provided | omitted | Agent decides from description |
| Apply to Specific Files | `false` | — | provided | File matches glob |
| Apply Manually | `false` | omitted | omitted | `@rule-name` mention |

Glob syntax: `*` (single segment), `**` (recursive), comma-separated for multiple patterns.

## AGENTS.md

Simplified always-on instructions in repo root or subdirectories. No frontmatter. Overlaps in role with `.cursor/rules/*.mdc` `alwaysApply: true`.

## Discovery

- Skills: `/<name>` in chat
- Always-apply rules: every session
- Auto-attached rules: when matching files are open
- Agent-requested rules: model selects based on `description`
- Manual rules: `@<rule-name>`

## What this repo uses

- `.cursor/skills/<workflow>/SKILL.md` — one alias skill per workflow, mirrors the Codex skill, points at the same shared `workflows/<name>.md`
- `.cursor/rules/p2e-policy.mdc` — repo-wide policy rule (always-apply) summarizing scope and pointing at `workflows/p2e-policy.md`
- `scripts/install-p2e-cursor-skills.sh` — product-repo Cloud Agent helper: clone this plugin (outside the product git tree) and symlink skills/rules/workflows into the workspace from `.cursor/environment.json` `install` / `start --update`
- `AGENTS.md` — minimal pointer file so non-Cursor IDEs that read `AGENTS.md` (e.g. Codex CLI in some flows) get the same orientation

## Cross-platform compliance note

Cursor cannot read `.claude-plugin/plugin.json` or `.codex-plugin/plugin.json`. The pattern (see `cross-platform-pattern.md`) is to keep the **workflow definition** as the source of truth and ship a thin per-platform wrapper that points at it.
