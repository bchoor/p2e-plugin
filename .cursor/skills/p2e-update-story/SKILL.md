---
name: p2e-update-story
description: Cursor entrypoint for the P2E update-story workflow. Thicken an existing P2E story's spec from a PRD, issue URL, or spec YAML; --dry-run previews only.
---

# p2e-update-story

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-update-story.md`
- `workflows/p2e-thicken.md`
- `workflows/p2e-sizing-rubric.md`

Execute the shared workflow exactly.

## Cursor-specific notes

Cursor has no `AskUserQuestion` or `superpowers:brainstorming` primitive. Where the workflow specifies brainstorming escalation, batch the 2–4 questions into a single chat message and parse the user's reply inline. Cross-platform mirrors: `commands/p2e-update-story.md` (Claude), `skills/p2e-update-story/SKILL.md` (Codex).

On the Thicken path, graph context is gathered per `workflows/p2e-thicken.md ## Context gathering` (anchor = `story_id`) before drafting thick-spec fields.
