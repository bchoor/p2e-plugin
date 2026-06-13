---
name: p2e-work-on-next
description: Cursor entrypoint for the P2E work-on-next workflow (v2 supervisor). Picks the next open story/stories and runs the sequential fallback; --full-team enables architect+plan.
---

# p2e-work-on-next

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-work-on-next.md`
- `workflows/p2e-first-turn-briefing.md`

Execute the shared orchestrator workflow exactly, using the **sequential fallback** in `## Cross-platform fallback` (parallel story-lead waves and the dynamic-Workflow batch mode are Claude-Code-only).

## Cursor-specific notes

- Status discipline is self-enforced by the workflow (Phase 2a flips `IN_PROGRESS` before any story-lead is spawned) — confirm a story is IN_PROGRESS through MCP before starting its implementation. There is no `PreToolUse` hook backstop on any platform.
- Subagents (`p2e-architect`, `p2e-staff-engineer`, `p2e-story-lead`) are not native to Cursor. Inline their prompts as sub-steps in the same chat; emit one `kind: NOTE` story-log entry per lifecycle transition as the progress surface.
- Stories end at `IN_REVIEW`; never cut a release.

Cross-platform mirrors: `commands/p2e-work-on-next.md` (Claude), `skills/p2e-work-on-next/SKILL.md` (Codex).
