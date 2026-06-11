---
name: p2e-add-story
description: Cursor entrypoint for the P2E add-story workflow. Thick by default — all thick-spec fields populated at add time. --thin opts out to fast placeholder capture. --dry-run previews only.
---

# p2e-add-story

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-add-story.md`
- `workflows/p2e-thicken.md`
- `workflows/p2e-sizing-rubric.md`

Execute the shared workflow exactly.

## Cursor-specific notes

Cursor has no `AskUserQuestion` or `superpowers:brainstorming` primitive. Where the workflow specifies brainstorming escalation, batch the 2–4 questions into a single chat message and parse the user's reply inline. Cross-platform mirrors: `commands/p2e-add-story.md` (Claude), `skills/p2e-add-story/SKILL.md` (Codex).

The default mode is **thick** — graph context is gathered and all six thick-spec fields are populated before the preview. Pass `--thin` to opt out to fast placeholder capture. The legacy `--thick` flag is accepted as an explicit alias for the default thick mode (a no-op), so existing invocations keep working.
