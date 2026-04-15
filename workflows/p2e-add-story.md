# P2E Add Story Workflow

This workflow drafts a single story, its acceptance criteria, and its capabilities from a description or from an existing thin draft. The wrapper should keep the interaction and rendering generic while preserving the MCP-first behavior.

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
3. The wrapper should render a preview that annotates what was matched, inferred, or defaulted.
4. The wrapper should ask for a single confirm step with adjustment options for phase/tier, UXO, story fields, acceptance criteria, capabilities, or abort.
5. On acceptance, perform the MCP write in order and stop at the first failure.
6. Create or update the story, then create acceptance criteria, then create capabilities, then create the GitHub issue labeled `ready`, then link the issue back to the story.

## Drafting rules

- Acceptance criteria should be testable and concise.
- Capabilities should describe distinct behavior changes.
- Breaking changes must be marked explicitly.
- Release defaults should be derived from existing planned stories when available.

## Error behavior

- Batch writes are fail-fast and non-atomic across phases.
- If a later phase fails, the wrapper must surface which phase failed and which item index failed.
- The successful earlier writes remain in place and may need manual reconciliation.
