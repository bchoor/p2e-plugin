---
name: p2e-manage-uxo
description: Cursor entrypoint for the P2E manage-uxo workflow. Edit an existing UXO (--edit, default) or add a new one (--add) via the canonical writing recipe with an annotated preview + confirm gate.
---

# p2e-manage-uxo

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-manage-uxo.md`
- `workflows/p2e-uxo-recipe.md`

Execute the shared manage-uxo workflow exactly.

## Cursor-specific notes

Cursor has no `AskUserQuestion` or `superpowers:brainstorming` primitive. Where the workflow specifies brainstorming escalation, batch the 2–4 questions into a single chat message and parse the user's reply inline. Cross-platform mirrors: `commands/p2e-manage-uxo.md` (Claude), `skills/p2e-manage-uxo/SKILL.md` (Codex).
