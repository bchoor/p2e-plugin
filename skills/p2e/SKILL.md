---
name: p2e
description: Plain-language Codex router for P2E workflows. Route requests into bootstrap, add-story, work-on-next, or sync-labels using the shared workflow core.
---

# p2e router

Read these first:
- `workflows/p2e-policy.md`

Then choose the one best-fit workflow, load it, and execute it end-to-end:
- requests about starting or mapping a project -> read `workflows/p2e-bootstrap.md`, then follow that workflow exactly
- requests about creating or filling a story -> read `workflows/p2e-add-story.md`, then follow that workflow exactly
- requests about implementing planned work -> read `workflows/p2e-work-on-next.md` AND `workflows/p2e-first-turn-briefing.md`, then follow the work-on-next workflow exactly
- requests about label or issue reconciliation -> read `workflows/p2e-sync-labels.md`, then follow that workflow exactly

If the request is ambiguous, prefer the primary user intent and select the workflow that best matches the main goal.
If the request genuinely spans multiple workflows, choose the first required workflow, execute it fully, and note any follow-up workflow that may still be needed after it completes.
