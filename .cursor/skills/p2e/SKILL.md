---
name: p2e
description: Plain-language Cursor router for P2E workflows. Route requests into bootstrap, add-story, update-story, work-on-next, ship-batch, cut-release, sync-labels, sync, manage-uxo, archaeology, or fix using the shared workflow core.
---

# p2e router (Cursor)

Mirrors the Codex `p2e` router. Read `workflows/p2e-policy.md` first, then choose the one best-fit workflow, load it, and execute it end-to-end:

- starting or mapping a project → `workflows/p2e-bootstrap.md`
- creating a new story → `workflows/p2e-add-story.md` + `workflows/p2e-thicken.md` (thick by default — all six thick-spec fields and graph context; `--thin` opts out)
- updating, thickening, steering, renaming, re-parenting, or retagging an existing story → `workflows/p2e-update-story.md`
- implementing planned work → `workflows/p2e-work-on-next.md` AND `workflows/p2e-first-turn-briefing.md` (pick the next open story/stories and run the v2 supervisor; story-lead waves on Claude Code, sequential fallback on Codex/Cursor; stories end at IN_REVIEW, no release)
- shipping or batching MULTIPLE planned stories through implementation + 360° verify + per-story PR + review + roll-up doc (e.g., "ship all v0.13 stories", "work through the release backlog with full gates") → `workflows/p2e-ship-batch.md` (which delegates Phase B to `workflows/p2e-work-on-next.md`); the heavyweight cousin of work-on-next — reach for it when shipping a release
- label / lifecycle reconciliation → `workflows/p2e-sync-labels.md`
- on-demand drift between a story and its linked GH issue body → `workflows/p2e-sync.md`
- writing/refining/auditing a UXO's `description` / `objectives[]` → `workflows/p2e-uxo-recipe.md`
- editing or adding a UXO via preview/confirm → `workflows/p2e-manage-uxo.md` + `workflows/p2e-uxo-recipe.md`
- onboarding an existing repo autonomously (no human interview) → `workflows/p2e-archaeology.md`
- fixing one or more bugs the right way (uproot + re-implement) → `workflows/p2e-fix.md`
- verifying a story end-to-end with a UAT report (`verify <story_id>`, `run UAT`, `do a visual UAT`) → `workflows/p2e-verify-story.md`
- cutting a release (`cut a release`, `ship a release`, `tag and release`, `publish v0.X.Y`) → `workflows/p2e-policy.md` + `workflows/p2e-cut-release.md`. Closes out a linked P2E story (status DONE + VERIFICATION log + GH label flip + landed comment) when `--story-id=<id>` is passed or inferred from the branch name (carve-out: `workflows/p2e-policy.md → ## Status lifecycle → Cut-release carve-out`).

If the request is ambiguous, prefer the primary user intent and select the workflow that best matches the main goal. If it spans multiple workflows, execute the first one fully and note any follow-up needed.

## Cursor-specific notes

Cursor lacks Claude-style `AskUserQuestion` and `superpowers:*` skills. Where a workflow references those primitives, fall back to the equivalent in-chat prompt the workflow describes. No `PreToolUse` or `SessionStart` hooks — workflows that depend on them degrade gracefully.
