# P2E Work-On-Next Workflow

This is the canonical orchestrator workflow. All three platforms (Claude Code, Codex, Cursor) inherit behavior from this file. Adapter-specific wrappers are thin pointers — domain logic lives here.

The main session acts as the **supervisor**: it selects and gates stories, plans waves, dispatches `p2e-story-lead` subagents, and reviews their structured reports. The supervisor never implements. Each story-lead owns one story's lifecycle end-to-end — from plan through reviewed PR — and returns a JSON report. The supervisor processes reports between waves and flips story status.

Recommend `/model fable` (high-effort) for the supervisor session; `opus` is acceptable. Surface this recommendation once at run start if the active session model is below `opus` — do not block on it.

## Arguments

- `release=<tag>` — filter candidates to stories linked to a release.
- `phase=<name>` — filter candidates to a specific phase.
- `tag=<tag>` — filter candidates by tag.
- `story_id=<id>` — select a specific story, skipping the queue sort.
- `limit=N` — select up to N stories this run (default: 1).
- `--full-team` — forces the architect + `superpowers:writing-plans` path for all eligible stories.
- `--workflow` — forces dynamic-Workflow batch mode; auto-selected at N ≥ 4.
- `--dry-run` — read-only preview; see `## Dry-run behavior`.

## Phase 0 — Select & gate

1. Query the candidate pool: `mcp__p2e__stories op=list status=OPEN` with any `release`, `phase`, `tag`, or `story_id` filters passed by the user.
2. Sort by the canonical priority order: **`priority` ascending (P0 → P1 → P2 → P3 → null)**, then by **`createdAt` ascending** (oldest first) as the tiebreak. This is **one global queue across all Flows** — do NOT pre-filter or group by Flow before picking; the supervisor picks the top `limit` stories regardless of which Flow (persona vs Foundation) their UXO sits in. (`Story.priority` values: `"P0"` = urgent … `"P3"` = lowest; `null` = unprioritized, always last.)
3. Take the top `limit` stories from the sorted result.
4. For each candidate, fetch full detail (`mcp__p2e__stories op=get`) and apply the thin-draft check (`## Thin drafts` in policy) before classification.
5. Apply the **thick-gate** (`## Thick-gate` in policy): refuse any story where `isThick=false` or `status != "OPEN"`; direct the user to `/p2e-update-story` and stop.
6. Apply the adaptive router (`## Adaptive router` in policy) to choose the track per story, and apply the shape-aware rule to decide whether architect + `superpowers:writing-plans` run or are skipped.

## Phase 1 — Plan & confirm

1. **Wave plan** (when N ≥ 2): dispatch `p2e-staff-engineer` (model: `opus`) with all selected story ids and their first-turn briefings. Parse the JSON output for `waves`, `files_touched`, and `collisions`. If the JSON contains `{"error":"cycle",...}`, surface the cycle to the user and stop.
2. **Architect + writing-plans** (opt-in per shape-aware rule): for each story where `constraints` contains `approach-review` OR `--full-team` was passed, dispatch `p2e-architect` and `superpowers:writing-plans` before dispatch. The resulting sketch is appended to that story's turn-1 briefing.
3. **Ensure a batch worktree exists.** If running from `main`, create an appropriately named worktree before proceeding. The branch name follows the convention in `## Branch-name convention`.
4. **Confirm gate** (one turn with the user): present the following in a single summary before any writes:
   - Selected queue (story id, title, track, model per the `## Model routing` in policy)
   - Skill-matrix hits per story (from `## Adaptive skill matrix` in policy)
   - Wave plan and any file collisions flagged by staff-engineer
   - Review tier per story (from `## Review tiering` in policy)
   - Explicit notice: **this run ends at `IN_REVIEW` — no release is cut automatically; use `/p2e-cut-release` when you are ready to ship**
5. **Create the task board.** One `TaskCreate` per story — title: `[#<story-id>] <story title>`, initial status: `pending`. The task description is the per-story progress surface; update it via `TaskUpdate` at each lifecycle transition: `briefed → implementing → verifying → PR open → in review → IN_REVIEW` (or `BLOCKED (strike 2)` on escalation).

## Phase 2 — Execute waves

Process one wave at a time. Never fire wave k+1 before every story in wave k is closed (report received and processed in Phase 3) or blocked.

