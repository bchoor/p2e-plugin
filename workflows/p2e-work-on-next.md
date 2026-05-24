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
2. Sort the resulting thick OPEN stories by the canonical priority order: **`priority` ascending (P0 → P1 → P2 → P3 → null)**, then by **`createdAt` ascending** (oldest first) as the tiebreak. This is **one global queue across all Flows** — do NOT pre-filter or group by Flow before picking; the agent picks the single top story regardless of which Flow (persona vs Foundation) its UXO sits in. The `release`, `phase`, `tag`, and `story_id` filters passed by the user narrow the candidate set on top of this sort, but do not change the ordering rule. (`Story.priority` values: `"P0"` = urgent … `"P3"` = lowest; `null` = unprioritized, always last.)
3. For each candidate, fetch full detail (`op=get`) and apply the thin-draft check (`## Thin drafts` in policy) before classification.
4. Apply the **thick-gate** (`## Thick-gate` in policy): refuse any story where `isThick=false` or `status != "OPEN"`; direct the user to `/p2e-update-story` and stop.
5. Apply the adaptive router (`## Adaptive router` in policy) to choose the track and, using the shape-aware rule, decide whether the architect + `superpowers:writing-plans` run or are skipped.
6. Present the selected queue, routing decisions, and wave plan to the user.
7. Ensure the work is happening in an appropriate git worktree for the batch.
8. If batch size >= 2, ask the staff engineer for a wave plan and use it to organize the run.
9. For each wave:
   - **9a. Move selected stories to IN_PROGRESS** — run `/p2e-update-story <story_id> status=IN_PROGRESS` for each story in the wave. This triggers the lifecycle label reconciliation phase in `workflows/p2e-update-story.md`: the MCP status write, the GitHub label flip (`ready` → `in-progress`), and the local cache refresh all happen as part of this step. Do not skip this step or inline the `op=update` call directly — the label and cache writes are required side effects.
   - **9b. Materialize first-turn briefing** — per `workflows/p2e-first-turn-briefing.md` for each story in the wave. This includes surfacing the story's **Flow membership** (persona Flow vs Foundation Flow, and if Foundation which of the 8 slots: Surfaces / Security / Data / Compute / Build-Deploy / Distribution / Observability / Cross-cutting) so the implementer understands the nature of the work before starting.
   - **9c. Spawn implementers** — with the briefing as turn 1, and gate the wave with verification.

   > Note: the `hooks/pre-agent-spawn-story-status.sh` PreToolUse hook enforces step 9a independently — an implementer spawn (Agent tool call) against a story still at `OPEN` will be blocked with a remediation message pointing at step 9a. The hook short-circuits automatically for `subagent_type` values in `{p2e-architect, p2e-staff-engineer, rescue}` and when `P2E_SKIP_STATUS_GATE=1` is set.
10. If the architect was skipped for a single-story thick run, the implementer self-plans inline from the briefing (no external `writing-plans` call).
11. On a passing story, move it to `IN_REVIEW` (`op=update status=IN_REVIEW`), toggle its acceptance criteria (`mcp__p2e__criteria op=toggle`), and post the summary back to the linked issue.
12. On a failing verification, apply the two-strike rule (`## Two-strike escalation` in policy): one re-brief, then on the second failure set `status=BLOCKED` and route to `p2e-architect` (Claude Code caller) or `codex:rescue` (Codex caller).

## Per-story task ladder

Each story progresses through exactly 6 steps. The orchestrator creates one `TaskCreate` task per step as it enters that step and `TaskUpdate`s it through `pending → in_progress → completed`. Task titles follow the prefix convention `[#<story-id>] <N>/6 <step-name>` (e.g., `[#DR-08-L8] 1/6 Brief & confirm`), which is the grouping mechanism for multi-story waves — `TaskCreate` has no native nesting so the prefix is the only board-level filter.

### Step 1 — Brief & confirm

