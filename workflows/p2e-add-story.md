# P2E Add Story Workflow

This workflow drafts a single story, its acceptance criteria, and its capabilities from a description or from an existing thin draft. The wrapper should keep the interaction and rendering generic while preserving the MCP-first behavior.

## Hard rules

- Stay in story-creation mode. Do not reinterpret the request as a troubleshooting task just because the described story mentions a bug, regression, or validation problem.
- Infer the story fields and present them back to the user before any mutation.
- Never write the story, acceptance criteria, capabilities, or GitHub issue until the user has seen the preview and had a chance to correct it.
- If MCP auth, project lookup, or required source context is unavailable, stop with a short blocker message instead of improvising or silently writing partial data.

## Purpose

- Turn a story description into a structured P2E story entry.
- Create the GitHub issue after the MCP write succeeds with the `ready` label, then link it back to the story.

## Modes

The command supports two drafting modes, selected at invocation:

- **thick (default)** — populate ALL fields the `/p2e-update-story` thicken path would populate, including the six thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`). Before drafting, gather graph context per `workflows/p2e-thicken.md ## Context gathering`. Run the sizing inference heuristic per `workflows/p2e-sizing-rubric.md` and annotate the inferred tier `derived-from-source: <evidence>` instead of `defaulted`. If the source signal is insufficient, invoke the host brainstorming primitive exactly once (see `## Brainstorming escalation`) to batch 2–4 questions before drafting. This is the default and ensures stories pass the thick-gate immediately on capture.
- **thin (`--thin`)** — the fast opt-out path. Infer phase, tier, UXO, title, RRR, a conservative acceptance-criteria list, a conservative capabilities list, and `priority` from the description. Do NOT populate the thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`). Leave `sizing` at the defaulted `M` and `priority` at the defaulted `null` unless the user signals urgency (see `## Priority rules`). Use this path for fast placeholder capture when thickening is explicitly deferred.

Both modes share the preview/confirm contract below. Thick mode adds more fields and richer provenance annotations; it does not change the accept/adjust/abort gate.

**Bootstrap batch flows** (`/p2e-bootstrap --all` and the onboarding backfill sub-step) invoke with `--thin` semantics explicitly and are unaffected by the thick default. Do not change bootstrap drafting behavior.

## Deprecated fill mode

The legacy `--fill <storyId>` path is deprecated as of v0.6 and now delegates to the shared `workflows/p2e-update-story.md` contract for one release before being removed. Any wrapper that still accepts `--fill` must forward the call verbatim to `/p2e-update-story` (Claude) or `p2e-update-story` (Codex) with the same story id. The fill-mode shim does not implement its own preview or write path; it is a pointer only. New thickening work should target `/p2e-update-story` directly.

## Preconditions

- The target project must exist.
- The target UXO must exist or be created as part of the flow.

## UXO placement matching

See `## UXO placement matching` in `workflows/p2e-uxo-recipe.md` for the canonical matching algorithm, preview output format, and re-evaluation rules.

## Workflow

1. Resolve the source description or the existing story being filled. Note whether `--thin` is set; if not set, enter thick mode (the default).
2. Determine phase, tier, UXO (using `## UXO placement matching` when multiple UXOs share the cell), release, title, RRR fields, acceptance criteria, capabilities, and `priority` (see `## Priority rules`). In thick mode, gather graph context per `workflows/p2e-thicken.md ## Context gathering` BEFORE drafting the thick-spec fields; then draft the six thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`) and run sizing inference per `workflows/p2e-thicken.md ## Sizing inference` (which in turn references `workflows/p2e-sizing-rubric.md`).
3. Signal check (thick mode only): if after the first draft pass ≥ 2 thick-spec fields are still empty AND neither the provided source nor sibling stories under the same UXO supply evidence to fill them, invoke the brainstorming primitive once per `## Brainstorming escalation`, fold the answers back into the staged draft, and re-run the draft.
4. The wrapper must render a preview that annotates what was matched, inferred, defaulted, or derived-from-source (see `## Required preview contents`).
5. The wrapper must ask for a single confirm step with adjustment options for phase/tier, UXO, story fields, acceptance criteria, capabilities, sizing, thick-spec fields (thick mode), or abort.
6. On acceptance, perform the MCP write in order and stop at the first failure.
7. Create or update the story, then create acceptance criteria, then create capabilities, then create the GitHub issue labeled `ready`, then link the issue back to the story. In thick mode, the initial `mcp__p2e__stories op=create` payload includes the six thick-spec fields and the inferred `sizing` value.

