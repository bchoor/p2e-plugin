---
name: p2e-work-on-next
description: Explicit Codex entrypoint for the P2E work-on-next workflow (v2 supervisor).
---

# p2e-work-on-next

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-work-on-next.md`
- `workflows/p2e-first-turn-briefing.md`

Execute the shared orchestrator workflow exactly. Codex has no nested Agent tree or dynamic Workflow tool — use the documented **sequential fallback** in `## Cross-platform fallback`: per story, brief → implement inline (adaptive skill matrix still applies) → verify with one retry → commit + PR → tiered review; track progress with `update_plan` (one entry per story). Stories end at `IN_REVIEW`; never cut a release.
