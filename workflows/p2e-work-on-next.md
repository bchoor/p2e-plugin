# P2E Work-On-Next Workflow

This is the canonical orchestrator workflow. Adapter-specific entrypoints should map to this shared behavior. The workflow selects planned stories, classifies them, coordinates implementation waves, and reconciles labels at the end of the run when enough context is available.

## Purpose

- Select one or more planned stories from the queue.
- Route each story through the adaptive model and agent hierarchy.
- Execute work in waves with per-story gate checks.
- Auto-sync labels at the end of the batch when issue and merge context is sufficient.
- Fall back to the explicit label-sync workflow when automatic reconciliation is not safe.

## Workflow

1. Query the planned queue with the optional release, phase, tag, or story filter.
2. Sort or narrow the queue deterministically when multiple candidates are available.
3. For each candidate, fetch story details and apply the thin-draft check before classification.
4. Apply the adaptive router to choose the track and model.
5. Present the queue to the user and let them choose one or more stories.
6. Ensure the work is happening in an appropriate git worktree for the batch.
7. When the batch size warrants it, ask the staff engineer for a wave plan and use it to organize the run.
8. For each wave, mark stories `PARTIAL`, spawn implementers, and gate the wave with verification.
9. On a passing story, move it to `BUILT`, toggle its acceptance criteria, and post the summary back to the linked issue.
10. On a failing or deferred story, leave it `PARTIAL` and comment with the relevant failure or hold reason.

## Thin-draft handling

- If a story has no acceptance criteria and no capabilities, treat it as a thin draft.
- The wrapper should stop and ask what to do before routing a thin draft into implementation.
- The user may flesh it, proceed as-is, or skip it.

## End-of-run sync

- If the batch has enough issue and merge context to reconcile labels safely, perform the label sync automatically at the end of the run.
- If that context is missing, incomplete, or ambiguous, do not guess.
- In the fallback case, the wrapper should route to `p2e-sync-labels` as the explicit reconcile step.

## Dry-run behavior

- Dry-run is read-only.
- The workflow should still show the selected queue, routing decisions, wave plan, and the writes it would have performed.
- Dry-run must skip all side effects, including issue updates and label reconciliation.

