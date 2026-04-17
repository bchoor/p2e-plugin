# P2E Work-On-Next Workflow

This is the canonical orchestrator workflow. Adapter-specific entrypoints should map to this shared behavior. The workflow selects open stories, classifies them, coordinates implementation waves, and reconciles labels at the end of the run when enough context is available.

## Purpose

- Select one or more open stories from the queue.
- Route each story through the adaptive model and agent hierarchy.
- Execute work in waves with per-story gate checks.
- Auto-sync labels at the end of the batch when issue and merge context is sufficient.
- Fall back to the explicit label-sync workflow when automatic reconciliation is not safe.

## Workflow

1. Query the planned queue (`mcp__p2e__stories op=list status=OPEN`) with the optional release, phase, tag, or story filter.
2. Sort or narrow the queue deterministically when multiple candidates are available.
3. For each candidate, fetch full detail (`op=get`) and apply the thin-draft check (`## Thin drafts` in policy) before classification.
4. Apply the **thick-gate** (`## Thick-gate` in policy): refuse any story where `isThick=false` or `status != "OPEN"`; direct the user to `/p2e-update-story` and stop.
5. Apply the adaptive router (`## Adaptive router` in policy) to choose the track and, using the shape-aware rule, decide whether the architect + `superpowers:writing-plans` run or are skipped.
6. Present the selected queue, routing decisions, and wave plan to the user.
7. Ensure the work is happening in an appropriate git worktree for the batch.
8. If batch size >= 2, ask the staff engineer for a wave plan and use it to organize the run.
9. For each wave:
   - **9a. Move selected stories to IN_PROGRESS** — run `/p2e-update-story <story_id> status=IN_PROGRESS` for each story in the wave. This triggers the lifecycle label reconciliation phase in `workflows/p2e-update-story.md`: the MCP status write, the GitHub label flip (`ready` → `in-progress`), and the local cache refresh all happen as part of this step. Do not skip this step or inline the `op=update` call directly — the label and cache writes are required side effects.
   - **9b. Materialize first-turn briefing** — per `workflows/p2e-first-turn-briefing.md` for each story in the wave.
   - **9c. Spawn implementers** — with the briefing as turn 1, and gate the wave with verification.

   > Note: the `hooks/pre-agent-spawn-story-status.sh` PreToolUse hook enforces step 9a independently — an implementer spawn (Agent tool call) against a story still at `OPEN` will be blocked with a remediation message pointing at step 9a. The hook short-circuits automatically for `subagent_type` values in `{p2e-architect, p2e-staff-engineer, rescue}` and when `P2E_SKIP_STATUS_GATE=1` is set.
10. If the architect was skipped for a single-story thick run, the implementer self-plans inline from the briefing (no external `writing-plans` call).
11. On a passing story, move it to `IN_REVIEW` (`op=update status=IN_REVIEW`), toggle its acceptance criteria (`mcp__p2e__criteria op=toggle`), and post the summary back to the linked issue.
12. On a failing verification, apply the two-strike rule (`## Two-strike escalation` in policy): one re-brief, then on the second failure set `status=BLOCKED` and route to `p2e-architect` (Claude Code caller) or `codex:rescue` (Codex caller).

## Thin-draft handling

- If a story has no acceptance criteria and no capabilities, treat it as a thin draft. The story remains at `DRAFT` or `OPEN` but is considered under-specified for implementation.
- The wrapper should stop and ask what to do before routing a thin draft into implementation.
- The user may flesh it out (using `/p2e-update-story`), proceed as-is, or skip it.

## End-of-run sync

- If the batch has enough issue and merge context to reconcile labels safely, perform the label sync automatically at the end of the run.
- If that context is missing, incomplete, or ambiguous, do not guess.
- In the fallback case, the wrapper should route to `p2e-sync-labels` as the explicit reconcile step.
- Stories completing the run are at `IN_REVIEW`; reconcile labels to match that state.

## Dry-run behavior

- Dry-run is read-only.
- The workflow should still show the selected queue, routing decisions, wave plan, and the writes it would have performed.
- Dry-run must skip all side effects, including issue updates and label reconciliation.
- Dry-run still shows the first-turn briefing it WOULD have handed to each implementer.
