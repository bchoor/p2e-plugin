---
name: p2e-work-on-next
description: Cursor entrypoint for the P2E work-on-next workflow. Pick the next open P2E story (or one by story_id=) and run the orchestrator; --full-team enables architect+plan.
---

# p2e-work-on-next

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-work-on-next.md`
- `workflows/p2e-first-turn-briefing.md`

Execute the shared orchestrator workflow exactly.

## Cursor-specific notes

- The Claude `PreToolUse` status-gate hook does NOT run in Cursor. The workflow's status discipline is self-enforced — confirm status transitions through MCP before dispatching implementer work.
- Subagents (`p2e-architect`, `p2e-staff-engineer`) are not native to Cursor. Where the workflow invokes them, inline the equivalent prompt as a sub-step in the same chat (or escalate to the Claude/Codex hosts that support them natively).

Cross-platform mirrors: `commands/p2e-work-on-next.md` (Claude), `skills/p2e-work-on-next/SKILL.md` (Codex).
