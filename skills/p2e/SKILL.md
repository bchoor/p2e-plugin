---
name: p2e
description: Plain-language Codex router for P2E workflows. Route requests into bootstrap, add-story, update-story, work-on-next, ship-batch, cut-release, sync-labels, manage-uxo, archaeology, or fix using the shared workflow core.
---

# p2e router

Read these first:
- `workflows/p2e-policy.md`

Then choose the one best-fit workflow, load it, and execute it end-to-end:
- requests about starting or mapping a project -> read `workflows/p2e-bootstrap.md`, then follow that workflow exactly
- requests about creating a new story -> read `workflows/p2e-add-story.md`, then follow that workflow exactly
- requests about updating, thickening, steering, renaming, re-parenting, or retagging an existing story -> read `workflows/p2e-update-story.md`, then follow that workflow exactly (this is the canonical path for what used to be `/p2e-add-story --fill`)
- requests about implementing planned work -> read `workflows/p2e-work-on-next.md` AND `workflows/p2e-first-turn-briefing.md`, then follow the work-on-next workflow exactly
- requests about shipping or batching MULTIPLE planned stories through implementation + 360° verify + per-story PR + review + roll-up doc (e.g., "ship all v0.13 stories", "work through the release backlog with full gates", multi-story `release=`/`phase=`/`tag=` filters) -> read `workflows/p2e-policy.md` AND `workflows/p2e-ship-batch.md` AND `workflows/p2e-work-on-next.md` AND `workflows/p2e-first-turn-briefing.md`, then follow the ship-batch workflow exactly. Phase B delegates to work-on-next without modification — do not fork its logic. This is the heavyweight cousin of `/p2e-work-on-next`; route to work-on-next directly for single-story or fast-track spot work.
- requests about label or lifecycle reconciliation -> read `workflows/p2e-sync-labels.md`, then follow that workflow exactly
- requests about drift reconciliation between a story and its linked GitHub issue body (on-demand, field-level) -> read `workflows/p2e-sync.md`, then follow that workflow exactly
- requests about writing, refining, or auditing a UXO's `description` / `objectives[]` -> read `workflows/p2e-uxo-recipe.md` and apply the recipe (objectives[] first → MECE-audit within the UXO → description as succinct articulation); this is a reference recipe, loadable standalone or mid-flow from bootstrap / update-story
- requests about editing an existing UXO or adding a new UXO via the preview/confirm flow -> read `workflows/p2e-manage-uxo.md` (shared behavior) and `workflows/p2e-uxo-recipe.md` (the recipe it applies), then follow that workflow exactly. `--edit <uxo_id>` (default) steers an existing UXO; `--add <uxo_id> --phase=<title> --tier=<name>` creates a new UXO through the same preview/confirm UX. `--dry-run` renders preview + MCP payload without writing.
- requests about autonomously onboarding an existing repo with no human interview (infer phases, UXOs, DONE layers from merged PRs, DRAFT stories from open gaps) -> read `workflows/p2e-archaeology.md`, then follow that workflow exactly
- requests about fixing one or more bugs the right way (uproot + re-implement, not band-aid layering) -> read `workflows/p2e-fix.md`, then follow that workflow exactly. Inputs are a list of bug descriptors (plain descriptions, file paths, GH issue refs, P2E story ids). Enforces a per-bug fix-shape gate (Deleted / Replaced / Preserved / Band-aid rejected) and verifies both the original problem and absence of regressions before completion.
- requests about verifying a story (`verify <story_id>`, `run UAT on issue #N`, `produce a UAT report`, `do a visual UAT`) -> read `workflows/p2e-verify-story.md`, then follow that workflow exactly. Sources ACs from P2E MCP (preferred) / spec / GH issue / free-form, reproduces each AC against the running app via a browser-driver MCP, captures visible-pixel evidence, and assembles a self-contained rich-HTML report. Output is information only — does not move the story's lifecycle.
- requests about cutting a release (`cut a release`, `ship a release`, `tag and release`, `publish v0.X.Y`) -> read `workflows/p2e-policy.md` AND `workflows/p2e-cut-release.md`, then follow the cut-release workflow exactly. The Phase 0 version-detection rewrite (fetch first → version-sort the tag namespace → manifest cross-check) is load-bearing — never regress to reading `package.json` from the worktree. Closes out a linked P2E story (status DONE + VERIFICATION log + GH label flip + landed comment) when `--story-id=<id>` is passed or inferred from the branch name; the carve-out lives in `workflows/p2e-policy.md → ## Status lifecycle → Cut-release carve-out`.

## Persona routing (work-on-next only)

When executing `workflows/p2e-work-on-next.md`, this is the persona invocation matrix:

| Persona | Default | Skip when |
| --- | --- | --- |
| `p2e-architect` | Standard / Architectural tracks | Story `constraints` does NOT contain `approach-review` AND caller did NOT pass `--full-team` |
| `superpowers:writing-plans` | Multi-story batches OR architect ran | Single-story thick run with architect skipped (see `workflows/p2e-policy.md#self-plan-inline`) |
| `p2e-staff-engineer` | Batch size ≥ 2 | Batch size = 1 |
| `codex:rescue` | Two-strike escalation when caller is Codex | Caller is Claude Code (architect handles escalation instead) |

Fast-track stays lightweight: no architect, no staff engineer, no writing-plans regardless of opt-in flags.

If the request is ambiguous, prefer the primary user intent and select the workflow that best matches the main goal.
If the request genuinely spans multiple workflows, choose the first required workflow, execute it fully, and note any follow-up workflow that may still be needed after it completes.