## Required preview contents

Before any write, the preview must show at least:

- proposed `storyId`
- phase
- tier
- release
- UXO action (`attach` vs `create new`) and UXO title/id
- `UXO match reason:` one-liner when the cell has multiple UXOs (see `## UXO placement matching`); omit when the cell has exactly one UXO
- story title
- user story / RRR fields
- drafted acceptance criteria
- drafted capabilities
- `sizing` — in thin mode, rendered with value `M` and the annotation `defaulted`; in thick mode, rendered with the inferred tier and the annotation `derived-from-source: <evidence>` citing the inputs that forced the tier (see `## Sizing rules` below and `workflows/p2e-sizing-rubric.md` for the canonical rubric). The user may override either annotation in the confirm step.
- `priority` — the value (`P0` / `P1` / `P2` / `P3` or `null`) and its provenance: `defaulted` when no urgency signal is present in the request; `stated-by-user: <phrase>` (e.g. `stated-by-user: "urgent"`) when the user signalled urgency. The user may override in the confirm step (see `## Priority rules`).
- in **thick mode only**: the six thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`), each annotated `empty`, `derived-from-source: <evidence>`, or `derived-from-brainstorming` when the answer came from the brainstorming escalation
- a note that the GitHub issue will be created with the `ready` label on acceptance

The preview may be rendered in a host-specific visual format, but the user must be able to review the inferred values clearly.

## Required confirm step

The confirm step must support:

- accept and write
- adjust phase/tier
- adjust UXO choice or proposal
- adjust story fields
- adjust acceptance criteria
- adjust capabilities
- adjust sizing (override the defaulted or derived-from-source value with any of `XS | S | M | L | XL | XXL`; preview re-renders with the chosen value before write)
- adjust priority (override with `P0 | P1 | P2 | P3 | null`; preview re-renders with the new value and a `steered-by-user` provenance annotation before write)
- in **thick mode only**: adjust any thick-spec field (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`); preview re-renders with the new value and a `steered-by-user` provenance annotation before write
- abort

If the user does not accept, do not write.

## Drafting rules

- Acceptance criteria should be testable and concise.
- Capabilities should describe distinct behavior changes.
- Breaking changes must be marked explicitly.
- Release defaults should be derived from existing planned stories when available.
- In thick mode, the six thick-spec fields follow the source-priority order and provenance rules in `workflows/p2e-thicken.md ## Thick-spec field population`. Cite the concrete derivation source in the annotation, and leave the cell empty if no source supports it. Empty cells are preferred over filler.

## Sizing rules

- In thin mode, every new story is drafted with `sizing: M` and the annotation `defaulted`. No heuristic runs at add time — in thin mode the story usually has only a title and a small AC list, which is not enough signal to credibly infer a tier.
- In thick mode, run the sizing inference per `workflows/p2e-thicken.md ## Sizing inference`, which references `workflows/p2e-sizing-rubric.md` as the canonical rubric.
- The drafter never asks the LLM to pick a sizing in thin mode. The confirm step is the only place where sizing may change before the write in thin mode; in thick mode, the confirm step may either accept the inferred tier or override it.
- The MCP write passes the final accepted `sizing` value and the final accepted `priority` value through to `mcp__p2e__stories op=create`. If the user does not override sizing, the annotated value (`defaulted` in thin mode, inferred in thick mode) is written. If the user does not override priority, the defaulted `null` (or stated-by-user value) is written.
- The canonical rubric (XS → XXL) and the inference inputs used during thicken are documented in `workflows/p2e-sizing-rubric.md`; commands and skills must not inline that rubric — they only reference it.

## Priority rules

See `## Priority rules` in `workflows/p2e-policy.md` for the canonical priority mapping, urgency-signal vocabulary, and queue-ordering semantics.

## Brainstorming escalation

See `## Brainstorming escalation` in `workflows/p2e-policy.md` for the canonical trigger conditions, question shape, and fold-back rules. The `derived-from-brainstorming` provenance annotation is required on any thick-spec field filled from the interview.

## Error behavior

- Batch writes are fail-fast and non-atomic across phases.
- If a later phase fails, the wrapper must surface which phase failed and which item index failed.
- The successful earlier writes remain in place and may need manual reconciliation.
- If inference succeeds but a write prerequisite fails, surface the blocker and preserve the already-rendered preview context so the user understands what would have been written.
