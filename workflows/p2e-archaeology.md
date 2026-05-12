# P2E Archaeology Workflow

This workflow autonomously onboards an existing codebase into P2E by reading git history, merged PRs, source structure, open issues, and documentation to infer phases, UXOs, BUILT (DONE) layers, and DRAFT stories — without a human interview step. It is the autonomous variant of `/p2e-bootstrap --mode=onboarding --backfill-built`.

## Purpose

- Populate phases, UXOs, DONE layers (one per feature-scoped merged PR), and DRAFT stories (one per open gap) for repos where the operator wants minimal human input.
- Complement `/p2e-bootstrap --mode=onboarding`, which uses a brainstorming interview; `/p2e-archaeology` infers everything it can from source artifacts and only pauses once — for the batch-confirm preview.
- Emit a proposed graph the operator can accept, adjust, or abort before any write occurs.

## Preconditions

- The operator is a member of an existing P2E project (`projectSlug` is required — every MCP call scopes by it; never hardcode a slug).
- The target repo is readable from the shell (local path or cwd).
- `gh` CLI is authenticated and has read access to the repo's pull requests and issues.
- The P2E MCP server (`mcp__p2e__*`) is reachable.
- The workflow depends on P-07-L1 (DRAFT/DONE lifecycle) and B-05-L12 (onboarding-mode preview pattern) being available in the target environment.

## Arguments

- `<repo-path>` (optional): path to the repo root; defaults to `cwd`.
- `project=<slug>` (required): P2E project slug to write into.
- `--dry-run`: read-only; prints all proposed payloads without writing anything.
- `--max-pr-age=<days>` (optional): only consider merged PRs newer than this age; default 365 days.
- `--todo-age=<days>` (optional): only surface TODO/FIXME comments older than this age; default 30 days.

## Inference passes

The workflow runs the following read passes in order. All passes are read-only; no writes occur until after the batch-confirm preview.

### Pass 1 — Git log scan

- Run `git log --oneline --merges -200` (or `git log --oneline -200` if no merge commits exist) to build a feature-signal timeline.
- Identify commits that are likely feature-scoped vs. fix-only vs. chore. Signals for feature-scoped: commit message begins with `feat`, `add`, `ship`, or `introduce`; or the commit's diff touches a new route/module file (not just a patch to an existing one).

### Pass 2 — Merged PR scan

- Run `gh pr list --state=merged --limit=100 --json number,title,body,mergedAt,labels,files` scoped to the repo.
- Apply `--max-pr-age` filter.
- Classify each PR as one of: **feature** (INTRODUCES or MODIFIES a capability), **fix** (bug fix only; skip unless it introduced a `FIXED` capability), or **chore/infra** (skip entirely).
- For each feature PR: extract a proposed capability action (`INTRODUCES` / `MODIFIES`) and capability slug from the PR title and diff summary. When uncertain, prefer `MODIFIES` over inventing a new capability.
- Fix-only PRs are included only if they introduced a capability with action `FIXED`.

### Pass 3 — Test file scan

- Enumerate test files (`**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`).
- Extract `test.todo(...)` stubs. Each stub becomes a candidate DRAFT story.

### Pass 4 — TODO/FIXME comment scan

- Scan source files for `TODO` and `FIXME` comments.
- Apply `--todo-age` filter: only surface comments whose authoring commit is older than the configured age (use `git log -S "TODO" --diff-filter=A` or equivalent blame heuristic).
- Each qualifying comment becomes a candidate DRAFT story with a one-line summary.

### Pass 5 — Open GH issue scan

- Run `gh issue list --state=open --limit=200 --json number,title,body,labels` scoped to the repo.
- Skip issues that already have a linked story in P2E (idempotency: match by `githubIssueNumber` on existing stories in `projectSlug`).
- Remaining issues become candidate DRAFT stories keyed by their `githubIssueNumber`.

### Pass 6 — README roadmap extraction

- Read `README.md` (and any `docs/ROADMAP.md` or `docs/roadmap.md` if present).
- Extract sections that describe planned or future work (headings like "Roadmap", "Upcoming", "Planned", "TODO", "Future").
- For each roadmap item: check whether matching source code or a merged PR already implements it. Items with no matching implementation become candidate DRAFT stories.

## Proposed graph data model

After all inference passes, the workflow assembles a proposed graph in memory:

```
project (scoped by projectSlug)
  └── flows[]                         ← discovered via mcp__p2e__flows op=list (never created here)
        ├── persona Flow              ← user-journey phases land here
        │     └── phases[]
        │           └── uxos[]
        │                 ├── DONE layers[]   ← one per feature-scoped merged PR
        │                 │     └── capabilities[] (INTRODUCES / MODIFIES / FIXED)
        │                 └── DRAFT layers[]  ← one per open gap (issue / TODO / test.todo / roadmap item)
        └── Foundation Flow (immutable) ← infra/platform UXOs land here
              └── phases[] (fixed slots: Surfaces, Security, Data, Compute,
                            Build-Deploy, Distribution, Observability, Cross-cutting)
                    └── uxos[]
                          ├── DONE layers[]
                          └── DRAFT layers[]
```

Both Flows are seeded by the platform when the Product is created. The workflow **discovers** them via `mcp__p2e__flows op=list product_slug=<slug>` and **never calls `op=create`** on a Flow or on a Foundation phase — the Foundation slots are fixed and immutable (MCP returns `FLOW_IMMUTABLE` if you attempt to modify or add to them).

- **Phase inference**: cluster feature-scoped PRs by file-path prefix and commit-message keywords. Propose one phase per cluster. Action-oriented names preferred (e.g., "User Authentication", "Data Ingestion"). User-journey phases belong under the persona Flow. Infra/platform clusters (auth, hosting, build pipeline, observability, data storage) map to the matching Foundation phase slot instead of becoming new phases.
- **UXO inference**: within each phase cluster, group by sub-feature. One UXO per sub-feature. Concrete objectives, not abstract benefits. Infra/platform UXOs that correspond to tech-decision PRs (choosing a framework, DB, hosting provider) should be flagged as candidates for an ADR draft under `docs/adrs/` (MADR format); the ADR path should be proposed for the UXO's `spec_file` field.
- **DONE layer**: one story per feature-scoped merged PR. Title = PR title (cleaned). Status = `DONE`. Collision key = `storyId` derived from PR number (`pr-<number>`); idempotent re-run skips if `storyId` already exists in `projectSlug`. Infra PRs attribute to the matching Foundation phase slot.
- **DRAFT layer**: one story per open gap. Title = issue title / TODO text / test.todo description / roadmap item. Status = `DRAFT`. Collision key = `githubIssueNumber` for issue-sourced drafts; a content-hash slug for TODO/test.todo/roadmap-sourced drafts.

Empty phase or UXO cells are preferred over inventing filler.

## Batch-confirm preview

Before any write, the workflow renders a single preview to the operator showing:

```
=== P2E Archaeology Preview ===
Project: <projectSlug>
Repo: <repo-path>

PHASES PROPOSED (N):
  [1] <phase name>  (<M> UXOs)
  ...

UXOs PROPOSED (N):
  [1] <phase> / <uxo>
  ...

DONE layers (from merged PRs, N):
  PR #<n>  →  <phase>/<uxo>  →  <INTRODUCES|MODIFIES|FIXED> <capability-slug>
  ...
  Skipped (fix-only or chore): N PRs

DRAFT stories (from open gaps, N):
  [issue #<n>]  <title>  (source: gh-issue)
  [todo]        <title>  (source: <file>:<line>)
  [test.todo]   <title>  (source: <file>)
  [roadmap]     <title>  (source: README)
  ...

Already-tracked (skipped, idempotent): N items

Actions:
  accept   — write all
  adjust   — edit a specific phase/uxo/story before writing
  dry-run  — print full JSON payloads, no write
  abort    — cancel
```

The operator must choose one action. The workflow does NOT write until the operator explicitly accepts. If the operator adjusts, the workflow re-renders the updated preview and re-prompts. No incremental writes during inference or adjustment.

## Write sequence

On acceptance, the workflow writes in the following order (bootstrap order):

