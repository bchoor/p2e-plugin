# P2E Sync-Labels Workflow

This is the explicit reconcile workflow for label drift. Use it after external changes, after partial runs, after missed automatic sync, or whenever the orchestrator did not have enough context to finish label reconciliation safely.

## Purpose

- Reconcile issue labels after a batch or after manual changes.
- Keep the label state aligned with the story state.
- Remain idempotent and safe to re-run.

## Workflow

1. Resolve the target repository from the project configuration.
2. Enumerate closed issues that still carry the review label, optionally narrowing to a specific PR or story subset.
3. Resolve the merge context for each candidate. If no merge sha can be resolved, skip that issue and report it.
4. For each eligible issue, remove `review`, add `done`, and post a landed-on-main comment that includes the merge sha.
5. Print a compact summary of what was reconciled and what was skipped.

## Targeting rules

- The workflow may run against a specific PR when the user wants to reconcile one batch.
- The workflow may also run against a curated set of stories after partial completion or external edits.
- If a story or issue is already synchronized, the workflow must leave it alone.

## Idempotency

- Re-running the workflow should not duplicate comments for issues that are already reconciled.
- If an issue no longer carries the review label, treat it as already done and skip it.

## Safety

- This workflow only reconciles labels and comments.
- It must not mutate the P2E map itself.

