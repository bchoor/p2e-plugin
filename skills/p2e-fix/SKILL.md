---
name: p2e-fix
description: Explicit Codex entrypoint for the P2E fix workflow. Resolve one or more bugs by uprooting and re-implementing rather than layering patches; enforces a fix-shape gate per bug.
---

# p2e-fix

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-fix.md`

Execute the shared workflow exactly.

## Phase 2 primitive (Codex)

Use the native debugging primitive for the root-cause phase. If root cause is not reached after one diagnostic pass, escalate to `codex:rescue` for a deeper investigation, then stop if still uncertain — do not move past the fix-shape gate without a written cause.

## Cross-platform note

Mirror skills exist as `commands/p2e-fix.md` (Claude Code) and `.cursor/skills/p2e-fix/SKILL.md` (Cursor). All three read the same `workflows/p2e-fix.md`.
