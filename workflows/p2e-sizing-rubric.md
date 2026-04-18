# P2E Story Sizing Rubric

This document defines the canonical 6-tier **agent-centric** sizing scale used by every P2E story. Sizing is read by planners, wave-gates, and the `/p2e-add-story` + `/p2e-update-story` plugin workflows, and it is stored on the Story row as the `sizing` enum field (shipped by P-07-L6).

Sizing is NOT a human-hour estimate. It expresses two things:

1. **Implementation complexity** for an agent — coupling, refactor surface, cross-layer reach, schema shape.
2. **Review cost** for a human reviewer — how long it takes a human to read, QA, and approve the diff.

The rubric explicitly weights **FE / redesign / visual-review work higher** than backend work of similar code size, because FE diffs demand screen-by-screen human inspection and have higher regression surface. It weights **backend code with test-script self-verification lower**, because the agent can prove correctness via `bunx vitest run` without a reviewer re-running flows.

## The 6 tiers

### XS — Trivial

**Agent complexity:** Single file, single function, no branching logic, no new dependencies. Touching one constant, one string, one regex, or one copy block.

**Review cost:** Reviewer reads the diff once and is done. No screens to walk through. No test paths to trace.

**Concrete example:** Fixing a typo in a copy string, renaming one private helper, bumping one hard-coded retry count, updating a CHANGELOG entry.

### S — Small

**Agent complexity:** 1–3 files in one layer, no schema work, no migrations, no cross-layer reach. Might add one test, one branch, one new config toggle.

**Review cost:** A reviewer can read the whole diff in a single sitting and QA any visible surface in under five minutes.

**Concrete example:** Adding a `?status=` filter to one MCP list operation, adding a dark-mode class to one existing component, renaming a prop across three call sites, removing a dead flag.

### M — Medium (default)

**Agent complexity:** One story's worth of work on a single feature — a few files across 1–2 layers, optionally including a single straightforward test file. No breaking changes, no migrations, no cross-cutting refactors.

**Review cost:** Reviewer can trace the change end-to-end in one pass. If there is a UI surface, it is a single view with no new navigation.

**M is the default sizing for every new story** unless the drafter has explicit evidence to go larger or smaller (see `## When to default to M`).

**Concrete example:** Adding a capability to an existing MCP operation + the matching server-action + a unit test; wiring an existing component into a new page; shipping a feature flag with tests.

### L — Large

**Agent complexity:** Cross-layer work — e.g. schema + MCP + UI for one feature — OR a single layer with non-trivial logic (state machine, merge semantics, conflict resolution). Often introduces a new component, a new MCP operation, or a new server action from scratch. Usually ≥ 5 acceptance criteria.

**Review cost:** Reviewer needs multiple passes — one for data model, one for API surface, one for UI/UX. Visual diff on ≥ 1 screen if tagged `UI`.

**Concrete example:** A new story-relations graph view (schema field already exists, but MCP + actions + a new graph component ship together); a new lifecycle state with server-side predicate + UI affordance + label sync.

### XL — Extra-Large

**Agent complexity:** Full cross-layer feature with a **visible redesign** element OR a migration with data backfill OR a new domain concept introduced in one pass (new table, new MCP tool, new UI surface, new docs). Likely ≥ 8 acceptance criteria, likely has a capability with `isBreaking: true`.

**Review cost:** Reviewer needs deep engagement — reads migration, walks new UI end-to-end, checks rollback plan, re-runs tests locally. Likely warrants an `approach-review` constraint so the architect agent plans it first.

**Concrete example:** Adding `Feature` as a first-class parent of UXOs (new table + migration + MCP CRUD + detail panel + matrix overlay); replacing effortHint semantics with a new enum + backfill + UI + docs.

### XXL — Max

**Agent complexity:** Major refactor, shared-infra change, or new subsystem that touches multiple features at once. Schema migration WITH data backfill AND downstream consumer coordination. Often introduces or removes an external surface (MCP tool, public CLI, installed hook).

