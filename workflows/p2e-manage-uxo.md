# P2E Manage UXO Workflow

This workflow creates a new UXO (`--add` mode) or edits an existing UXO's `title`, `description`, `objectives[]`, `tier`, or phase (`--edit` mode, default). It applies the canonical UXO writing recipe in `workflows/p2e-uxo-recipe.md` and shares the preview/confirm UX pattern of `workflows/p2e-update-story.md`. The wrapper stays host-agnostic: it asks, renders, and confirms, but does not hard-code platform entrypoint details.

## Hard rules

- Stay in UXO-management mode. Do not reinterpret the request as a story edit just because a UXO's scope is discussed in story terms.
- ALWAYS show an annotated preview and require explicit accept before any write. The preview must include every field the recipe's grammar template references (`title`, `tier`, `description`, `objectives[]`), each annotated with provenance (`populated` / `derived-from-source` / `derived-from-stories` / `derived-from-brainstorming` / `steered-by-user`).
- NEVER silently mutate the UXO or its stories without that preview gate.
- Load `workflows/p2e-uxo-recipe.md` and follow it — objectives[] first → MECE-audit within the UXO → description as synthesis. The description must match the enumeration in `objectives[]` 1:1.
- If MCP auth, UXO lookup, or required source context is unavailable, stop with a short blocker message instead of improvising or silently writing partial data.

## Purpose

- Operationalize the canonical UXO writing recipe through a preview + confirmed MCP write.
- Support both **edit** (steer an existing UXO) and **add** (create a new one) through the same preview/confirm flow — the only differences are the source of initial state and the write op on Accept.
- Run the MECE audit against the existing story stack when the UXO has stories, rendering a story-landing coverage table.
- Surface scope gaps (missing objectives the UXO plausibly owns) per the recipe's gap-flagging protocol instead of silently diluting the UXO.

## Modes

### `--edit <uxo_id>` (default)

- Resolve the target UXO via `mcp__p2e__uxos` (or via `mcp__p2e__projects op=get` and the phase+tier+uxoId lookup). Capture `title`, `tier`, `description` (stored as `objective`), `objectives[]`, current story stack titles + tags + status.
- Render the annotated preview; open the confirm loop.
- On Accept, write via `mcp__p2e__uxos op=update`.

### `--add <uxo_id> --phase=<title> --tier=<name>`

