# P2E Update Story Workflow

This workflow updates any field of an existing P2E story — thickening empty fields from context, steering populated ones, renaming, re-parenting, retagging, or adjusting release. It shares the preview/confirm UX of `p2e-add-story` and subsumes the old `p2e-add-story --fill` mode into a single code path. The wrapper stays wrapper-agnostic: it asks, renders, and confirms, but does not hard-code platform entrypoint details.

## Hard rules

- Stay in story-update mode. Do not reinterpret the request as a troubleshooting task just because the described field mentions a bug, regression, or validation problem.
- ALWAYS show an annotated preview and require explicit accept before any write.
- NEVER silently mutate the story or its linked GitHub issue without that preview gate.
- If MCP auth, story lookup, or required source context is unavailable, stop with a short blocker message instead of improvising or silently writing partial data.
- Never write the story, acceptance criteria, capabilities, spec link, or GitHub issue until the user has seen the preview and had a chance to correct it.

## Purpose

- Turn an existing story-id (plus optional source) into a diff-preview + confirmed MCP write.
- Support both **thicken** (fill empty fields from title + source + siblings) and **steer** (adjust populated fields) through the same preview/confirm flow.
- Enforce the P-07-L1 thickness predicate on any `DRAFT → OPEN` transition — the wrapper surfaces failing predicate clauses instead of silently rejecting.
- Keep the GitHub issue in sync: create one on promotion to `OPEN` if missing, patch the existing issue body otherwise.

## Preconditions

- The target project must exist.
- The target story must exist. The story id is the canonical human-readable form (e.g. `P-01-L1`), not the DB cuid.
- If the story is linked to a GitHub issue, the linked repo must be reachable via `gh` for body-patch and label updates.

## Workflow

1. Resolve the target story via `mcp__p2e__stories op=get` with the provided `story_id` + `project_slug`. Capture the current state including `isThick`, `failingClauses`, `status`, all RRR fields, acceptance criteria, capabilities, relations, and thick-spec fields.
2. If a source argument was provided (a PRD path, issue URL, or spec YAML), read it. Resolve sibling stories under the same UXO via `op=list uxo_id=<cuid>` so the wrapper can cite them as derivation evidence.
3. Render an annotated preview of every Story field tagged with its provenance:
   - `empty` — the field was null/empty and stays null/empty.
   - `populated` — the field already had a value and remains unchanged.
   - `derived-from-source` — the field will be filled or steered, with the source (title inference / provided source arg / sibling story id) cited inline.
4. Ask for a single interactive action using the host's native prompt primitive (Claude wrapper uses `AskUserQuestion`; Codex wrapper uses its native prompt). The prompt offers these options and loops until Accept or Abort:
   - Thicken empty fields
   - Steer a specific field
   - Rename `story_id`
   - Move UXO
   - Retag
   - Adjust release
   - Adjust sizing
   - Accept and write
   - Abort
5. After every Thicken / Steer / Rename / Move UXO / Retag / Adjust release / Adjust sizing selection, re-render the preview with the new state and return to the same prompt. Only Accept exits into the write path; Abort exits with no changes.
6. On Accept, perform the batched MCP write in order and stop at the first failure. Surface the failing phase + item index so earlier successful writes can be reconciled manually.

## Required preview contents

Before any write, the preview must show at least:

- current `storyId` and proposed new `storyId` if a rename is staged
- `projectSlug`, current UXO, proposed UXO if a move is staged
- `status` (current) and proposed status transition if any
- `title`, `storyAs`, `storyWant`, `storySoThat`, `background`
- current and proposed `tags`, `release`, `specFile`
- acceptance criteria with per-item diff (add / edit / remove / keep)
- capabilities with per-item diff (add / edit / remove / keep), including `action` and `isBreaking`
- thick-spec fields: `filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`
- `sizing` row — current value and proposed value, annotated with its provenance: `populated` when the story already has a sizing and the thicken path leaves it alone, `derived-from-source: <evidence>` when the thicken path infers a new tier (see `## Thicken rules` and `workflows/p2e-sizing-rubric.md`), or `steered-by-user` when the user manually overrode it via Adjust sizing
- current `isThick` and proposed `isThick` (with `failingClauses` if the proposal still fails)
- linked GitHub issue state: create-new / patch-existing / leave-alone
- provenance annotation on every field: `empty`, `populated`, or `derived-from-source` with the concrete source cited