**Review cost:** Cannot be reviewed in one sitting. Needs staged verification: schema PR separate from UI PR, or a dedicated migration dry-run. Almost always carries `approach-review` and usually lands behind a feature flag.

**Concrete example:** Product → Projects model (new top-level entity above Project; every MCP tool grows a `product_slug` arg with backfill); replacing the story-id scheme across the whole backlog; moving from a single repo to a plugin + main split.

## Weighting rules

These are the forcing rules that push sizing up or down **regardless of raw file count**:

| Signal | Effect on sizing |
|---|---|
| Any capability with `isBreaking: true` | Minimum **L**. Breaking changes always need reviewer attention. |
| Any tag in `{Schema, migration, infra, data-model}` | Minimum **L**; if combined with `UI` tag, minimum **XL**. |
| `UI` tag alone (visible screen diff) | Bump by one tier vs. the pure-backend equivalent. FE review is visual, not test-gated. |
| Backend-only work with `verificationCmd` covering the full path | Allow **one tier lower** than raw file count suggests. Test-gated correctness reduces review cost. |
| Acceptance criteria count ≥ 8 | Minimum **L**. Many-AC stories are inherently cross-cutting. |
| Acceptance criteria count ≤ 3 AND tags ∈ `{ui-copy, docs, copy}` | Allow **XS** or **S** when the diff is pure documentation/copy. |
| `files_hint` length ≥ 7 | Minimum **L**. Many files touched is a review-cost forcing function. |
| `files_hint` length ≥ 12 | Minimum **XL**. |
| Story title contains "rewrite", "migrate", "redesign", "refactor", or "extract" | Bump by at least one tier vs. the title-free estimate. |

When multiple rules apply, take the **maximum** of the produced tiers.

## When to default to M

The default tier for a new story is **M**. Drafting workflows apply `sizing: M` at add time without running any heuristic, because at add time the story usually has only a title and a few acceptance criteria — not enough signal for a credible inference.

Inference only runs during `/p2e-update-story` **thicken** (see `workflows/p2e-update-story.md`), where the story has real capabilities, an AC list, tags, and a `files_hint`. Until then, `M` with a `defaulted` annotation is the honest default.

## Inference inputs (used by `/p2e-update-story` thicken)

The thicken path computes a proposed sizing from these five inputs:

1. **Title** — scanned for the bump-triggers listed above (`rewrite`, `migrate`, `redesign`, `refactor`, `extract`).
2. **Capabilities** — count of capabilities, and whether any has `isBreaking: true`.
3. **Acceptance criteria count** — the AC length threshold rules (`≤ 3`, `≥ 8`).
4. **Tags** — normalized, matched against the weighting table (`UI`, `Schema`, `migration`, `infra`, `data-model`, `ui-copy`, `docs`, `copy`).
5. **`files_hint` length** — the file-count thresholds (`≥ 7`, `≥ 12`).

The thicken path annotates the proposed sizing as `derived-from-source: <evidence>` where `<evidence>` cites the specific inputs that forced the tier. Example:

> `derived-from-source: 3 capabilities + 6 AC + Schema tag → L`
> `derived-from-source: 2 capabilities + 2 AC + Docs tag + 1 file_hint → S`
> `derived-from-source: isBreaking capability + UI tag + 9 AC → XL`

## User override

At both add-time (via `/p2e-add-story`) and thicken-time (via `/p2e-update-story`), the confirm step **must** let the user override the inferred or defaulted value before write. The user's override wins unconditionally — the rubric is a starting point, not a gate.

The override flows through the normal `mcp__p2e__stories op=create` or `op=update` write with the user-accepted `sizing` value; no separate sizing endpoint exists.

## Non-goals

- Sizing does **not** drive agent model selection (that remains `effortHint` + the persona router).
- Sizing does **not** drive wave assignment (that remains the staff-engineer's file-collision analysis).
- Sizing does **not** block any workflow — a story with the "wrong" size still ships; the rubric is advisory.
- Sizing is **not** a human-hour estimate; do not translate XS/S/M/L/XL/XXL into story-points or calendar time.
