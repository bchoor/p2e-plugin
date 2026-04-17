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
   - Accept and write
   - Abort
5. After every Thicken / Steer / Rename / Move UXO / Retag / Adjust release selection, re-render the preview with the new state and return to the same prompt. Only Accept exits into the write path; Abort exits with no changes.
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
- Accept and write
- Abort

If the user does not accept, do not write.

## Thicken rules

When the user picks **Thicken empty fields**, infer proposed values from these sources in priority order:

1. The story's own `title` + existing populated fields.
2. The optional `source` argument (PRD path, GH issue URL, or spec YAML under `specs/<projectSlug>/`).
3. Sibling stories under the same UXO (same `uxoId`), especially their capabilities and acceptance-criteria patterns.

Each thickened field must be annotated with the concrete derivation source in the re-rendered preview. If no source supports a field, leave it empty — empty cells are preferred over filler.

## Steer rules

When the user picks **Steer a specific field**, the wrapper prompts for which field and the new value (or a follow-up interactive flow for criteria / capabilities / thick-spec arrays). Steering overwrites the existing value; the previous value is preserved in the AuditLog (server-side) and shown in the before/after diff in the preview.

## Write behavior

On Accept, issue MCP writes in this exact order and stop at the first failure:

1. `mcp__p2e__stories op=update` — RRR fields, background, release, tags, `status` (if a transition is staged), `specFile`, `new_story_id` (if a rename is staged), `uxo_id` (if a move is staged), and the six thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`).
2. `mcp__p2e__criteria op=create/update/delete` — the add/edit/remove diff from the criteria preview.
3. `mcp__p2e__capabilities op=create/update/delete` — the add/edit/remove diff from the capabilities preview.
4. GitHub issue reconciliation (see below).

Batch writes are fail-fast and non-atomic across phases; earlier successful writes remain persisted. The wrapper must surface which phase failed and which item index failed so the user can reconcile manually.

## Thick-gate on DRAFT → OPEN

If the staged update transitions the story to `OPEN` and the staged state still has `isThick=false`, reject the write. Surface the `failingClauses` returned by `mcp__p2e__stories op=get` (for example `files_hint_and_spec_file_missing` or `constraints_null`) so the user can decide whether to keep the story at `DRAFT`, go back to Thicken, or set `specFile` to satisfy the predicate. The P-07-L1 server-action layer enforces this gate regardless; the wrapper mirrors the check at preview time so the user sees the failure before hitting the MCP.

Transitions that don't cross `DRAFT → OPEN` (for example `OPEN → IN_PROGRESS`, `IN_PROGRESS → IN_REVIEW`, or `IN_REVIEW → DONE`) are allowed without the thickness check.

## GitHub issue reconciliation

- If the story has no linked GitHub issue AND the staged update promotes it to `OPEN`: create the issue in the project's configured GitHub repo, label it `ready`, link it back via `githubIssueNumber` + `githubIssueUrl` on the story, and include the P2E story id in the issue title.
- If the story already has a linked GitHub issue: patch the issue body to match the new state (same story → GH direction as `workflows/p2e-sync-labels.md`). Do not touch labels here — label lifecycle is owned by `/p2e-work-on-next` and `/p2e-sync-labels`.
- If the staged update is purely about `DRAFT` fields (no promotion), leave the GH issue alone.

## AuditLog

Every mutation on `Story`, `AcceptanceCriterion`, or `StoryCapability` writes an `AuditLog` row server-side via `src/lib/audit.ts` in the P2E main repo. The plugin never calls audit helpers directly — it relies on the MCP layer to record history.

## Dry-run behavior

- `--dry-run` is read-only.
- The workflow must still fetch the story, render the annotated preview, and print the exact MCP payloads it would have written at each phase (stories.update body, criteria upserts, capabilities upserts, GH issue create/patch body).
- Dry-run must skip all side effects, including MCP writes, GH issue creation/patching, and audit-log emission.

## Error behavior

- Batch writes are fail-fast and non-atomic across phases.
- If a later phase fails, the wrapper must surface which phase failed and which item index failed.
- The successful earlier writes remain in place and may need manual reconciliation via `/p2e-update-story` or the UI.
- If inference succeeds but a write prerequisite fails (for example the thick-gate rejects promotion to OPEN), surface the blocker and preserve the already-rendered preview context so the user understands what would have been written.
- If a write succeeds at the MCP layer but GH issue reconciliation fails, the story is updated but the issue is out of sync; the wrapper must say so explicitly and point the user at `/p2e-sync-labels` as the repair path.