The preview may be rendered in a host-specific visual format, but the user must be able to review the provenance of every value clearly.

## Required confirm step

The confirm step must support:

- Thicken empty fields
- Steer a specific field
- Rename `story_id`
- Move UXO
- Retag
- Adjust release
- Adjust sizing (override the inferred or populated value with any of `XS | S | M | L | XL | XXL`; preview re-renders with the chosen value before write — see `## Steer rules` for the sizing-specific override path)
- Accept and write
- Abort

If the user does not accept, do not write.

## Thicken rules

When the user picks **Thicken empty fields**, infer proposed values from these sources in priority order:

1. The story's own `title` + existing populated fields.
2. The optional `source` argument (PRD path, GH issue URL, or spec YAML under `specs/<projectSlug>/`).
3. Sibling stories under the same UXO (same `uxoId`), especially their capabilities and acceptance-criteria patterns.

Each thickened field must be annotated with the concrete derivation source in the re-rendered preview. If no source supports a field, leave it empty — empty cells are preferred over filler.

### Sizing inference

Sizing is a special case: it is always populated (every Story row has a `sizing` value after P-07-L6), so the thicken path does not fill an empty cell — it **re-infers** a proposed tier from the staged state of the story and compares it to the current value. If the inferred tier differs from the current one, the preview shows a before/after diff with a `derived-from-source` annotation; otherwise the row is annotated `populated` and left alone.

The inference reads five inputs from the staged state (the post-thicken projection, not the pre-thicken values):

1. **Title** — scanned for the bump-triggers `rewrite`, `migrate`, `redesign`, `refactor`, `extract`.
2. **Capabilities** — count of capabilities and whether any has `isBreaking: true`.
3. **Acceptance criteria count** — `≤ 3` and `≥ 8` thresholds per the rubric.
4. **Tags** — normalized (lowercased, trimmed, whitespace→`-`), matched against the weighting table.
5. **`files_hint` length** — `≥ 7` and `≥ 12` thresholds per the rubric.

The canonical tier definitions, weighting rules, and worked examples live in `workflows/p2e-sizing-rubric.md` — the thicken path must not re-invent them.

The annotation cites the specific inputs that forced the tier. Examples the preview renderer should emit:

> `derived-from-source: 3 capabilities + 6 AC + Schema tag → L`
> `derived-from-source: 2 capabilities + 2 AC + Docs tag + 1 file_hint → S`
> `derived-from-source: isBreaking capability + UI tag + 9 AC → XL`

The inferred value is a proposal; the user can override it in the confirm step via the **Adjust sizing** action (see `## Steer rules`).

## Steer rules

When the user picks **Steer a specific field**, the wrapper prompts for which field and the new value (or a follow-up interactive flow for criteria / capabilities / thick-spec arrays). Steering overwrites the existing value; the previous value is preserved in the AuditLog (server-side) and shown in the before/after diff in the preview.

When the user picks **Adjust sizing** (equivalent to steering the `sizing` field), the wrapper prompts for one of `XS | S | M | L | XL | XXL`. The user's choice overrides both the previously populated value and any thicken-inferred proposal unconditionally — the rubric in `workflows/p2e-sizing-rubric.md` is advisory, not gating. The preview re-renders with the chosen value annotated `steered-by-user` (with the before/after pair shown inline) and returns to the confirm prompt; the write only happens on Accept.

## Brainstorming escalation

