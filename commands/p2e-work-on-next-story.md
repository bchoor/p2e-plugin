---
name: p2e-work-on-next-story
description: Select 1–N PLANNED stories from a filtered queue, classify each, optionally run Architect/Staff-Engineer subagents, then implement in parallel waves within a single worktree. Wave gate pauses per-story on failure.
argument-hint: [release=v0.3] [phase=Build] [tag=plugin] [story_id=X-00-L0] [--full-team] [--dry-run]
---

# /p2e-work-on-next-story

End-to-end orchestrator. Follow exactly.

## Pre-flight

1. Default project slug to `p2e`.
2. Parse named arguments: `release=...`, `phase=...`, `tag=...`, `story_id=...`, `--full-team`, `--dry-run`. Any may be combined.

## Step 1. Query + rank the PLANNED queue

Call `mcp__p2e__stories` with `{ op: "list", project_slug: "p2e", status: "PLANNED", ...optional filters }` where optional filters include `release`, `phase`, `tag` if provided.

Client-side sort (stable):
1. `release` ascending (empty last).
2. Count of unresolved `BUILDS_ON` / `DEPENDS_ON` relations pointing OUT of the story (fewer first). A relation is "unresolved" if the target story's status is not BUILT. Fetch with `mcp__p2e__relations` op=stack or inline on each story.get.
3. AC count ascending.

If `story_id=` was passed, skip the filter + sort. Call `mcp__p2e__stories` with `{ op: "get", project_slug: "p2e", story_id: "<id>" }` and verify it is PLANNED.

## Step 2. Classify each candidate

For each candidate, fetch `mcp__p2e__stories` with `{ op: "get", project_slug: "p2e", story_id }` to get capabilities/tags/AC count.

### Thin-draft check (BEFORE classification)

A "thin draft" is a story that bootstrap drafted title-only and was never fleshed out. Detect with:

```
isThinDraft(story) := story.acceptanceCriteria.length === 0
                    && story.capabilities.length === 0
```

If `isThinDraft(story)`, prompt the user via `AskUserQuestion`:

> "`<storyId>` is a thin draft (no AC, no capabilities). What now?"

Options:

1. **Flesh now (Recommended)** — invoke `/p2e-add-story --fill <storyId>` inline. On success, re-fetch the story (it now has RRR + AC + caps) and continue classification.
2. **Proceed as-is** — pass the title + UXO context to the implementer subagent and trust the model to infer. The implementer's brief should explicitly note the story was a thin draft.
3. **Skip this story** — drop it from the wave. The story stays PLANNED for later.

After handling thin drafts, apply the classification rules below.

### Classification rules

Apply in order:

1. Any capability with `isBreaking: true` → **Architectural** / sonnet
2. Any capability with action `DEPRECATES` or `REMOVES` → **Architectural** / sonnet
3. Any tag in `{ data-model, migration, infra }` → **Architectural** / sonnet
4. AC count ≥ 8 → **Architectural** / sonnet
5. Any tag in `{ ui, docs, copy }` AND AC count ≤ 3 → **Fast** / haiku
6. Else → **Standard** / sonnet

If `--full-team` is present, override every track to `Architectural` (and model to `sonnet`).

Collect `{storyId, track, model}` per story.

## Step 3. Present the queue (multiSelect)

Use `AskUserQuestion` with `multiSelect: true`. Options (top 8 default — if the sorted list has more, add a final option "Show more (up to 24)" that re-prompts with an expanded list):

- Label: `<storyId> — <title>`
- Description: `<track> (<model>) · <phase>/<tier> · <acCount> AC · release <release>`

The user picks 1–N stories.

## Step 4. Ensure a worktree

Check if you're already in a git worktree:

```bash
git rev-parse --show-toplevel
```

If the toplevel path contains `.claude/worktrees/`, you're already in one — reuse it.

