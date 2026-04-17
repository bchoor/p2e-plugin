---
name: p2e-add-story
description: Thin wrapper for the shared P2E add-story workflow.
argument-hint: <free-form description> [--dry-run]
---

# /p2e-add-story

This command is a thin wrapper over `workflows/p2e-policy.md` and `workflows/p2e-add-story.md`.
Follow the shared workflow contract exactly.

## Deprecated: `--fill <storyId>`

`/p2e-add-story --fill <storyId>` is deprecated as of v0.6 and delegates to `/p2e-update-story <storyId>` for one release. The fill-mode shim will be removed in a follow-up release. New thickening work should target `/p2e-update-story` directly.