When the thicken path runs and the staged draft still leaves ≥ 2 of the six thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`) empty AND the provided source does not support filling them, the wrapper invokes a shared brainstorming primitive **exactly once per flow** to batch clarifying questions in a single turn. The Claude wrapper resolves the reference against the `superpowers:brainstorming` skill; the Codex wrapper resolves it against its native brainstorming primitive (the same pattern used by `workflows/p2e-bootstrap.md --mode=onboarding` and `workflows/p2e-add-story.md` thick mode).

### When to escalate

Escalate **only** when ALL of the following are true after the first thicken pass:

1. Two or more of the six thick-spec fields are still empty.
2. The provided source (the `source` argument, if any) does not contain evidence to fill them, and no sibling story under the same UXO supplies matching capabilities or AC patterns.
3. The user's original invocation did not explicitly opt out (for example via a `--no-brainstorm` flag on the wrapper, if implemented).

Do NOT escalate when the gap is a single optional field. Do NOT escalate more than once per flow — if answers still leave major gaps, leave the cells empty and continue to the preview. Empty cells are preferred over filler, consistent with `## Thicken rules`.

### Question shape

The wrapper batches 2–4 concrete questions in a single turn. Prefer multiple-choice or closed-form questions over open-ended prose. Typical questions:

- Which files or modules does this story touch? (pick from detected candidates under the same UXO, or free-form)
- What are the non-negotiable constraints? (timezone / currency / backwards-compat / visible-screen / etc.)
- What is explicitly out of scope?
- Which existing document or sibling story most closely describes the shape of this work?
- What command would verify this story is done? (defaults to the track's `verificationCmd`)

### Fold-back rules

- Answers fold back into the staged draft as if they had been in the original source. Any field populated from the interview is annotated `derived-from-brainstorming` in the re-rendered preview (in addition to the existing `empty` / `populated` / `derived-from-source` / `steered-by-user` set).
- The brainstorming interview does not bypass the preview/confirm gate — the wrapper must still render the preview and return to the Thicken / Steer / Accept / Abort prompt.
- If the user aborts the interview (or declines to answer), continue to the preview with the fields left empty. Do not force-answer on the user's behalf.

## Write behavior

On Accept, issue MCP writes in this exact order and stop at the first failure:

1. `mcp__p2e__stories op=update` — RRR fields, background, release, tags, `status` (if a transition is staged), `specFile`, `new_story_id` (if a rename is staged), `uxo_id` (if a move is staged), `sizing` (always included if the staged value differs from the current value — whether derived-from-source or steered-by-user), and the six thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`).
2. `mcp__p2e__criteria op=create/update/delete` — the add/edit/remove diff from the criteria preview.
3. `mcp__p2e__capabilities op=create/update/delete` — the add/edit/remove diff from the capabilities preview.
4. GitHub issue reconciliation (see below).

Batch writes are fail-fast and non-atomic across phases; earlier successful writes remain persisted. The wrapper must surface which phase failed and which item index failed so the user can reconcile manually.

## Thick-gate on DRAFT → OPEN

If the staged update transitions the story to `OPEN` and the staged state still has `isThick=false`, reject the write. Surface the `failingClauses` returned by `mcp__p2e__stories op=get` (for example `files_hint_and_spec_file_missing` or `constraints_null`) so the user can decide whether to keep the story at `DRAFT`, go back to Thicken, or set `specFile` to satisfy the predicate. The P-07-L1 server-action layer enforces this gate regardless; the wrapper mirrors the check at preview time so the user sees the failure before hitting the MCP.

Transitions that don't cross `DRAFT → OPEN` (for example `OPEN → IN_PROGRESS`, `IN_PROGRESS → IN_REVIEW`, or `IN_REVIEW → DONE`) are allowed without the thickness check.

## Lifecycle label reconciliation

When the staged update crosses a **lifecycle boundary** (a status transition), the workflow must reconcile the linked GitHub issue label after the MCP write and before the GH issue body patch.

### Label map

| P2E status  | GitHub label |
|-------------|--------------|
| OPEN        | `ready`      |
| IN_PROGRESS | `in-progress`|
| IN_REVIEW   | `review`     |
| DONE        | `done`       |
| BLOCKED     | `blocked`    |

Only the five statuses above have a label mapping. Any other status value produces a stderr warning and the phase exits 0 (not a failure).

### Lifecycle boundaries that trigger label sync

A lifecycle boundary is any status transition that changes the status field. Examples:

- `OPEN → IN_PROGRESS` (transition: remove `ready`, add `in-progress`)
- `IN_PROGRESS → IN_REVIEW` (transition: remove `in-progress`, add `review`)
- `IN_REVIEW → DONE` (transition: remove `review`, add `done`)
- any status → `BLOCKED` (transition: remove the current-status label, add `blocked`)

Non-status updates (thicken / steer / rename / move UXO / retag / release / AC / capabilities diff) do **not** trigger label sync — see AC3.

### Write ordering for lifecycle transitions (fail-fast, 3 phases)

When the accept path includes a status transition:

1. **Phase 1 — MCP update** (`mcp__p2e__stories op=update`): write the new status and all other staged fields. Stop on any failure; surface phase 1 + item index.
2. **Phase 2 — Label reconciliation** (`scripts/sync-github-label.sh <repo> <issue#> <from-status> <to-status>`): invoke the helper with the from/to status values resolved from the label map. Stop on non-zero exit (unless the exit is a "label not found" warning, which exits 0). Surface phase 2 on failure.
3. **Phase 3 — Cache refresh**: write `~/.cache/p2e/<slug>/<story_id>.json` with `{"status":"<new-status>","ts":<unix-epoch>}` so the PreToolUse hook (see `hooks/pre-agent-spawn-story-status.sh`) reads the fresh status within its 30-second TTL window. This phase is best-effort: a write failure here does not stop the overall flow — log a stderr warning and continue.

After phase 3, the flow continues to the GH issue body patch (existing reconciliation step) if applicable.

For non-lifecycle updates, the existing write ordering (phase 1 MCP + optional GH body patch) remains unchanged.

### Unknown label behavior

If `scripts/sync-github-label.sh` cannot find a label on the target repo (because the label was not created), it prints a warning to stderr and exits 0 so the overall update succeeds. The wrapper should surface the warning to the user with a note to create the label via `gh label create`.

## GitHub issue reconciliation

- If the story has no linked GitHub issue AND the staged update promotes it to `OPEN`: create the issue in the project's configured GitHub repo, label it `ready`, link it back via `githubIssueNumber` + `githubIssueUrl` on the story, and include the P2E story id in the issue title.
- If the story already has a linked GitHub issue AND the update crosses a lifecycle boundary: the label was already reconciled in the lifecycle label reconciliation phase above. Patch the issue body to match the new state. Do not double-write the label.
- If the story already has a linked GitHub issue AND the update is NOT a lifecycle transition: patch the issue body only.
- If the staged update is purely about `DRAFT` fields (no promotion), leave the GH issue alone.

## AuditLog

Every mutation on `Story`, `AcceptanceCriterion`, or `StoryCapability` writes an `AuditLog` row server-side via `src/lib/audit.ts` in the P2E main repo. The plugin never calls audit helpers directly — it relies on the MCP layer to record history.

## Dry-run behavior

- `--dry-run` is read-only.
- The workflow must still fetch the story, render the annotated preview (including the `sizing` row with its `populated` / `derived-from-source` / `steered-by-user` provenance), and print the exact MCP payloads it would have written at each phase (stories.update body, criteria upserts, capabilities upserts, GH issue create/patch body).
- Dry-run must skip all side effects, including MCP writes, GH issue creation/patching, and audit-log emission. No `mcp__p2e__stories op=update` call is issued until the user accepts outside dry-run.

## Error behavior

- Batch writes are fail-fast and non-atomic across phases.
- If a later phase fails, the wrapper must surface which phase failed and which item index failed.
- The successful earlier writes remain in place and may need manual reconciliation via `/p2e-update-story` or the UI.
- If inference succeeds but a write prerequisite fails (for example the thick-gate rejects promotion to OPEN), surface the blocker and preserve the already-rendered preview context so the user understands what would have been written.
- If a write succeeds at the MCP layer but GH issue reconciliation fails, the story is updated but the issue is out of sync; the wrapper must say so explicitly and point the user at `/p2e-sync-labels` as the repair path.
