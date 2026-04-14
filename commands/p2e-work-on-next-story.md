---
name: p2e-work-on-next-story
description: Select 1–N PLANNED stories from a filtered queue, classify each via the router, optionally run Architect/Staff-Engineer subagents, then implement in parallel waves within a single worktree. Wave gate pauses per-story on failure.
argument-hint: [release=v0.3] [phase=Build] [tag=plugin] [story_id=X-00-L0] [--full-team] [--dry-run]
---

# /p2e-work-on-next-story

End-to-end orchestrator. Follow exactly.

## Pre-flight

1. Follow `skills/p2e/SKILL.md` §"Pre-flight: dev server check".
2. Default project slug to `p2e`.
3. Parse named arguments: `release=...`, `phase=...`, `tag=...`, `story_id=...`, `--full-team`, `--dry-run`. Any may be combined.

## Step 1. Query + rank the PLANNED queue

```bash
bun ${CLAUDE_PLUGIN_ROOT}/lib/cli/mcp-call.ts stories "$(jq -n --arg ps "<slug>" --arg r "<release-or-empty>" --arg p "<phase-or-empty>" --arg t "<tag-or-empty>" '{op:"list",project_slug:$ps,status:"PLANNED"} + (if $r != "" then {release:$r} else {} end) + (if $p != "" then {phase:$p} else {} end) + (if $t != "" then {tag:$t} else {} end)')"
```

Client-side sort (stable):
1. `release` ascending (empty last).
2. Count of unresolved `BUILDS_ON` / `DEPENDS_ON` relations pointing OUT of the story (fewer first). A relation is "unresolved" if the target story's status is not BUILT.
3. AC count ascending.

If `story_id=` was passed, skip the filter + sort and use just that one story (verify it exists, is PLANNED).

## Step 2. Classify each candidate

For each candidate in the sorted queue (or the single story from `story_id=`):

```bash
bun ${CLAUDE_PLUGIN_ROOT}/lib/cli/classify.ts <slug> <story_id>
```

Run these in parallel (background them with `&` and `wait`) — classify.ts is an independent read per story, and sequential execution scales poorly past 4 candidates. Example for a bash loop over story ids:

```bash
for sid in "${STORY_IDS[@]}"; do
  bun ${CLAUDE_PLUGIN_ROOT}/lib/cli/classify.ts "$SLUG" "$sid" > "/tmp/p2e-classify-$sid.json" &
done
wait
# then read back each /tmp/p2e-classify-*.json
```

Collect `{storyId, track, model}` per story. If `--full-team` is present, override every track to `Architectural` (and model to `sonnet`).

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

Spawn the `p2e-staff-engineer` agent via the Task tool, passing `{storyIds: [...], projectSlug: "<slug>"}` as the brief. Include the `opus-justified:` line (copy from the agent file's Hook contract section) as the first line of the brief passed to the Task tool.

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

Flip status to `PARTIAL` for all stories in the wave (single batched call):

```bash
bun ${CLAUDE_PLUGIN_ROOT}/lib/cli/mcp-call.ts stories "$(jq -n --arg ps "<slug>" --argjson items "$ITEMS" '{op:"update",project_slug:$ps,items:$items}')"
```

where `ITEMS` is a JSON array `[{"story_id":"X-00-L0","status":"PARTIAL"}, ...]`.

Note: per SKILL.md, PLANNED → PARTIAL → BUILT is the v1 status shim (replaced by OPEN / IN_PROGRESS / DONE + health in P-07-L1 when that lands).

### 6b. Spawn parallel implementer subagents (one per story)

For each story in the wave, spawn a fresh subagent via the Task tool. Brief template:

- When spawning the implementer Task, pass `model: '<routed model>'` into the Agent tool's parameters so the subagent runs at the correct tier.

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
2. Invoke `superpowers:writing-plans` to produce a plan at `docs/superpowers/plans/B-05-L2-<storyId>.md`.
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
   - On Yes: `stories.update` status → BUILT; `criteria.toggle` all AC ids; post a GH comment with the subagent's summary.
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
     - Adds a **`Closes` block** with one `Closes #<N>` line per story flipped to BUILT in this batch (B-05-L5 AC #1). One line per issue.
     - Stories that ended **PARTIAL / held / failed** appear in the body with their issue link, but WITHOUT a `Closes` line — they stay open intentionally (AC #2).
     - Stories with **no linked GH issue** are silently omitted from the Closes block (AC #3).
     - End the body with `— bchoor-claude`.

     Example of the Closes block for a batch that flipped 3 of 5 stories to BUILT (AC #12):

     ```
     ## Closes

     Closes #41
     Closes #44
     Closes #47

     <!-- P-02-L1 and B-03-L2 are PARTIAL and remain open. -->
     ```

   - Create PR:

     ```bash
     gh pr create --title "<joined storyIds>: <combined titles>" --body-file /tmp/p2e-batch-pr-body.md --label "review"
     ```

   - Under `--dry-run`, print the generated PR body (including the Closes block) but do NOT push or create the PR (AC #4).

4. For every BUILT story: on its GH issue, move label `ready` → `review` and post a final summary comment:

   ```bash
   gh issue edit <n> --repo <owner/repo> --remove-label "ready" --add-label "review"
   gh issue comment <n> --repo <owner/repo> --body "<summary>

   — bchoor-claude"
   ```

5. If **≥1 story was flipped to BUILT** in this batch, print the finisher hint (AC #11):

   ```
   Run /p2e-sync-labels after PR #<n> merges to finalize labels.
   ```

   Skip this line if zero stories were flipped BUILT.

## Dry-run mode

Under `--dry-run`:

- Run Steps 1–5 (queries and classify are read-only; Staff Engineer does not write).
- At Step 6, print the wave plan (including the routed model for each story) + the subagent briefs that WOULD be spawned, and the stories.update command with `status:"PARTIAL"` it would run. Example wave plan format:

  ```
  Wave plan (dry-run):
  | Story    | Track         | Model  | Wave |
  |----------|---------------|--------|------|
  | P-01-L12 | Fast          | haiku  | 1    |
  | B-05-L7  | Standard      | sonnet | 1    |
  | B-01-L6  | Architectural | sonnet | 2    |
  ```
- Skip all subagent spawns, all MCP writes (`stories.update`, `criteria.toggle`), AND all GitHub CLI writes (`gh issue comment`, `gh issue edit`, `gh pr create`, `git push`). Dry-run is strictly read-only.
- Skip the PR creation.
- Print "dry-run complete" and exit.