### 2a — Status flip

For each story in the wave, run `/p2e-update-story <story_id> status=IN_PROGRESS`. This triggers the lifecycle label reconciliation in `workflows/p2e-update-story.md`: the MCP status write, the GitHub label flip (`ready` → `in-progress`), and the local cache refresh all happen as required side effects. Do not skip this step or inline the `op=update` call directly.

> **Note:** this status flip IS the dispatch gate — it must complete before any `p2e-story-lead` is spawned, because a story-lead is the implementer this discipline exists for. The flip is self-enforced by this workflow on every platform (there is no `PreToolUse` hook backstop); spawning an implementer against a story still at `OPEN` is a workflow violation. Phase 2a must flip `IN_PROGRESS` first.

### 2b — Briefing

Materialize the first-turn briefing per `workflows/p2e-first-turn-briefing.md` for each story in the wave (Flow membership surfaced, unchanged). If any briefing surfaces `OPEN_QUESTIONS`, emit one `kind: NOTE` story-log entry per question and resolve them with the user **before** dispatching story-leads — leads cannot ask the user mid-flight.

### 2c — Dispatch

Dispatch one `p2e-story-lead` per story, **in parallel within the wave**, each with `isolation: worktree`. Model per the policy model routing table (`## Model routing`): `sonnet` for Fast/Standard tracks, `opus` for Architectural. The briefing (plus architect sketch if produced) is the turn-1 message. Update each story's task via `TaskUpdate` to `in_progress`.

### 2d — Workflow batch mode (N ≥ 4 or `--workflow`)

When the run selects N ≥ 4 stories, or `--workflow` is passed, the supervisor compiles **one dynamic Workflow invocation per wave** from the staff-engineer JSON instead of direct Agent dispatches. Skeleton (verbatim):

```js
export const meta = {
  name: 'p2e-wave-exec',
  description: 'Execute one P2E story wave via story-lead agents',
  phases: [{ title: 'Wave' }],
}
const reports = await parallel(args.stories.map(s => () =>
  agent(s.briefing, {
    agentType: 'p2e-story-lead', label: `story:${s.id}`, phase: 'Wave',
    isolation: 'worktree', model: s.model, schema: args.report_schema,
  })))
return { reports: reports.filter(Boolean) }
```

The supervisor processes reports between waves (Phase 3) — never fire wave k+1 before wave k's stories are closed or blocked. Workflow mode is Claude-Code-only; the slash-command instruction in this workflow is the user's opt-in. See `## Cross-platform fallback` for Codex/Cursor behavior.

## Phase 3 — Close per story

On receiving each story-lead report, the supervisor processes it immediately (do not batch all of wave k before processing — process each report as it arrives).

### `outcome: "pass"`

The story-lead ran the verify gate inside its lifecycle (verificationCmd + consumer sweep + tiered review tool + adaptive fix loop). The supervisor's Phase 3 responsibilities are the close-out steps after the gate:

1. Review the report's `acceptance_criteria` array against the story's ACs — spot-check evidence, do not rubber-stamp.
2. Record per-AC verdicts via `mcp__p2e__criteria op=verdict` for each criterion in the report (see `## Story log checkpoint policy` Checkpoint 1). Use the evidence from `report.acceptance_criteria[n].evidence` as the `note` field. Do NOT use `op=toggle` — verdicts replace toggles.
3. Write Checkpoint 2 (VERIFICATION) story-log entry (see `## Story log checkpoint policy`).
4. Write the DEVIATIONS story-log entry (see `## Orchestrator DEVIATIONS checkpoint` in policy). If the story-lead's report `deviations` array is non-empty, summarize those entries; otherwise write `"DEVIATIONS: none"`.
5. Flip the story to `IN_REVIEW`: `mcp__p2e__stories op=update status=IN_REVIEW`.
6. Post the summary and PR URL to the linked GitHub issue.
7. `TaskUpdate` the story's task to `completed`.

### `outcome: "blocked"`

The story-lead's adaptive fix loop exited non-pass (stall, oscillation, or 6-round cap) — this is **strike 1** from the supervisor's perspective. The story-lead already wrote one `kind: BLOCKER` (`"author":"implementer"`) entry summarizing the fix-loop rounds and final open-problem count.

