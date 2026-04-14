---
name: p2e-sync-labels
description: Close-the-loop finisher. After an orchestrator PR merges, reconciles every GH issue whose label is `review` AND whose state is CLOSED — transitions `review` → `done` and posts a landed-on-main comment with the merge sha. Idempotent and safe to re-run.
argument-hint: [project=p2e] [pr=<n>]
---

# /p2e-sync-labels

Finishes the `ready → in-progress → review → done → close` lifecycle for every story batched by `/p2e-work-on-next-story` after the orchestrator PR merges. The GH issue was already transitioned to `review` at the end of the batch; GitHub closes it automatically via the `Closes #<N>` line in the PR body once the PR merges. This command reconciles the label side of the world: `review` → `done`, with a landed-on-main comment carrying the merge sha.

## Pre-flight

1. Follow `skills/p2e/SKILL.md` §"Pre-flight: dev server check". (Not strictly required — this command is gh-only — but having the server up keeps agents consistent and allows future reconciliation against P2E state.)
2. Parse optional named arguments:
   - `project=<slug>` — defaults to `p2e`.
   - `pr=<n>` — optional filter: only reconcile issues that were linked from this PR.

## Step 1. Resolve the target repository

Derive `<owner>/<repo>` from `mcp__p2e__projects { op: "get", project_slug: <slug> }` (the `github_repo` field). If the project has no GitHub repo configured, fail fast with the repo-missing message.

## Step 2. Enumerate candidate issues

```bash
gh issue list \
  --repo "<owner>/<repo>" \
  --label "review" \
  --state "closed" \
  --limit 100 \
  --json number,title,state,labels,closedAt,body
```

If `pr=<n>` was supplied, additionally filter the resulting list to issues that are referenced by PR `<n>` — use:

```bash
gh pr view <n> --repo "<owner>/<repo>" --json body,closingIssuesReferences
```

and intersect with `closingIssuesReferences[].number`. Drop any issue not in the intersection.

## Step 3. Resolve the merge sha (once per run)

If `pr=<n>` was supplied:

```bash
gh pr view <n> --repo "<owner>/<repo>" --json mergeCommit --jq '.mergeCommit.oid'
```

Otherwise, for each issue, use the commit that closed it:

```bash
gh issue view <issue-n> --repo "<owner>/<repo>" --json closedByPullRequestsReferences,stateReason
```

and resolve its merge sha from the first `closedByPullRequestsReferences` entry.

If no merge sha can be resolved for an issue, skip it and note this in the summary — do not guess.

## Step 4. Transition each issue: `review` → `done`

For every candidate issue:

```bash
gh issue edit <n> --repo "<owner>/<repo>" --remove-label "review" --add-label "done"
gh issue comment <n> --repo "<owner>/<repo>" --body "Landed on main as <merge-sha>.

— bchoor-claude"
```

**Idempotency (AC #9):** If an issue already carries the `done` label (or no longer carries `review`), skip the edit and do NOT post another comment. Running this command twice must be a no-op on the second pass.

**Cross-project drift (AC #10):** This command is safe to run without an open batch. If `pr=` is omitted, it reconciles every `review`-labeled, closed issue in the project's repo — useful when manual merges bypassed the orchestrator.

## Step 5. Print the summary table

Print a compact table for the user (AC #8):

```
storyId     | issue | was     | now  | sha
P-01-L11    | #41   | review  | done | 12faa39
A-01-L5     | #44   | review  | done | 12faa39
B-05-L5     | #58   | review  | done | <abc1234>
```

Columns:
- `storyId` — resolved from the issue title prefix (format `<story_id>:` is the convention `/p2e-add-story` emits). Fall back to `?` if the prefix cannot be parsed.
- `issue` — the GH issue number.
- `was` — the label that was replaced (always `review` for transitioned rows; `done` for rows skipped due to idempotency).
- `now` — the final label (`done`).
- `sha` — the merge sha carried in the landed comment.

Follow with a single-line tally: `Reconciled <M> issues (<S> skipped as already done).`

## Step 6. Exit

Done. No writes to the P2E map — this is a plugin-only label reconciler.

## Dry-run mode

Under `--dry-run`, run Steps 1–3 and print the summary table with `was → now` shown as the *intended* transition (`review` → `done`). Skip every `gh issue edit` and `gh issue comment` call. No side effects.