Otherwise, ask the user explicitly via `AskUserQuestion` (question text: "Create a new git worktree `p2e-batch-<YYYYMMDD>-<nn>` for this batch?", options: `Yes, create worktree` / `No, cancel and stay on main`). On Yes, call the `EnterWorktree` tool with that exact name (nn = first free two-digit suffix starting at `01`). The `worktree` wording in the question text is required — `EnterWorktree` only runs when the user explicitly confirms a worktree operation.

## Step 5. Staff Engineer (only if N ≥ 2 stories selected)

Spawn the `p2e-staff-engineer` agent via the Task tool, passing `{storyIds: [...], projectSlug: "p2e"}` as the brief. Include the `opus-justified:` line (copy from the agent file's Hook contract section) as the first line of the brief passed to the Task tool.

Parse the returned JSON block for `waves`, `files_touched`, `collisions`. If the JSON is `{"error":"cycle", ...}`, stop and ask the user to resolve the dependency cycle before re-running.

Otherwise, display the wave plan + any collisions as a table, then `AskUserQuestion` with options:

- `Proceed` (Recommended)
- `Abort`

(v1 does NOT support manual wave reorder — if the user wants a different order, they abort and re-select stories in a different combination.)

If N = 1, waves = `[[storyId]]` trivially.

## Step 6. Wave loop

For each wave (serial across waves, parallel within):

### 6a. Wave start

Post a GH comment on each story's linked GH issue with text: `Starting work (wave <n>, batch <branch-name>). — bchoor-claude`. Use:

```bash
gh issue comment <issue-number> --repo <owner/repo> --body "Starting work (wave <n>, batch <branch-name>). — bchoor-claude"
```

Flip status to `PARTIAL` for all stories in the wave via `mcp__p2e__stories` with `{ op: "update", project_slug: "p2e", items: [{ story_id, status: "PARTIAL" }, ...] }`.

Note: per SKILL.md, PLANNED → PARTIAL → BUILT is the v1 status shim (replaced by OPEN / IN_PROGRESS / DONE + health in P-07-L1 when that lands).

### 6b. Spawn parallel implementer subagents (one per story)

For each story in the wave, spawn a fresh subagent via the Task tool. Pass `model: '<routed model>'` into the Agent tool's parameters so the subagent runs at the correct tier.

Brief template:

```
Story: <storyId> — <title>
Track: <Fast | Standard | Architectural>
Model: <haiku | sonnet | opus>
Metadata: phase=<phase>, tier=<tier>, release=<release>
Spec file: <specs/<slug>/<file>.yaml if the story has one, else inline below>
Acceptance criteria:
  - <list>
Capabilities to introduce/modify:
  - <list>
GitHub issue: #<number> (<url>)
Working directory: <worktree path>

Instructions:
1. If track != Fast, the orchestrator has already run the Architect and will provide its output in the brief (see below). Use it to inform your implementation plan.
2. Invoke `superpowers:writing-plans` to produce a plan at `docs/superpowers/plans/<storyId>.md`.
3. Invoke `superpowers:subagent-driven-development` to execute the plan.
4. On success, return a short summary: files touched, tests added, commands run for verification, any concerns.
5. If you hit an architectural surprise (schema change needed, cross-cutting refactor), return `{"escalate":"architect"}` or `{"escalate":"staff-engineer"}` with a `"reason":"..."` string and STOP — the orchestrator will re-route.
```

If track ≥ Standard: BEFORE spawning the implementer, first spawn the `p2e-architect` agent for that story. Include the `opus-justified:` line (copy from the agent file's Hook contract section) as the first line of the brief passed to the Task tool. Collect its output and paste it into the implementer's brief under a `## Architect output:` block.

### 6c. Wave gate

After all subagents in the wave return:

1. Run `superpowers:verification-before-completion` across the cumulative wave diff.
2. For each story, classify as PASS or FAIL based on verification output.
3. For each PASSING story, `AskUserQuestion`: "Mark `<storyId>` as BUILT?" options: `Yes, update status + toggle AC` (Recommended), `Hold for review`.
   - On Yes: `mcp__p2e__stories` update `status → BUILT`; `mcp__p2e__criteria` toggle all AC ids; post a GH comment with the subagent's summary.
   - On Hold: leave status PARTIAL; post a GH comment noting "held for human review".
4. For each FAILING story, `AskUserQuestion`: "What to do with `<storyId>`?" options: `Retry this wave`, `Mark PARTIAL + comment`, `Abort batch`.
   - `Retry`: re-spawn the implementer with the verification failure output included in the brief. Retry budget is 2 re-spawns per story **across the entire batch** (not per wave). When exhausted, the Retry option is hidden and only "Mark PARTIAL + comment" or "Abort batch" remain.
   - `Mark PARTIAL + comment`: leave PARTIAL; GH comment with failure details.
   - `Abort batch`: stop; successful stories in prior waves already flipped BUILT remain as-is.

### 6d. Escalation handling

If ANY implementer returned an `escalate` marker:

- `architect`: re-spawn `p2e-architect` for that story with the escalation reason appended, then re-spawn the implementer with the fresh architect output.
- `staff-engineer`: re-spawn `p2e-staff-engineer` with the full batch (may produce a different wave plan). Ask the user to confirm the revised plan before continuing.

Escalation consumes the retry budget (max 2 re-spawns per story). The post-escalation implementer inherits the decremented budget — if escalation uses 1 retry, only 1 retry remains for subsequent verification failures on the same story. When the budget is exhausted the story falls through to the 6c FAIL choice (Mark PARTIAL or Abort batch).

## Step 7. Finale

After the last wave completes (or user aborts):

1. `git status` in the worktree — show cumulative diff.
2. `AskUserQuestion`: "Open a PR?" options: `Open PR` (Recommended), `Commit only`, `Leave worktree as-is`.
3. On `Open PR`:
   - If there are uncommitted changes, offer to `git add` + commit them with a message listing the story ids.
   - Push the branch: `git push -u origin <branch-name>`.
   - Assemble `/tmp/p2e-batch-pr-body.md`:
     - Lists each story id, its GH issue link, pass/hold status, and any deferred items.
     - Adds a **`Closes` block** with one `Closes #<N>` line per story flipped to BUILT in this batch.
     - Stories that ended PARTIAL / held / failed appear in the body with their issue link, but WITHOUT a `Closes` line.
     - Stories with no linked GH issue are silently omitted from the Closes block.
     - End the body with `— bchoor-claude`.
   - Create PR: `gh pr create --title "<joined storyIds>: <combined titles>" --body-file /tmp/p2e-batch-pr-body.md --label "review"`.
   - Under `--dry-run`, print the generated PR body (including the Closes block) but do NOT push or create the PR.

4. For every BUILT story: on its GH issue, move label `ready` → `review` and post a final summary comment:

   ```bash
   gh issue edit <n> --repo <owner/repo> --remove-label "ready" --add-label "review"
   gh issue comment <n> --repo <owner/repo> --body "<summary>

   — bchoor-claude"
   ```

5. If **≥1 story was flipped to BUILT** in this batch, print the finisher hint:

   ```
   Run /p2e-sync-labels after PR #<n> merges to finalize labels.
   ```

## Dry-run mode

Under `--dry-run`:

- Run Steps 1–5 (queries and classify are read-only; Staff Engineer does not write).
- At Step 6, print the wave plan (including the routed model for each story) + the subagent briefs that WOULD be spawned, and the `mcp__p2e__stories.update` payload with `status:"PARTIAL"` it would send.
- Skip all subagent spawns, all MCP writes, AND all GitHub CLI writes. Dry-run is strictly read-only.
- Skip the PR creation.
- Print "dry-run complete" and exit.