**TaskCreate:** `[#<story-id>] 1/6 Brief & confirm`
**TaskUpdate:** `pending → in_progress` on entering step 9b; `→ completed` when the thick-gate passes and the first-turn briefing (`workflows/p2e-first-turn-briefing.md`) has been rendered to the user.
**story_log:** If the briefing surfaces `OPEN_QUESTIONS` (ambiguous AC, missing capabilities, dependency risk), emit one `kind:NOTE` entry per question before marking step 1 completed:
```
mcp__p2e__story_log op=append project_slug=<slug> items=[{"story_id":"<id>","kind":"NOTE","author":"orchestrator","message":"OPEN_QUESTION: <question text>"}]
```
No log entry is written for a clean brief — the thick-gate pass is recorded in `story.status`.

### Step 2 — Implement

**TaskCreate:** `[#<story-id>] 2/6 Implement`
**TaskUpdate:** `pending → in_progress` when the implementer agent(s) are spawned; `→ completed` when the implementation is ready for verification (existing behavior, no change).
**story_log:** None from the orchestrator at this step. The implementer emits `DECISION` and `SCOPE_CHANGE` entries as needed per `workflows/p2e-first-turn-briefing.md#deviation-reporting`.

### Step 3 — Verify & fix

**TaskCreate:** `[#<story-id>] 3/6 Verify & fix`
**TaskUpdate:** `pending → in_progress` when the verification command fires; `→ completed` when verification passes — at which point step 11 logic runs (`IN_REVIEW` flip + AC toggles).
**story_log:** Two entries on a passing run (existing checkpoint contract from `## Story log checkpoint policy`): one `AC_CHANGE` per criterion toggled, and one `VERIFICATION` entry immediately before the `IN_REVIEW` flip. On a failing run, the two-strike `BLOCKER` entries apply as documented above. No new kinds.

### Step 4 — Commit + PR (new — codify)

**TaskCreate:** `[#<story-id>] 4/6 Commit + PR`
**TaskUpdate:** `pending → in_progress` when the commit command starts; `→ completed` when `gh pr create` returns a PR URL. Capture the PR URL in the task description via `TaskUpdate`.
**Ordering contract:** step 3 must be `completed` (story at `IN_REVIEW`) before step 4 fires. Do not commit and push a story that has not passed verification.
**Commit rules:**
- Commit any uncommitted implementation work on the feature branch.
- Branch MUST be named `feat/<STORY-ID>-<topic-kebab>` for step 6's zero-flag closeout (see **Branch-name convention dependency** below).
- **NEVER include a version bump commit on the feature branch** — that is `/p2e-cut-release`'s Phase B job. A version bump on a feature branch will conflict with the release process.
- Push: `git push -u origin HEAD`
- Open PR: `gh pr create --fill` — the `--fill` flag uses the branch name and commit messages to populate title and body. If a GitHub issue is linked to the story, add `--body` text referencing `Closes #<issue-number>`.
**story_log:** None required. The PR URL is a GitHub artifact, not a P2E log event.

### Step 5 — /review-pr (new — codify)

