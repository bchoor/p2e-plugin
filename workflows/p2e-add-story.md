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

- **thin (default)** — infer phase, tier, UXO, title, RRR, a conservative acceptance-criteria list, and a conservative capabilities list from the description. Do NOT populate the thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`). Leave `sizing` at the defaulted `M`. This is the fastest path and is the right default when the intent is to capture a placeholder for later thickening.
- **thick (`--thick`)** — populate ALL fields the `/p2e-update-story` thicken path would populate, including the six thick-spec fields. Run the sizing inference heuristic per `workflows/p2e-sizing-rubric.md` and annotate the inferred tier `derived-from-source: <evidence>` instead of `defaulted`. If the source signal is insufficient, invoke the host brainstorming primitive exactly once (see `## Brainstorming escalation`) to batch 2–4 questions before drafting. Thick mode is opt-in; thin-mode behavior is unchanged.

Both modes share the preview/confirm contract below. Thick mode adds more fields and richer provenance annotations; it does not change the accept/adjust/abort gate.

## Deprecated fill mode

The legacy `--fill <storyId>` path is deprecated as of v0.6 and now delegates to the shared `workflows/p2e-update-story.md` contract for one release before being removed. Any wrapper that still accepts `--fill` must forward the call verbatim to `/p2e-update-story` (Claude) or `p2e-update-story` (Codex) with the same story id. The fill-mode shim does not implement its own preview or write path; it is a pointer only. New thickening work should target `/p2e-update-story` directly.

## Preconditions

- The target project must exist.
- The target UXO must exist or be created as part of the flow.

## UXO placement matching

When a phase+tier cell has more than one UXO, the drafter MUST score each candidate against the story description using `title + objective + objectives[]` and pick the best match — never by cuid sort order.

### Matching algorithm

1. Fetch candidate UXOs via `mcp__p2e__uxos op=get` (or from the project data already in context).
2. For each candidate, build a match signal from:
   - `title` (always present)
   - `objective` (prose description, may be null)
   - `objectives[]` (array of short goal bullets; may be empty — falls back to `title + objective` only)
3. Score the story description against each candidate's signal. Pick the highest-scoring UXO.
4. Record the match reason as a single phrase, e.g. `"surfaces relevant signals matches 'reduce time-to-first-insight'"` or `"title 'Technical charting' matches charting work"`.
5. If no `objectives[]` are set on any candidate, the fallback signal is `title + objective` — equivalent to pre-A-03-L4 behavior.

### Preview output

The preview MUST include a `UXO match reason:` line immediately after the UXO row:

```
UXO: P-01 — Discover product  (attach)
UXO match reason: objective bullet "reduce time-to-first-insight" matches story intent
```

If the cell has only one UXO, omit the match reason (no ambiguity to explain).

## Workflow

1. Resolve the source description or the existing story being filled. Note whether `--thick` is set; if so, enter thick mode.
2. Determine phase, tier, UXO (using `## UXO placement matching` when multiple UXOs share the cell), release, title, RRR fields, acceptance criteria, and capabilities. In thick mode, additionally draft the six thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`) and run sizing inference per `workflows/p2e-sizing-rubric.md`.
3. Signal check (thick mode only): if after the first draft pass ≥ 2 thick-spec fields are still empty AND the source lacks evidence to fill them, invoke the brainstorming primitive once per `## Brainstorming escalation`, fold the answers back into the staged draft, and re-run the draft.
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
- in **thick mode only**: adjust any thick-spec field (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`); preview re-renders with the new value and a `steered-by-user` provenance annotation before write
- abort

If the user does not accept, do not write.

## Drafting rules

- Acceptance criteria should be testable and concise.
- Capabilities should describe distinct behavior changes.
- Breaking changes must be marked explicitly.
- Release defaults should be derived from existing planned stories when available.
- In thick mode, the six thick-spec fields follow the same provenance rules as `/p2e-update-story` thicken: cite the concrete derivation source in the annotation, and leave the cell empty if no source supports it. Empty cells are preferred over filler.

## Sizing rules

- In thin mode, every new story is drafted with `sizing: M` and the annotation `defaulted`. No heuristic runs at add time — in thin mode the story usually has only a title and a small AC list, which is not enough signal to credibly infer a tier.
- In thick mode, the drafter runs the rubric's inference heuristic against the staged post-draft projection (title + capabilities + AC count + tags + `files_hint` length) and proposes a tier annotated `derived-from-source: <evidence>`. The evidence string cites the specific inputs that forced the tier. The rubric in `workflows/p2e-sizing-rubric.md` is authoritative; thick mode must not inline it.
- The drafter never asks the LLM to pick a sizing in thin mode. The confirm step is the only place where sizing may change before the write in thin mode; in thick mode, the confirm step may either accept the inferred tier or override it.
- The MCP write passes the final accepted `sizing` value through to `mcp__p2e__stories op=create`. If the user does not override, the annotated value (`defaulted` in thin mode, inferred in thick mode) is written.
- The canonical rubric (XS → XXL) and the inference inputs used during thicken are documented in `workflows/p2e-sizing-rubric.md`; commands and skills must not inline that rubric — they only reference it.

## Brainstorming escalation

When the source signal is insufficient to credibly populate the thick-spec fields, the wrapper invokes a shared brainstorming primitive exactly once per flow to batch clarifying questions in a single turn. The Claude wrapper resolves the reference against the `superpowers:brainstorming` skill; the Codex wrapper resolves it against its native brainstorming primitive (the same pattern used by `workflows/p2e-bootstrap.md --mode=onboarding`).

### When to escalate

Escalate in thick mode **only** when ALL of the following are true after the first draft pass:

1. Two or more of the six thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`) are still empty.
2. The original source does not contain evidence to fill them (no linked PRD, no issue body, no spec YAML, no sibling stories with matching capabilities).
3. The user's original invocation did not explicitly opt out of escalation (for example via a `--no-brainstorm` flag on the wrapper, if implemented).

Do NOT escalate for thin mode. Do NOT escalate when the gap is a single optional field. Do NOT escalate more than once per flow — if answers still leave major gaps, leave the cells empty and continue to the preview. Empty cells are preferred over filler.

### Question shape

The wrapper must batch 2–4 concrete questions in a single turn. Prefer multiple-choice or closed-form questions over open-ended prose. Typical questions:

- Which files or modules does this story touch? (pick from detected candidates, or free-form)
- What are the non-negotiable constraints? (timezone / currency / backwards-compat / visible-screen / etc.)
- What is explicitly out of scope?
- Which existing document or sibling story most closely describes the shape of this work?
- What command would verify this story is done? (defaults to the track's `verificationCmd`)

### Fold-back rules

- Answers fold back into the staged draft as if they had been in the original source, with the provenance annotation `derived-from-brainstorming` on any field filled from the interview.
- The brainstorming interview does not bypass the preview/confirm gate — the wrapper must still render the preview and ask for accept/adjust/abort before any write.
- If the user aborts the brainstorming interview (or declines to answer), continue to the preview with the fields left empty. Do not force-answer on the user's behalf.

## Error behavior

- Batch writes are fail-fast and non-atomic across phases.
- If a later phase fails, the wrapper must surface which phase failed and which item index failed.
- The successful earlier writes remain in place and may need manual reconciliation.
- If inference succeeds but a write prerequisite fails, surface the blocker and preserve the already-rendered preview context so the user understands what would have been written.
