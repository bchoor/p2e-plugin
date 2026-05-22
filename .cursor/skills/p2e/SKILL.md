---
name: p2e
description: Plain-language Cursor router for P2E workflows. Route requests into bootstrap, add-story, update-story, work-on-next, sync-labels, sync, manage-uxo, archaeology, or fix using the shared workflow core.
---

# p2e router (Cursor)

Mirrors the Codex `p2e` router. Read `workflows/p2e-policy.md` first, then choose the one best-fit workflow, load it, and execute it end-to-end:

- starting or mapping a project → `workflows/p2e-bootstrap.md`
- creating a new story → `workflows/p2e-add-story.md`
- updating, thickening, steering, renaming, re-parenting, or retagging an existing story → `workflows/p2e-update-story.md`
- implementing planned work → `workflows/p2e-work-on-next.md` AND `workflows/p2e-first-turn-briefing.md`
- label / lifecycle reconciliation → `workflows/p2e-sync-labels.md`
- on-demand drift between a story and its linked GH issue body → `workflows/p2e-sync.md`
- writing/refining/auditing a UXO's `description` / `objectives[]` → `workflows/p2e-uxo-recipe.md`
- editing or adding a UXO via preview/confirm → `workflows/p2e-manage-uxo.md` + `workflows/p2e-uxo-recipe.md`
- onboarding an existing repo autonomously (no human interview) → `workflows/p2e-archaeology.md`
- fixing one or more bugs the right way (uproot + re-implement) → `workflows/p2e-fix.md`
- verifying a story end-to-end with a UAT report (`verify <story_id>`, `run UAT`, `do a visual UAT`) → `workflows/p2e-verify-story.md`

If the request is ambiguous, prefer the primary user intent and select the workflow that best matches the main goal. If it spans multiple workflows, execute the first one fully and note any follow-up needed.

## Cursor-specific notes

Cursor lacks Claude-style `AskUserQuestion` and `superpowers:*` skills. Where a workflow references those primitives, fall back to the equivalent in-chat prompt the workflow describes. No `PreToolUse` or `SessionStart` hooks — workflows that depend on them degrade gracefully.
