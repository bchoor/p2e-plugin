---
name: p2e-add-story
description: Cursor entrypoint for the P2E add-story workflow. Draft a new P2E story from a free-form description; --thick fills all thick-spec fields at add time; --dry-run previews only.
---

# p2e-add-story

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-add-story.md`
- `workflows/p2e-sizing-rubric.md`

Execute the shared workflow exactly.

## Cursor-specific notes

Cursor has no `AskUserQuestion` or `superpowers:brainstorming` primitive. Where the workflow specifies brainstorming escalation, batch the 2–4 questions into a single chat message and parse the user's reply inline. Cross-platform mirrors: `commands/p2e-add-story.md` (Claude), `skills/p2e-add-story/SKILL.md` (Codex).
