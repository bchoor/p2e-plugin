# P2E Add Story Workflow

This workflow drafts a single story, its acceptance criteria, and its capabilities from a description or from an existing thin draft. The wrapper should keep the interaction and rendering generic while preserving the MCP-first behavior.

## Hard rules

- Stay in story-creation mode. Do not reinterpret the request as a troubleshooting task just because the described story mentions a bug, regression, or validation problem.
- Infer the story fields and present them back to the user before any mutation.
- Never write the story, acceptance criteria, capabilities, or GitHub issue until the user has seen the preview and had a chance to correct it.
- If MCP auth, project lookup, or required source context is unavailable, stop with a short blocker message instead of improvising or silently writing partial data.

## Purpose

- Turn a story description into a structured P2E story entry.
- Support both create mode and fill mode.
- Create the GitHub issue after the MCP write succeeds with the `ready` label, then link it back to the story.

## Preconditions

- The target project must exist.
- The target UXO must exist or be created as part of the flow.
- If the story is being filled from a thin draft, the workflow should update the existing story instead of creating a new one.

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
- abort

If the user does not accept, do not write.

## Drafting rules

- Acceptance criteria should be testable and concise.
- Capabilities should describe distinct behavior changes.
- Breaking changes must be marked explicitly.
- Release defaults should be derived from existing planned stories when available.

## Error behavior

- Batch writes are fail-fast and non-atomic across phases.
- If a later phase fails, the wrapper must surface which phase failed and which item index failed.
- The successful earlier writes remain in place and may need manual reconciliation.
- If inference succeeds but a write prerequisite fails, surface the blocker and preserve the already-rendered preview context so the user understands what would have been written.
