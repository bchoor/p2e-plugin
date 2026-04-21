# P2E Bootstrap Workflow

This workflow turns a free-form product description OR an existing repo into a draft journey map: phases, tiers, UXOs, and optional per-UXO DRAFT stories. It is a shared behavior spec, not a wrapper-specific command description.

## Purpose

- Produce the initial story-map skeleton for a new or lightly drafted P2E project, OR onboard an existing repo into an accurate P2E map without pretending the repo is greenfield.
- Preserve the current MCP-first workflow.
- Keep the language wrapper-agnostic: the wrapper should ask, render, and confirm, but not hard-code platform entrypoint details.
- Emit stories as `DRAFT` so `/p2e-update-story` can thicken them per the lifecycle-v2 contract (P-07-L1). No GitHub issues are created at draft time.

## Modes

This workflow supports two entry points selected via `--mode={new,onboarding}`. When `--mode` is omitted, `new` is the default.

### `--mode=new` (default)

Current behavior, made explicit:

- Source is a PRD, storyboard, or free-form product description (inline text or a referenced document).
- Produces the journey + phases + UXOs + optional per-UXO thin-story drafting.
- No repo introspection — the wrapper trusts the source document.

### `--mode=onboarding`

For existing repos that need a P2E map reflecting what actually exists:

- Accepts a repo path; defaults to the current working directory.
- Uses a shared interview (referenced abstractly as `superpowers:brainstorming` on Claude and its Codex equivalent) that asks 2–4 batched questions in a single turn. Prefer one combined question over multiple rounds. Typical questions:
  - Which docs should the workflow read? (default: `README`, `docs/`, any top-level `*.md`)
  - Which paths to ignore? (default: `node_modules/`, `dist/`, `build/`, `.git/`, lockfiles)
  - Which GitHub labels indicate story-tracked work vs noise?
  - Is there an existing PRD or spec doc that should anchor the phases?
- Parses the repo's `README` + `/docs` + route tree + test titles + last 200 commits on the history log + open GitHub issues to propose phases and UXOs.
- Renders the same accept/adjust preview matrix as `--mode=new`.
- Empty cells are preferred over filler — if the repo evidence does not support a tier row, leave it empty.

## Preconditions

- The target project must already exist in P2E.
- If the project already has a drafted journey, the workflow should prefer append semantics and ask before overwriting.
- `--mode=new` accepts an inline description or a referenced document as the source.
- `--mode=onboarding` requires a readable repo path, and `gh` auth for the repo if GitHub-issue context is requested in the interview.

## Workflow

1. Parse the source according to the selected mode:
   - `new`: extract product vision, primary persona, user journey, stage outcomes, quality ambitions, and constraints from the PRD or description.
   - `onboarding`: run the brainstorming interview, then extract the same journey signals from repo docs, route tree, test titles, recent commit history, and open GH issues.
2. If the source is ambiguous, the wrapper should ask at most four clarifying questions using the host's native prompt primitive. Prefer one combined question over multiple rounds.
3. Draft the journey metadata, phases, and UXOs in memory.
4. The wrapper should render a preview matrix that shows phases across tiers and the proposed UXOs in each cell.
5. The wrapper should ask the user what to do next: accept and write, adjust a phase, adjust a cell, dive deeper, regenerate, add per-UXO DRAFT stories (see `## Per-UXO story drafting`), run `--backfill-built` (onboarding only), or abort.
6. If the user chooses to dive deeper, the wrapper may use brainstorming-style exploration to refine a phase or UXO before re-rendering.
7. On acceptance, write the structure through MCP in a single batch per entity type, preserving fail-fast behavior.

## Per-UXO story drafting

After the phases + UXOs are accepted, the wrapper can draft thin DRAFT stories for any UXO:

- Default: drafting is one-UXO-at-a-time. The user picks a UXO, the wrapper proposes 0–N title-only stories with a one-line justification citing the source passage (or the repo evidence in onboarding mode), and writes the accepted ones as `DRAFT` via `mcp__p2e__stories op=create`.
- `--all`: fan drafting across every UXO in the matrix in a single pass, then render ONE combined multi-select accept so the user reviews every proposed draft in one view before any write. Fail-fast on the batched write; earlier successful drafts remain persisted.
- All drafts written this way use `status=DRAFT`. The workflow does NOT create GitHub issues at draft time. Thickening and issue creation are deferred to `/p2e-update-story`.

## `--backfill-built` (onboarding only)

Optional sub-step after the phases + UXOs are accepted in `--mode=onboarding`:

- Scans merged PRs on the onboarding repo via `gh pr list --state=merged`.
- Proposes `DONE` layer stories on matching UXOs, with `INTRODUCES` capabilities inferred from PR titles + diff summaries.
- The user accepts per-PR or skips the entire step. The wrapper must not write anything unless explicitly accepted.
- Mapping a PR to a UXO is heuristic; when uncertain the wrapper should skip the PR rather than guess.

## Drafting rules

- Phases should be action-oriented and reflect the user journey.
- UXOs should be concrete objectives, not abstract benefits. **When drafting or refining a UXO's `description` and `objectives[]`, follow the canonical recipe in `workflows/p2e-uxo-recipe.md` — objectives[] first, MECE-audit within the UXO, then description as succinct articulation.**
- Empty cells are allowed and are better than inventing filler.
- CORE rows should capture the baseline viable journey.
- ADVANCED and STRETCH rows should only appear when the source text (or the onboarding-mode repo evidence) supports them.
- Story drafts are written as `DRAFT` status regardless of mode; no GH issue creation at draft time.

## Write behavior

- Create phases first, then UXOs, then (if requested) DRAFT stories.
- Reuse existing phases or UXOs when the project already has partial structure and the user chose append behavior.
- Surface the final matrix and the write payloads when running in dry-run mode.
- In `--mode=onboarding`, the `--backfill-built` sub-step (when accepted) writes `DONE` stories and their `INTRODUCES` capabilities via the same MCP surface.

## Brainstorming skill reference

The onboarding interview is referenced abstractly in this workflow and in the wrappers. The Claude wrapper resolves the reference against the `superpowers:brainstorming` skill; the Codex wrapper resolves it against its native brainstorming primitive. The workflow contract only requires that the wrapper batch 2–4 questions in a single turn and re-enter the preview loop with the interview answers folded in.