**TaskCreate:** `[#<story-id>] 5/6 /review-pr`
**TaskUpdate:** `pending → in_progress` when `/review-pr` is invoked; `→ completed` when the orchestrator has addressed all findings (or triaged each as won't-fix with a rationale).
**Ordering contract:** step 4 must be `completed` (PR open) before step 5 fires. `/review-pr` targets an open PR — if step 4 has not pushed yet, step 5 has nothing to review. Enforce this sequentially; do not fire both in parallel.
**Invocation:** invoke `pr-review-toolkit:review-pr` (the `/review-pr` command from the `pr-review-toolkit` plugin). The orchestrator receives findings back and addresses each before marking step 5 done. **This is NOT `/ultrareview`** — that command is user-triggered and billed; the orchestrator never auto-invokes it. If the user wants `/ultrareview`, they trigger it manually between steps 4 and 5.
**story_log:** If a review finding results in a material code change (new logic, dropped AC, added scope), emit a `DECISION` or `SCOPE_CHANGE` entry as appropriate. Minor style/naming fixes do not require a log entry.

### Step 6 — /p2e-cut-release

**TaskCreate:** `[#<story-id>] 6/6 /p2e-cut-release`
**TaskUpdate:** `pending → in_progress` when `/p2e-cut-release` is invoked; `→ completed` when `/p2e-cut-release`'s Phase E confirms `IN_REVIEW → DONE` (or the equivalent terminal state for the release).
**Invocation:** invoke the shipped `/p2e-cut-release` command (no flags needed when the branch follows the naming convention). It absorbs push + PR + CI + squash-merge + bump + tag + `gh release create` + screenshots + story closeout + teardown in one atomic call. See `workflows/p2e-cut-release.md` for the full Phase 0 + A–F contract.
**Human authorization:** `/p2e-cut-release` has its own `AskUserQuestion` release-plan gate (its workflow step 8). That gate IS the human authorization for the release. The orchestrator trusts it and does NOT add an additional turn boundary before invoking. Invoke step 6 directly after step 5 completes.
**story_log:** `/p2e-cut-release` Phase E writes the closeout `VERIFICATION` entry and flips GH labels automatically. The orchestrator does NOT write a duplicate entry for the DONE transition — that would be noise against a state already in `story.status` + `AuditLog`.
**Multi-story batch:** when you genuinely need one release to cover several stories, use `workflows/p2e-ship-batch.md` (`/p2e-ship-batch`) instead. The ladder is per-story by design; batch releases are a separate concern.

### Cross-platform fallback

The ladder above is canonical for **Claude Code**, which has `TaskCreate` / `TaskUpdate`. Other platforms degrade gracefully:

- **Claude Code** — `TaskCreate` / `TaskUpdate` as documented above. All 6 steps visible in the task list, persisted across session restarts.
- **Codex** — use Codex's equivalent task primitive (`update_plan` or whichever is current). Same title-prefix convention `[#<story-id>] <N>/6 <step-name>`.
- **Cursor** — no task primitive. Emit a `kind:NOTE` story_log entry at each step transition as the fallback progress signal:
  ```
  mcp__p2e__story_log op=append project_slug=<slug> items=[{"story_id":"<id>","kind":"NOTE","author":"orchestrator","message":"Step 4/6 Commit+PR — completed. PR: <url>"}]
  ```
  One NOTE per step completed; do NOT write NOTEs for intermediate state within a step (only on `→ completed`). This keeps the log scannable without bloating it.

Document platform asymmetries; do not paper them over. Cursor's fallback is coarser-grained than the Claude Code task board — that is expected and acceptable.

### Branch-name convention dependency

Name the worktree branch `feat/<STORY-ID>-<topic-kebab>` (e.g., `feat/P-07-L8-task-ladder`). `/p2e-cut-release` matches the regex `[A-Z]+-[0-9]+-L[0-9]+` against the branch name to auto-infer `--story-id`. When the regex matches, no flag is needed and Phase E closeout is automatic. When it does not match, `/p2e-cut-release` falls through to its `AskUserQuestion` story-picker — the release still works, but the user must confirm the story ID manually.

If a worktree branch was auto-named (e.g., `claude/laughing-bartik-...`), run `/update-branch-name` before step 4. The rename must preserve the story-id segment in the new name. Renaming after step 4 (after the PR is already open) requires updating the PR base branch reference and re-pushing — do it before opening the PR to avoid the complication.

### Multi-story wave verbosity

With N stories × 6 steps = 6N tasks in the task list. The `[#<story-id>]` prefix is the only grouping mechanism — `TaskCreate` has no native nesting or sub-task hierarchy. For a 5-story wave that yields 30 tasks, the prefix enables filtering: scan for `[#DR-08-L8]` to see that story's 6 tasks in sequence. The verbosity is intentional: each task represents a discrete, durable checkpoint that survives a session restart.

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

## Story log checkpoint policy

### Intent

The story log is a narrative of events during implementation that **do not already have their own first-class surface**. State transitions (`OPEN → IN_PROGRESS → IN_REVIEW`) are recorded in `story.status` and `AuditLog`; duplicating them here would be noise. The log carries the things that would otherwise scatter across GH comments and agent transcripts: AC changes, verifications, blockers, decisions, scope changes, and user notes.

The `kind` chip is a taxonomy so a skimmer can filter ("show me blockers", "show me scope changes") — it must honestly categorize the event.

### Orchestrator-authored checkpoints (exactly 3)

The orchestrator writes to `mcp__p2e__story_log` (op=append) at these 3 checkpoints per story. No per-tool-call logging; no entries for status transitions alone.

#### Checkpoint 1 — AC toggle (step 11, after verification passes, one entry per AC toggled)

```json
{ "kind": "AC_CHANGE", "author": "orchestrator", "message": "Toggled AC<n>: <criterion text>" }
```

Replace `<n>` with the criterion ordinal (1-based) and `<criterion text>` with the exact criterion text.

#### Checkpoint 2 — Verification pass (step 11, right before IN_REVIEW flip)

```json
{ "kind": "VERIFICATION", "author": "orchestrator", "message": "Verified: <verificationCmd> — <short summary, e.g. tests passed, build clean>" }
```

One entry per verification run that passed. The state flip to `IN_REVIEW` itself is NOT logged — it lives in `story.status` + `AuditLog`.

#### Checkpoint 3 — Verification failure (step 12)

Strike 1 (first failure, re-brief issued):
```json
{ "kind": "BLOCKER", "author": "orchestrator", "message": "Verification failed (strike 1): <short reason>" }
```

Strike 2 (second failure, story set to BLOCKED):
```json
{ "kind": "BLOCKER", "author": "orchestrator", "message": "Verification failed (strike 2): <short reason> — escalated to architect" }
```

The state flip to `BLOCKED` on strike 2 is NOT a separate log entry — it's implied by the strike-2 BLOCKER message and recorded in `story.status`.

### Self-reporting kinds (implementer or human)

These kinds are NOT orchestrator checkpoints — the orchestrator never emits them automatically. They are emitted by the implementer (per `workflows/p2e-first-turn-briefing.md#deviation-reporting`) or written by humans via the UI or MCP:

- `DECISION` — judgment call that does NOT change the spec (e.g., "picked Approach A because...", "overrode architect's recommendation", "deferred caching layer to follow-up story"). Authored by `"implementer"`, `"user"`, or `"orchestrator"` (the last only when the orchestrator itself made the call, e.g., `--no-security` override under `/p2e-ship-batch`).
- `SCOPE_CHANGE` — mid-flight change to the story spec itself (e.g., "dropped retroactive backfill, covered in Non-goals", "added AC for empty-state copy after design review"). Authored by `"implementer"` or `"user"`.
- `NOTE` — free-form observation worth preserving (e.g., orchestrator-authored audit notes from `/p2e-ship-batch`'s scope-change audit, or human-authored context).

The implementer must emit `SCOPE_CHANGE` / `DECISION` entries **before** making the deviating change, not after — see `workflows/p2e-first-turn-briefing.md#deviation-reporting` for the contract and MCP call shape.

### MCP call shape

All checkpoint writes use `items:[{...}]` form (never flat form — arrays/bools round-trip correctly in items form only):

```
mcp__p2e__story_log op=append project_slug=<slug> items=[{ "story_id": "<id>", "kind": "...", "author": "orchestrator", "message": "..." }]
```

### Notes

- State transitions (`OPEN → IN_PROGRESS → IN_REVIEW → DONE`) are NOT log events. Read them from `story.status` or `AuditLog`.
- The MCP tool is append-only; there is no op=update or op=delete for log entries.
- `stories op=get` returns the last 50 log entries inline as `logEntries` + `logCount` — no second round-trip needed.
