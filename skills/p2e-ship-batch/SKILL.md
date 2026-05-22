---
name: p2e-ship-batch
description: Explicit Codex entrypoint for the P2E ship-batch workflow. Heavyweight batch ship — delegates per-story implementation to work-on-next, layers 360° verify, per-story PR + review, conditional security review (auto-detected from diff paths), and a rich-Markdown roll-up doc. Use when shipping a release with multiple stories under release=, phase=, or tag= filters.
---

# p2e-ship-batch

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-ship-batch.md`
- `workflows/p2e-work-on-next.md`
- `workflows/p2e-first-turn-briefing.md`

Execute the shared ship-batch workflow exactly. Phase B delegates to `workflows/p2e-work-on-next.md` without modification — do not fork briefing, status-gate, two-strike, or AC-toggle logic. The implementer deviation-reporting contract is enforced via the briefing's `## Deviation reporting` section so a hands-off batch run produces a fully-auditable story log.

## Codex-specific notes

- The `p2e-architect` and `p2e-staff-engineer` subagents are Claude Code natives. Where the workflow invokes them, inline the equivalent prompt as a sub-step in the same chat. The Phase F `--cut-release` handoff is Claude Code only — print the next step for the user to run manually.
- The `PreToolUse` status-gate hook is Claude Code only — Phase B inherits work-on-next's self-enforced MCP status discipline.
- `TaskCreate` / `TaskUpdate` are Claude Code natives — on Codex, the per-story tracking degrades to a chat-prose progress block printed at each phase boundary.
- `/p2e-verify-story` ships in v0.10.2 and works cross-platform — the Phase C UAT-report path is the same on Codex as on Claude Code. `/security-review` is user-installed; the Phase D security gate hard-skips with a logged DECISION entry when missing.

Cross-platform mirrors: `commands/p2e-ship-batch.md` (Claude), `.cursor/skills/p2e-ship-batch/SKILL.md` (Cursor).