0. **Flow discovery** — `mcp__p2e__flows op=list product_slug=<slug>` to retrieve the seeded persona Flow and Foundation Flow. Record both Flow IDs for routing. **Do not call `op=create`** on any Flow, and **never create a new phase under the Foundation Flow** — its 8 slots (Surfaces, Security, Data, Compute, Build-Deploy, Distribution, Observability, Cross-cutting) are fixed and immutable.
1. **Phases** — `mcp__p2e__phases op=create` for each proposed user-journey phase not already present (persona Flow only). Foundation phases are not created; infra UXOs are placed inside an existing Foundation slot.
2. **UXOs** — `mcp__p2e__uxos op=create` for each proposed UXO, linked to its phase. For infra/platform UXOs, link to the relevant Foundation phase slot. If the UXO corresponds to a tech-decision PR, set `spec_file` to the proposed ADR path (e.g., `docs/adrs/001-database-choice.md`, MADR format).
3. **Stories (DONE layers)** — `mcp__p2e__stories op=create` with `status=DONE` for each merged-PR layer, linked to its UXO. Skip if collision key already exists.
4. **Stories (DRAFT layers)** — `mcp__p2e__stories op=create` with `status=DRAFT` for each open-gap story, linked to its UXO. Set `githubIssueNumber` for issue-sourced drafts to enable future idempotency.
5. **Criteria** — `mcp__p2e__criteria op=create` for any inferred acceptance criteria (typically empty at archaeology time; leave for `/p2e-update-story` to thicken).
6. **Capabilities** — `mcp__p2e__capabilities op=create` for each `INTRODUCES`, `MODIFIES`, or `FIXED` capability inferred from merged PRs, linked to the corresponding DONE story.

All writes are fail-fast: if a phase write fails, UXO writes do not proceed. Earlier successful writes remain persisted; the workflow reports the failing phase and item index clearly.

## Idempotency

- **Merged PR collision**: before writing a DONE story, query `mcp__p2e__stories op=list` for the `projectSlug` and check for an existing story with the derived `storyId` (`pr-<number>`). If found, skip silently and count toward the "already-tracked" total in the preview.
- **Issue collision**: same check via `githubIssueNumber` field. If a story with that `githubIssueNumber` already exists in the project, skip.
- **Phase/UXO collision**: if a phase or UXO with the same name already exists, skip creation and reuse the existing entity for linking.
- Re-running on the same repo produces the same proposed graph and skips already-written items, making it safe to run multiple times as the repo evolves.

## Dry-run behavior

When `--dry-run` is passed (or when the operator chooses "dry-run" at the preview prompt):

- All inference passes run normally.
- The preview is rendered.
- Full JSON write payloads are printed for each entity in write order.
- No MCP mutations are issued.
- Exit cleanly with a summary line: `Dry run complete. N phases, M UXOs, P DONE layers, Q DRAFT stories proposed.`

## Error behavior and fail-fast

- If `gh` CLI is not authenticated or the repo is private and access is denied, the workflow stops immediately and reports the specific auth error. It does not attempt to proceed with partial data.
- If a merged PR's diff summary is unavailable, the PR is classified as "uncertain" and downgraded to a DRAFT story proposal (not a DONE layer) with a note in the preview.
- If `mcp__p2e__*` returns an error on any write, the workflow stops at that item, reports the failure (phase, UXO, or story title + error message), and lists the items that were not yet written so the operator can reconcile.
- The workflow does not retry failed writes. The operator re-runs after fixing the underlying issue; idempotency ensures already-written items are skipped.

## Relationship to `/p2e-bootstrap --mode=onboarding`

| Dimension | `/p2e-bootstrap --mode=onboarding` | `/p2e-archaeology` |
|---|---|---|
| Human input | Brainstorming interview (2–4 questions) | None (fully autonomous inference) |
| Merged PR backfill | Optional (`--backfill-built`) | Always included |
| TODO/FIXME scan | No | Yes |
| test.todo scan | No | Yes |
| README roadmap extraction | No | Yes |
| Preview gate | Yes (same accept/adjust pattern) | Yes (same accept/adjust pattern) |
| Write path | `mcp__p2e__*` | `mcp__p2e__*` |
| Idempotent re-run | No (no collision keys) | Yes (PR number + issue number collision keys) |

Use `/p2e-bootstrap --mode=onboarding` when the operator wants to answer a short interview to guide phase/UXO naming. Use `/p2e-archaeology` when the operator wants a fully autonomous first pass with minimal interaction.

## Multi-project scoping invariant

Every `mcp__p2e__*` call must include the `projectSlug` argument. The workflow never hardcodes a slug. The `projectSlug` is resolved from the `project=<slug>` argument at invocation time and threaded through all passes and write calls.
