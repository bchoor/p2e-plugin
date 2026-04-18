---
name: p2e-add-story
description: Draft a new P2E story from a free-form description; add `--dry-run` to preview without writing.
argument-hint: <free-form description> [--dry-run]
---

# /p2e-add-story

This command is a thin wrapper over `workflows/p2e-policy.md` and `workflows/p2e-add-story.md`.
Follow the shared workflow contract exactly.

## Preview rendering (sizing)

Every preview rendered by this command includes a `sizing` row defaulting to `M` annotated `defaulted`. The confirm step must let the user override the default to any of `XS | S | M | L | XL | XXL` before the `mcp__p2e__stories op=create` write. The canonical 6-tier rubric lives in `workflows/p2e-sizing-rubric.md` — the command must reference it rather than inline the tier definitions.

## Deprecated: `--fill <storyId>`

`/p2e-add-story --fill <storyId>` is deprecated as of v0.6 and delegates to `/p2e-update-story <storyId>` for one release. The fill-mode shim will be removed in a follow-up release. New thickening work should target `/p2e-update-story` directly.