- Require `uxo_id` (human-readable, e.g. `AU-06`), `phase` (phase title), and `tier` (tier name resolving against the project's tier registry).
- Scaffold a blank UXO (no prior objectives, no prior stories).
- Render the annotated preview with every field marked `empty` initially; open the confirm loop.
- On Accept, write via `mcp__p2e__uxos op=create`.

Both modes share the same preview layout, confirm actions, and recipe-driven drafting. A single CLI surface; two entry points.

## Preconditions

- The target project must exist and be bound (`.p2e/project.json` or explicit `project_slug`).
- For `--edit`: the target UXO must exist. `uxo_id` is the human-readable form (e.g. `AU-01`), not the DB cuid.
- For `--add`: the target phase must exist and the target tier name must resolve against the project's tier registry.

## Workflow

1. **Resolve initial state.** For `--edit`, fetch the UXO and its story stack. For `--add`, scaffold a blank UXO with the given `uxo_id`, `phase`, and `tier`.
2. **Load the recipe.** Read `workflows/p2e-uxo-recipe.md` and apply its 5-step process to draft the staged state:
   - Step 1: read evidence (the fetched UXO + stories, or the caller's free-form scope description for `--add`).
   - Step 2: brainstorm candidate objectives.
   - Step 3: MECE-audit (mutual-exclusion pass, collective-exhaustiveness pass, story-landing pass).
   - Step 4: write `objectives[]` as noun-phrase bullets.
   - Step 5: write `description` as a single-sentence synthesis using a capability verb + grammar template.
3. **Render the annotated preview.** See `## Required preview contents`.
4. **Ask for a single interactive action** using the host's native prompt primitive (Claude wrapper uses `AskUserQuestion`; Codex wrapper uses its native prompt). The prompt offers these options and loops until Accept or Abort:
   - Thicken objectives[]
   - Steer a specific field (title / description / objectives[] / tier / phase)
   - Flag gap (creates a thin-DRAFT story under the current UXO per the recipe's gap-flagging protocol)
   - Accept and write
   - Abort
5. **Re-render** the preview after every Thicken / Steer / Flag-gap selection and return to the same prompt. Only Accept exits into the write path; Abort exits with no changes.
6. **On Accept**, perform the batched MCP write in order and stop at the first failure. Surface the failing phase + item index so earlier successful writes can be reconciled manually.

## Required preview contents

Before any write, the preview must show at least:

- mode (`--edit` or `--add`) and the target `uxo_id`
- `phase` and `tier` (both modes), with proposed change annotated if a move is staged in `--edit`
- `title` — current and proposed, annotated
- `description` — current and proposed, rendered in full (not truncated), annotated
- `objectives[]` — current and proposed as a side-by-side or before/after list with per-bullet diff (add / edit / remove / keep), each annotated
- **MECE audit section** when stories exist under the UXO:
  - *story-landing coverage table* — every story under the UXO placed on exactly one proposed objective; orphan (zero landings) and multi-landed (two+ landings) rows flagged as MECE violations
  - *gap-flag section* — concerns the audit surfaced as plausibly in-scope but not included in the proposed `objectives[]`, each with a one-line description and a suggested capture path (thin-DRAFT story under this UXO, new UXO proposal, or comment)
- provenance annotation on every field: `populated` / `empty` / `derived-from-source: <evidence>` / `derived-from-stories: <story_id>` / `derived-from-brainstorming` / `steered-by-user`
- for `--add`: initial-state scaffolding note (`New UXO under <phase> / <tier>; no prior stories or objectives`)

The preview may be rendered in a host-specific visual format, but the user must be able to review the provenance of every value clearly.

## Required confirm step

The confirm step must support:

- Thicken objectives[]
- Steer a specific field (title / description / objectives[] / tier / phase)
- Flag gap (writes a thin-DRAFT story under the current UXO naming the gap; see `## Gap flagging`)
- Accept and write
- Abort

If the user does not accept, do not write.

## Thicken rules

When the user picks **Thicken objectives[]**, re-run the recipe's Step 2 + Step 3 against:

- The UXO's `title` and any existing `description`
- All stories currently under the UXO (`mcp__p2e__stories op=list uxo_id=<cuid>`) — each story title + tags + status becomes evidence for the brainstorm
- Sibling UXOs in the same phase+tier cell for sibling-MECE contrast (not as the primary MECE gate)

Each proposed objective bullet must be annotated with the concrete derivation source in the re-rendered preview: `derived-from-stories: <story_ids>` when a bullet is inferred from story titles, `derived-from-brainstorming` when produced by a brainstorming escalation, `derived-from-source: <title-inference>` when inferred from the UXO's own title.

If no source supports a candidate objective, omit it — empty cells are preferred over filler. The final `description` field is then rewritten as a synthesis of the locked `objectives[]` per the recipe's Step 5.

## Steer rules

When the user picks **Steer a specific field**, the wrapper prompts for which field and the new value.

- `title` — free-form string; the MECE audit re-runs against the new title to check for scope drift
- `description` — free-form string; the wrapper warns if the new description enumerates concerns that don't match the current `objectives[]` (a recipe violation) and offers to re-thicken `objectives[]`
- `objectives[]` — interactive list edit (add / edit / remove / reorder bullets); each change triggers a recipe-constraint check (noun-phrase shape, no user-journey verbs, no implementation leak)
- `tier` — tier name (resolves against the project's tier registry); the wrapper warns if existing stories under the UXO are incompatible with the new tier
- `phase` — phase title (resolves to phase DB cuid); the wrapper warns if existing stories under the UXO would be orphaned by the move

Steering overwrites the staged value; the previous value is preserved in the AuditLog (server-side) and shown in the before/after diff in the re-rendered preview.

## Gap flagging

When the MECE audit surfaces a concern that plausibly belongs to the UXO but is not in the staged `objectives[]`, the **Flag gap** confirm action opens a sub-prompt:

1. Confirm the gap's short title (e.g., `account deletion / user lifecycle`).
2. Pick the capture path per `workflows/p2e-uxo-recipe.md` `## Gap flagging`:
   - **Thin-DRAFT story under this UXO** — writes via `mcp__p2e__stories op=create` with `status: "DRAFT"` and the gap title; returns to the preview loop.
   - **New UXO proposal** — records the proposal in the preview's gap-flag section; the user can later invoke `/p2e-manage-uxo --add` to create it.
   - **Leave as note** — records the gap in the preview's gap-flag section for reference; no write.

The gap-flag action does NOT add the gap to the current UXO's `objectives[]` — the recipe forbids dilution. Captured gaps are either routed to a separate story (DRAFT) or a separate UXO proposal.

## Brainstorming escalation

When the thicken path runs and the staged `objectives[]` has fewer than 3 bullets AND the UXO's stories + title + sibling UXOs do not supply enough evidence to reach 3, the wrapper invokes the host brainstorming primitive **exactly once per flow** to batch clarifying questions in a single turn. The Claude wrapper resolves the reference against `superpowers:brainstorming`; the Codex wrapper resolves it against its native brainstorming primitive.

### When to escalate

Escalate only when ALL of the following are true after the first thicken pass:

1. The staged `objectives[]` has fewer than 3 bullets.
2. The recipe's "typical landing size" guidance (3–6 objectives) is not met by title + story evidence alone.
3. The user's invocation did not opt out (for example via `--no-brainstorm`, if implemented).

Do NOT escalate when the UXO is genuinely narrow (a 2-objective UXO is acceptable if the evidence supports only 2). Do NOT escalate more than once per flow — if answers still leave gaps, leave the objectives as-is and continue to the preview.

### Question shape

The wrapper batches 2–4 concrete questions in a single turn. Prefer multiple-choice or closed-form over open-ended prose. Typical questions:

- What state does this UXO hold? (pick from candidates inferred from the title, or free-form)
- What operations mutate that state?
- What invariants does this UXO enforce?
- What hardening / boundaries does it need?
- Is there a lifecycle (creation, update, termination) the UXO governs?

### Fold-back rules

- Answers fold back into the staged `objectives[]` as if they had been in the original source. Any objective bullet populated from the interview is annotated `derived-from-brainstorming` in the re-rendered preview.
- The brainstorming interview does not bypass the preview/confirm gate — the wrapper must still render the preview and return to the Thicken / Steer / Flag-gap / Accept / Abort prompt.
- If the user aborts the interview (or declines to answer), continue to the preview with the `objectives[]` left as-is.

## Write behavior

### `--edit` Accept path

1. `mcp__p2e__uxos op=update` — single item containing the UXO DB cuid and every staged field that differs from the current state (`title?`, `description?`, `objectives?`, `tier_name?`, `phase_id?`). Call form: `{ op: "update", items: [{ id, ... }] }` — the `items:[{...}]` form is required to round-trip `objectives` as a native array (see P2E memory on MCP array coercion).
2. If any Flag-gap actions created thin-DRAFT stories, those `mcp__p2e__stories op=create` calls fired inline at Flag-gap time, not on Accept. They are NOT retried or rolled back on Accept failure.

### `--add` Accept path

1. `mcp__p2e__uxos op=create` — single item: `{ uxo_id, title, tier_name, phase_title OR phase_id, description?, objectives? }`. The server auto-normalizes the flat form to `items:[{...}]`.
2. If any Flag-gap actions created thin-DRAFT stories during drafting, those already landed (same as `--edit`).

### Write form

Use the `items:[{...}]` form for both modes. This is the verified shape that round-trips arrays correctly on Opus 4.7 and Sonnet 4.6 sessions.

## AuditLog

Every mutation on `Uxo` or `Story` writes an `AuditLog` row server-side via `src/lib/audit.ts` in the P2E main repo. The plugin never calls audit helpers directly — it relies on the MCP layer to record history.

## Dry-run behavior

- `--dry-run` is read-only.
- The workflow must still fetch the UXO (or scaffold the `--add` blank), render the annotated preview including the MECE audit section, and print the exact MCP payload it would have written (`uxos.update` or `uxos.create`) plus any thin-DRAFT story payloads that Flag-gap would have issued.
- Dry-run must skip all side effects, including MCP writes and audit-log emission.

## Error behavior

- Batch writes are fail-fast and non-atomic across phases.
- If the MCP write fails, the wrapper must surface the concrete error and preserve the rendered preview context so the user understands what would have been written.
- If `--add` fails because `uxo_id` collides with an existing UXO in the project, surface the collision with a suggestion to pick the next unused ordinal (e.g., `AU-08` if `AU-07` is the current max).
- If `--edit` fails because the UXO cuid was not found, surface the lookup and suggest the user verify `uxo_id` + `project_slug`.

## Relationship to V-02-L5

This workflow is **proactive authoring discipline** — the user opts into running the recipe against a UXO they know needs work (or a new UXO they're adding). It does not detect drift automatically.

V-02-L5 (`UXO drift capture + recalibration flow`) is **reactive drift correction** — the drift detector surfaces signals, the Edit-in-place executor opens this workflow (or its DB-side equivalent) pre-filled for a specific UXO. The two layers complement each other without overlap.
