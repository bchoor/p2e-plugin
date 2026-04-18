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

## Deprecated fill mode

The legacy `--fill <storyId>` path is deprecated as of v0.6 and now delegates to the shared `workflows/p2e-update-story.md` contract for one release before being removed. Any wrapper that still accepts `--fill` must forward the call verbatim to `/p2e-update-story` (Claude) or `p2e-update-story` (Codex) with the same story id. The fill-mode shim does not implement its own preview or write path; it is a pointer only. New thickening work should target `/p2e-update-story` directly.

## Preconditions

- The target project must exist.
- The target UXO must exist or be created as part of the flow.

## Workflow

1. Resolve the source description or the existing story being filled.
2. Determine phase, tier, UXO, release, title, RRR fields, acceptance criteria, and capabilities.
3. The wrapper must render a preview that annotates what was matched, inferred, or defaulted.
4. The wrapper must ask for a single confirm step with adjustment options for phase/tier, UXO, story fields, acceptance criteria, capabilities, or abort.
5. On acceptance, perform the MCP write in order and stop at the first failure.
6. Create or update the story, then create acceptance criteria, then create capabilities, then create the GitHub issue labeled `ready`, then link the issue back to the story.

## Required preview contents

Before any write, the preview must show at least:

- proposed `storyId`
- phase
- tier
- release
- UXO action (`attach` vs `create new`) and UXO title/id
- story title
- user story / RRR fields
- drafted acceptance criteria
- drafted capabilities
- `sizing` — always rendered with value `M` and the annotation `defaulted` (see `## Sizing rules` below and `workflows/p2e-sizing-rubric.md` for the canonical rubric)
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
- adjust sizing (override the defaulted `M` with any of `XS | S | M | L | XL | XXL`; preview re-renders with the chosen value before write)
- abort

If the user does not accept, do not write.

## Drafting rules

- Acceptance criteria should be testable and concise.
- Capabilities should describe distinct behavior changes.
- Breaking changes must be marked explicitly.
- Release defaults should be derived from existing planned stories when available.

## Sizing rules

- Every new story is drafted with `sizing: M` and the annotation `defaulted`. No heuristic runs at add time — at add time the story usually has only a title and a small AC list, which is not enough signal to credibly infer a tier. Heuristic inference lives in `/p2e-update-story` thicken (see `workflows/p2e-update-story.md` and `workflows/p2e-sizing-rubric.md`).
- The drafter never asks the LLM to pick a sizing at add time. The confirm step is the only place where sizing may change before the write.
- The MCP write passes the final accepted `sizing` value through to `mcp__p2e__stories op=create`. If the user does not override, `sizing=M` is written.
- The canonical rubric (XS → XXL) and the inference inputs used during thicken are documented in `workflows/p2e-sizing-rubric.md`; commands and skills must not inline that rubric — they only reference it.

## Error behavior

- Batch writes are fail-fast and non-atomic across phases.
- If a later phase fails, the wrapper must surface which phase failed and which item index failed.
- The successful earlier writes remain in place and may need manual reconciliation.
- If inference succeeds but a write prerequisite fails, surface the blocker and preserve the already-rendered preview context so the user understands what would have been written.
