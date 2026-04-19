---
name: p2e
description: Plain-language Codex router for P2E workflows. Route requests into bootstrap, add-story, update-story, work-on-next, or sync-labels using the shared workflow core.
---

# p2e router

Read these first:
- `workflows/p2e-policy.md`

Then choose the one best-fit workflow, load it, and execute it end-to-end:
- requests about starting or mapping a project -> read `workflows/p2e-bootstrap.md`, then follow that workflow exactly
- requests about creating a new story -> read `workflows/p2e-add-story.md`, then follow that workflow exactly
- requests about updating, thickening, steering, renaming, re-parenting, or retagging an existing story -> read `workflows/p2e-update-story.md`, then follow that workflow exactly (this is the canonical path for what used to be `/p2e-add-story --fill`)
- requests about implementing planned work -> read `workflows/p2e-work-on-next.md` AND `workflows/p2e-first-turn-briefing.md`, then follow the work-on-next workflow exactly
- requests about label or lifecycle reconciliation -> read `workflows/p2e-sync-labels.md`, then follow that workflow exactly
- requests about drift reconciliation between a story and its linked GitHub issue body (on-demand, field-level) -> read `workflows/p2e-sync.md`, then follow that workflow exactly

## Persona routing (work-on-next only)

When executing `workflows/p2e-work-on-next.md`, this is the persona invocation matrix:

| Persona | Default | Skip when |
| --- | --- | --- |
| `p2e-architect` | Standard / Architectural tracks | Story `constraints` does NOT contain `approach-review` AND caller did NOT pass `--full-team` |
| `superpowers:writing-plans` | Multi-story batches OR architect ran | Single-story thick run with architect skipped (see `workflows/p2e-policy.md#self-plan-inline`) |
| `p2e-staff-engineer` | Batch size ≥ 2 | Batch size = 1 |
| `codex:rescue` | Two-strike escalation when caller is Codex | Caller is Claude Code (architect handles escalation instead) |

Fast-track stays lightweight: no architect, no staff engineer, no writing-plans regardless of opt-in flags.

If the request is ambiguous, prefer the primary user intent and select the workflow that best matches the main goal.
If the request genuinely spans multiple workflows, choose the first required workflow, execute it fully, and note any follow-up workflow that may still be needed after it completes.
