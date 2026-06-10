---
name: p2e-ship-batch
description: Cursor entrypoint for the P2E ship-batch workflow. Heavyweight batch ship — delegates per-story implementation to work-on-next, layers 360° verify, per-story PR + review, conditional security review (auto-detected from diff paths), and a rich-Markdown roll-up doc. Use when shipping a release with multiple stories under release=, phase=, or tag= filters.
---

# p2e-ship-batch

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-ship-batch.md`
- `workflows/p2e-work-on-next.md`
- `workflows/p2e-first-turn-briefing.md`

Execute the shared ship-batch workflow exactly. Phase B delegates to `workflows/p2e-work-on-next.md` without modification — do not fork briefing, status-gate, verify-gate, or label-sync logic. The implementer deviation-reporting contract is enforced via the briefing's `## Deviation reporting` section so a hands-off batch run produces a fully-auditable story log.

## Cursor-specific notes

- The Claude `PreToolUse` status-gate hook does NOT run in Cursor. Phase B inherits work-on-next's self-enforced MCP status discipline — confirm `OPEN → IN_PROGRESS` transitions through MCP before dispatching implementer work.
- The `p2e-architect` and `p2e-staff-engineer` subagents are not native to Cursor. Where the workflow invokes them, inline the equivalent prompt as a sub-step in the same chat (or escalate to the Claude/Codex hosts that support them natively).
- `TaskCreate` / `TaskUpdate` are Claude Code natives — on Cursor, the per-story tracking degrades to a chat-prose progress block printed at each phase boundary.
- Phase F `--cut-release` auto-handoff is Claude Code only. On Cursor, the workflow prints the next step for the user to run manually.
- `/p2e-verify-story` ships in v0.10.2 and works cross-platform — the Phase C UAT-report path is the same on Cursor as on Claude Code. `/security-review` is user-installed; the Phase D security gate hard-skips with a logged DECISION entry when missing.

Cross-platform mirrors: `commands/p2e-ship-batch.md` (Claude), `skills/p2e-ship-batch/SKILL.md` (Codex).
