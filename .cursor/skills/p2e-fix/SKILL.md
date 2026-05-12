---
name: p2e-fix
description: Cursor entrypoint for the P2E fix workflow. Resolve one or more bugs by uprooting and re-implementing rather than layering patches; enforces a fix-shape gate per bug.
---

# p2e-fix

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-fix.md`

Execute the shared workflow exactly.

## Phase 2 primitive (Cursor)

Use the host's debugging skill if one is available. If not, apply the four-field root-cause checklist (Symptom / Mechanism / Cause / Blast radius) directly from the workflow before moving past the fix-shape gate. Do not proceed without a written cause.

## Cross-platform note

Mirror entrypoints exist as `commands/p2e-fix.md` (Claude Code) and `skills/p2e-fix/SKILL.md` (Codex). All three read the same `workflows/p2e-fix.md`.