1. Write a `kind: NOTE` (`"author":"orchestrator"`) strike-1 context entry naming the blocking problem and the architect approach being tried next.
2. Route to `p2e-architect` for a fresh approach (Claude Code) or `codex:rescue` (Codex). The architect produces an implementation sketch; dispatch a new story-lead attempt (or inline implementer on Codex/Cursor) with that sketch.
3. If the second attempt also exits BLOCKED — **strike 2**: write the strike-2 BLOCKER checkpoint (see `## Story log checkpoint policy` Checkpoint 3), set `mcp__p2e__stories op=update status=BLOCKED`, post the failure summary to the linked GitHub issue, and `TaskUpdate` the story's task description to `BLOCKED (strike 2)` (leave task status `in_progress`).
4. If the second attempt passes: continue with the normal `outcome: "pass"` close-out steps above.

## Story-lead dispatch contract

The story-lead (`agents/p2e-story-lead.md`) receives the following at dispatch:
- **Turn-1 message:** the first-turn briefing (per `workflows/p2e-first-turn-briefing.md`) for this story, plus any architect sketch when one was produced.
- **Story id** and **project slug**.
- **Track** (Fast / Standard / Architectural) and **review tier** (from `## Review tiering` in policy).
- **Verification command** (`story.verificationCmd` or the track default from `## Verification matrix` in policy).
- **Branch name**: `feat/<STORY-ID>-<topic-kebab>` (supervisor provides this; the lead renames the worktree branch before pushing if it doesn't match).

The story-lead's 5-step lifecycle (defined in `agents/p2e-story-lead.md`): plan via the adaptive skill matrix → implement via nested workers → run the verify gate (verificationCmd + consumer-impact sweep + tiered review tool + adaptive fix loop per policy) → commit + PR (ordering per risk class in `## Review tiering`) → return structured report.

The story-lead's final message is a single JSON report block the supervisor parses:

```json
{
  "story_id": "X-00-L0",
  "outcome": "pass | blocked",
  "branch": "feat/X-00-L0-topic",
  "pr_url": "https://github.com/... | null",
  "verification": { "cmd": "...", "result": "pass | fail", "summary": "..." },
  "acceptance_criteria": [{ "ordinal": 1, "met": true, "evidence": "..." }],
  "review": { "tool": "code-review | review-pr", "findings_addressed": 0, "wont_fix": [{ "finding": "...", "rationale": "..." }], "security_review": "run | skipped" },
  "deviations": ["story_log entries already written by the lead (DECISION/SCOPE_CHANGE/strike-1 BLOCKER)"],
  "files_touched": ["..."],
  "blocked_reason": null
}
```

The supervisor never delegates to a story-lead that has not been gated through Phase 0 + Phase 1 (thick-gate + wave plan).

## Phase 4 — End of run

1. **Label sync:** reconcile GitHub issue labels at end of run per `## End-of-run sync` rules. Stories that completed the run are at `IN_REVIEW`; labels must reflect that state. When context is insufficient, route to `p2e-sync-labels` explicitly.
2. **Run summary:** emit a table of (story id, outcome, PR URL, review findings addressed, security review status).
3. **Explicit statement:** the orchestrator **never invokes `/p2e-cut-release` or `/ultrareview`**. Stories completing the run sit at `IN_REVIEW` awaiting human acceptance and a user-triggered release. When you are ready to ship, run `/p2e-cut-release`.

## Branch-name convention

Name the worktree branch `feat/<STORY-ID>-<topic-kebab>` (e.g., `feat/P-07-L8-task-ladder`). The convention exists because `/p2e-cut-release` matches the regex `[A-Z]+-[0-9]+-L[0-9]+` against the branch name to auto-infer `--story-id` when the user later runs it. When the regex matches, no flag is needed and the release closeout is automatic. When it does not match, `/p2e-cut-release` falls through to its `AskUserQuestion` story-picker — the release still works, but requires a manual confirmation.

If a worktree branch was auto-named (e.g., `claude/laughing-bartik-...`), run `/update-branch-name` before the story-lead opens the PR. The rename must preserve the story-id segment. Renaming after the PR is open requires updating the PR base branch reference and re-pushing — do it before opening to avoid the complication.

## Cross-platform fallback

### Claude Code

Full supervisor architecture as described above: Phase 0–4, parallel story-lead waves per wave, optional Workflow batch mode at N ≥ 4.

### Codex

Codex has no nested Agent tree or dynamic Workflow tool. Use the **sequential fallback** — per story, in priority order: materialize first-turn briefing → implement inline (adaptive skill matrix still applies) → verify via the adaptive fix loop (per `## Verify gate` in policy; same 6-round/stall/oscillation exits) → commit + PR → tiered review. Track progress with `update_plan` (one entry per story). Stories end at `IN_REVIEW`; never cut a release inline.

### Cursor

Same sequential fallback as Codex (verify via the adaptive fix loop, not a single retry). No task primitive: emit one `kind: NOTE` story-log entry per lifecycle transition as the progress surface:

```
mcp__p2e__story_log op=append project_slug=<slug> items=[{"story_id":"<id>","kind":"NOTE","author":"orchestrator","message":"Step: implementing — starting implementation"}]
```

One NOTE per transition; do NOT write NOTEs for intermediate state within a step (only on transition). Status discipline is self-enforced by this workflow on every platform (Claude Code, Codex, Cursor) — confirm a story is `IN_PROGRESS` through MCP before starting implementation.

Parallel waves and dynamic-Workflow batch mode are Claude-Code-only features. This is a documented asymmetry, not a defect.

## Thin-draft handling

- If a story has no acceptance criteria and no capabilities, treat it as a thin draft. The story remains at `DRAFT` or `OPEN` but is considered under-specified for implementation.
- The wrapper should stop and ask what to do before routing a thin draft into implementation.
- The user may flesh it out (using `/p2e-update-story`), proceed as-is, or skip it.

## End-of-run sync

- If the batch has enough issue and merge context to reconcile labels safely, perform the label sync automatically at the end of the run (Phase 4).
- If that context is missing, incomplete, or ambiguous, do not guess.
- In the fallback case, route to `p2e-sync-labels` as the explicit reconcile step.
- Stories completing the run are at `IN_REVIEW`; reconcile labels to match that state.

## Dry-run behavior

- Dry-run is read-only.
- The workflow should still show the selected queue, routing decisions, wave plan, the would-be wave dispatches, the chosen Workflow mode (direct Agent vs dynamic Workflow), and the writes it would have performed.
- Dry-run must skip all side effects, including MCP status writes, issue updates, and label reconciliation.
- Dry-run still shows the first-turn briefing it WOULD have handed to each story-lead.

## Story log checkpoint policy

### Intent

The story log is a narrative of events during implementation that **do not already have their own first-class surface**. State transitions (`OPEN → IN_PROGRESS → IN_REVIEW`) are recorded in `story.status` and `AuditLog`; duplicating them here would be noise. The log carries the things that would otherwise scatter across GH comments and agent transcripts: AC changes, verifications, blockers, decisions, scope changes, and user notes.

The `kind` chip is a taxonomy so a skimmer can filter ("show me blockers", "show me scope changes") — it must honestly categorize the event.

### Orchestrator-authored checkpoints (exactly 3)

The **supervisor** writes to `mcp__p2e__story_log` (op=append) at these 3 checkpoints per story, in Phase 3. No per-tool-call logging; no entries for status transitions alone.

#### Checkpoint 1 — AC verdict (Phase 3, after gate passes, one call per AC)

Use `mcp__p2e__criteria op=verdict` — **not** `op=toggle`. Pass concrete evidence in the `note` field.

```
mcp__p2e__criteria op=verdict items=[{"id":"<criterion-db-cuid>","verdict":"PASS","note":"<test name or file:line or commit — cite the concrete evidence>"}]
```

Verdict values: `PASS` | `FAIL` | `BLOCKED` | `NOT_TESTED`. The `note` field (max 2000 chars) is required at Checkpoint 1; a bare verdict with no evidence is insufficient. When `note` is provided, the MCP server appends a `UAT_RESULT` StoryLogEntry automatically — the supervisor does NOT write a separate log entry for this checkpoint.

For UI-tagged stories where `/p2e-verify-story` ran as the evidence engine (see `### Gate integration with /p2e-verify-story` below), the verdict and note are written by the verify-story phase; the supervisor confirms they were recorded rather than writing them directly.

#### Checkpoint 2 — Verification pass (Phase 3, right before `IN_REVIEW` flip)

Written by the **supervisor** in Phase 3.

```json
{ "kind": "VERIFICATION", "author": "orchestrator", "message": "Verified: <verificationCmd> — <short summary, e.g. tests passed, build clean>" }
```

One entry per verification run that passed. The state flip to `IN_REVIEW` itself is NOT logged — it lives in `story.status` + `AuditLog`.

#### Checkpoint 3 — Gate failure / BLOCKED

**Fix-loop exited non-pass (story-lead reports `outcome: "blocked"`):** written by the **story-lead** (`"author": "implementer"`) when its adaptive fix loop exits with stall, oscillation, or 6-round cap — exactly one entry summarizing the rounds run and the final open-problem count:
```json
{ "kind": "BLOCKER", "author": "implementer", "message": "Fix loop exited blocked: <N rounds, final open-problem count, short reason>" }
```

**Strike 2 (supervisor receives `outcome: "blocked"` report in Phase 3):** written by the **supervisor** (`"author": "orchestrator"`):
```json
{ "kind": "BLOCKER", "author": "orchestrator", "message": "Verification failed (strike 2): <short reason> — architect-assisted retry also exited blocked" }
```

The state flip to `BLOCKED` on strike 2 is NOT a separate log entry — it's implied by the strike-2 BLOCKER message and recorded in `story.status`.

### Self-reporting kinds (story-lead or human)

These kinds are NOT supervisor checkpoints — the supervisor never emits them automatically. They are emitted by the story-lead (per `workflows/p2e-first-turn-briefing.md#deviation-reporting`) or written by humans via the UI or MCP:

- `DECISION` — judgment call that does NOT change the spec (e.g., "picked Approach A because...", "overrode architect's recommendation", "deferred caching layer to follow-up story"). Authored by `"implementer"`, `"user"`, or `"orchestrator"` (the last only when the orchestrator itself made the call, e.g., `--no-security` override under `/p2e-ship-batch`).
- `SCOPE_CHANGE` — mid-flight change to the story spec itself (e.g., "dropped retroactive backfill, covered in Non-goals", "added AC for empty-state copy after design review"). Authored by `"implementer"` or `"user"`.
- `NOTE` — free-form observation worth preserving (e.g., orchestrator-authored audit notes from `/p2e-ship-batch`'s scope-change audit, or human-authored context).

The story-lead must emit `SCOPE_CHANGE` / `DECISION` entries **before** making the deviating change, not after — see `workflows/p2e-first-turn-briefing.md#deviation-reporting` for the contract and MCP call shape.

### MCP call shape

All checkpoint writes use `items:[{...}]` form (never flat form — arrays/bools round-trip correctly in items form only):

```
mcp__p2e__story_log op=append project_slug=<slug> items=[{ "story_id": "<id>", "kind": "...", "author": "orchestrator", "message": "..." }]
```

### Gate integration with /p2e-verify-story

For UI-tagged stories, the verify gate invokes `/p2e-verify-story` as the evidence engine for the browser phases:
- Phases 2–3 reproduce each AC and capture screenshots.
- Screenshots are uploaded via `mcp__p2e__story_assets op=upload_url` (signed-URL path — see `## Screenshot evidence upload` in `workflows/p2e-policy.md`) with `criterion_id=<ac-cuid>` to link evidence directly to the criterion.
- Verdicts are recorded via `mcp__p2e__criteria op=verdict items=[{"id":"<ac-cuid>","verdict":"PASS|FAIL|BLOCKED","note":"<screenshot path or test ref>"}]`.
- The HTML report is an optional `--report` artifact; the tracker (detail panel + map badge) is the primary output.

The `CAVEAT` verdict from older verify-story runs maps to `PASS` with a note (if the caveat is acceptable) or `BLOCKED` (if it gates shipping). The verify-story workflow no longer refuses to update the story — it IS the story-update mechanism for UI evidence.

### Notes

- State transitions (`OPEN → IN_PROGRESS → IN_REVIEW → DONE`) are NOT log events. Read them from `story.status` or `AuditLog`.
- The MCP tool is append-only; there is no op=update or op=delete for log entries.
- `stories op=get` returns the last 50 log entries inline as `logEntries` + `logCount` — no second round-trip needed.
