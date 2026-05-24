# P2E Cut-Release Workflow

Cut a release through the proper gate — push branch, open PR, wait for CI green, squash-merge, then bump + tag + release on `main`. Optionally close out a linked P2E story (set `IN_REVIEW → DONE`, append a `VERIFICATION` story-log entry, flip the GitHub issue `review → done` label, post a landed-on-main comment) when `--story-id=<id>` is passed or inferred from the current branch name.

Replaces the previous global `~/.claude/commands/cut-release.md`. The shipped behavior is identical to that command **plus**: an authoritative version-detection path that no longer trusts the current worktree's manifest, and the optional story-closeout integration.

## Purpose

- Cut a release that always reflects the actual latest tag on `origin`, not a stale worktree snapshot.
- Run a PR + CI gate by default; emergency `--no-pr` bypass requires a confirmation prompt.
- Carry the release through to a `gh release create` with auto-generated notes.
- Optionally close out a linked P2E story end-to-end when `--story-id=<id>` is passed or inferred.
- Capture acceptance-criteria screenshots for FE-touching releases on platforms that support a browser-driver MCP.

## Inputs

```
/p2e-cut-release [--story-id=<id>] [--no-pr] [--no-screenshots] [--draft]
```

| Flag | Default | Effect |
| --- | --- | --- |
| `--story-id=<id>` | inferred from branch | Close out the named story (must be at `IN_REVIEW`) on success. ID matches `[A-Z]+-[0-9]+-L[0-9]+` (e.g. `DR-08-L8`, `P-01-L3`, `A-04-L7`). |
| `--no-pr` | off | Emergency hotfix: skip Phase A, cut directly on `main` from the current branch. Requires explicit confirm via `AskUserQuestion`. |
| `--no-screenshots` | off | Skip Phase C even if FE files changed. |
| `--draft` | off | Pass `--draft` to `gh release create` so the release publishes as a draft. |

## Bind precondition

This workflow honors the bind convention from `workflows/p2e-policy.md`: if any P2E MCP write is going to happen (Phase F story-closeout), `.p2e/project.json` must exist at the repo root. The `project_slug` is always read from that file; never asked of the user. If the file is missing AND a story-id was passed or inferred, stop and direct the user to run `/p2e-bind` first.

If the file is missing AND no story-id is involved, Phase F is silently a no-op — the release still ships.

## Phase 0 — Pre-flight (version-truth and plan)

The previous `/cut-release` had a load-bearing bug here: it read the current version from `package.json` in the worktree and computed "last tag" via `git describe --tags --abbrev=0`. Both sources are local-worktree-relative. On a branch made off an older tag, `git describe` returns only the most recent tag *reachable from HEAD's ancestry*, not the highest tag in the repo — a branch made off `v0.10.1` reports `v0.10.1` as "last tag" even if `v0.10.3` exists on `main`. The proposed bump (`v0.10.2`) then clashes with an existing tag.

This workflow's pre-flight replaces both reads with authoritative sources, in this order:

1. **Fetch first.** `git fetch --tags --prune --prune-tags origin`. No pre-flight read happens before this completes — even with a fixed sort order, a stale local repo would miss tags pushed by others.

2. **Compute "latest released version" by version-sort, not by describe.** Use:
   ```
   git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -1
   ```
   This returns the highest semver-shaped tag in the entire local-after-fetch tag namespace, independent of HEAD's ancestry. Strip the leading `v` to get `<latest>`. If no tags exist yet, treat `<latest>` as `0.0.0`.

3. **Read manifest version from the source-of-truth list (not just `package.json`).** Probe each candidate in order; use the first that exists:
   - `.claude-plugin/plugin.json` (`"version"` key)
   - `.codex-plugin/plugin.json` (`"version"` key)
   - `marketplace.json` (root `"version"` or `plugins[].version` — match by plugin name from `.claude-plugin/plugin.json`)
   - `package.json` (`"version"` key)
   - `Cargo.toml` (`[package].version`)
   - `pyproject.toml` (`[project].version` or `[tool.poetry].version`)
   - `__version__.py` or `version.py` (`__version__ = "..."`)
   - `VERSION` (whole-file string)

   The manifest read is informational, NOT the source of truth. It is compared against `<latest>`:
   - manifest **equals** `<latest>` → expected steady state (most recent release was tagged from this manifest value). Proceed.
   - manifest **less than** `<latest>` → the worktree is stale relative to `origin/main`. Stop the workflow and direct the user to rebase onto `origin/main` (or pull `main` if already on it). Do not propose a bump from a stale value.
   - manifest **greater than** `<latest>` → an in-progress release commit is sitting in the worktree (someone bumped without tagging). Surface this and let the user decide: tag the current manifest value, or roll back the manifest and re-bump.

4. **Pick the next version against `<latest>`, not against the manifest.** Default rule: patch bump (e.g. `0.10.3 → 0.10.4`). Infer the bump level from the commit subjects since the latest tag — read them with `git log v<latest>..origin/main --oneline` (NOT against HEAD; the branch's own commits add to this set in Phase A, they don't replace it). Conventional-commit signals:
   - any commit subject containing `BREAKING CHANGE`, `feat!`, `fix!`, or `refactor!` → major bump
   - any commit subject starting `feat(` or `feat:` → minor bump
   - otherwise → patch bump

   Compute `<next>` = bumped `<latest>`. The user can override the bump level in step 8.

5. **Sanity-check that `v<next>` does not already exist.** Run:
   ```
   git rev-parse --verify "refs/tags/v<next>" 2>/dev/null
   ```
   If it returns a sha, the proposed tag exists already — stop the workflow and report the conflict (the user should investigate; this almost always means another agent or human shipped a release between fetch and now, OR the bump-level inference picked an already-released version because of a stale assumption).

6. **Snapshot branch state.** Capture in a structured pre-flight object:
   - current branch: `git rev-parse --abbrev-ref HEAD`
   - working tree dirtiness: `git status --short`
   - commits on this branch since `v<latest>` that are NOT yet on `origin/main`: `git log --left-right v<latest>...HEAD --oneline` filtered to `>`-only entries

7. **If on `main` with unreleased commits already on it (and the tree is clean):** skip Phase A; jump to Phase B. (Still require step 8 below.) If on `main` with no unreleased commits: stop — nothing to release.

8. **Release-plan authorization (REQUIRED).** Before any push / merge / tag / release / story write, present the full plan via `AskUserQuestion` — a single consolidated confirmation that pre-authorizes every irreversible action in this run. The harness treats `/p2e-cut-release` as initiation, not authorization; this step is what unlocks the merge in Phase A and the story write in Phase F.

   Format:
   - **header**: `Cut release v<next>?`
   - **body**: single question, options `Proceed | Change bump level | Cancel`. Body shows:
     - Branch: `<current-branch>` → squash-merge to `main` (or "directly on main" if `--no-pr`)
     - PR: `#<n>` reuse / "will create new" / "n/a (--no-pr)"
     - Version bump: `v<latest> → v<next>` (level: patch / minor / major; inferred from commit subjects)
     - Manifest probe: `<file>:<version>` (the one that won the source-of-truth probe)
     - Commits since `v<latest>` (on branch + on main): one-line list of subjects, `<count>` total
     - Repo: `<owner>/<name>` (confirm in allowlist `bchoor/*` / `columenlabs/*`)
     - Story closeout: `<story-id>` (resolved or "(none)"); current status: `<status>`; gating: `<reason if blocked>` — see Phase F gating
     - Flags: `--no-pr=<bool> --no-screenshots=<bool> --draft=<bool>`
     - Actions to be authorized by your answer:
       1. `git push origin <branch>` (skipped if `--no-pr`)
       2. `gh pr create` / reuse PR `#<n>` (skipped if `--no-pr`)
       3. wait for CI, then `gh pr merge #<n> --squash --delete-branch` (skipped if `--no-pr`)
       4. on `main`: bump manifest(s), commit `Release v<next>`, tag `v<next>`, push tag
       5. `gh release create v<next> --generate-notes`
       6. (if story-id resolved AND gate clears) `mcp__p2e__stories op=update status=DONE` + `mcp__p2e__story_log op=append` + GH label flip + landed comment

   On "Proceed": all subsequent steps in this run are explicitly authorized; do not re-prompt for individual irreversible actions.

   On "Change bump level": ask for `patch | minor | major`, recompute `<next>`, re-run step 5 (tag-existence check), re-present the plan.

9. **Repo allowlist check.** If `<owner>/<name>` is outside `bchoor/*` and `columenlabs/*`, stop and confirm with the user before any push. (This is in addition to step 8.)

### Story-id resolution rules

Computed during step 8 plan-build, surfaced in the plan body, and then used by Phase F.

1. If the user passed `--story-id=<id>` on the command line, use it verbatim. If the string does not match `^[A-Z]+-[0-9]+-L[0-9]+$`, stop the workflow with a clear error before any push.

2. Otherwise, parse the current branch name for the same regex. If exactly one match is found, that's the resolved story-id. Examples:
   - `feat/DR-08-L8-folder-walk-progress` → `DR-08-L8`
   - `spec/P-01-L3-hosted-live-comments` → `P-01-L3`
   - `design/A-04-L7-sidebar-redesign` → `A-04-L7`
   - `feat/foo-bar` → no match
   - `feat/DR-08-L8-and-P-01-L3-combined` → multiple matches → fall through to step 3

3. If branch parsing did not produce exactly one match AND `.p2e/project.json` exists, call `mcp__p2e__stories op=list project_slug=<slug> status=IN_REVIEW` and surface the list via `AskUserQuestion` so the user can pick one or "(none — skip story closeout)". Do not silently guess.

4. If no story-id resolves and the user did not pass `--story-id`, Phase F is a no-op for this run.

## Phase A — Land the work via PR

All irreversible steps in this phase (push, merge) are pre-authorized by the user's "Proceed" answer in step 8. Do not re-prompt.

10. Commit any uncommitted work as a `feat(...)` / `fix(...)` / `style(...)` commit on the feature branch. **Never** commit the version bump on the feature branch — that happens in Phase B on `main`.

11. `git push -u origin HEAD` (set upstream if first push).

12. Create or reuse a PR:
    - `gh pr view --json number,state -q '{n:.number,s:.state}' 2>/dev/null` — if a PR exists for this branch, reuse it. Otherwise `gh pr create --fill` (or with explicit `--title` / `--body` derived from the commits).
    - For FE-touching changes (any of `*.{ts,tsx,jsx,css,scss,html,vue,svelte}` in the diff vs `main`), include the Phase C screenshot capture below in the PR body before waiting for CI.

13. **Wait for CI to pass.** Use the platform's monitor / poll primitive on `gh pr checks <pr>`:
    - Emit one line per terminal check (`succeeded | failed | cancelled | timeout`).
    - Stop when no `pending` remains.
    - If any check failed → stop, report which one, ask the user before retrying or overriding.
    - Reasonable timeout: 30 min. Bump if the repo's CI is slower; ask the user if the timeout hits.

14. Merge: `gh pr merge <pr> --squash --delete-branch` (or `--merge` / `--rebase` if the repo's default differs — check `gh repo view --json mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed`). If the merge call is denied by the harness, surface the error and ask the user to allowlist `gh pr merge` in settings; do not silently retry or work around it.

## Phase B — Cut release on main

15. Sync main: in the main worktree, `git fetch origin && git checkout main && git pull --ff-only`.

16. Bump version in every manifest from the source-of-truth list in step 3 that exists in this repo (not just the one that won the probe). All of them must match the new version after this step. The plugin repos in this org typically carry both `.claude-plugin/plugin.json` AND `.codex-plugin/plugin.json` — bump both. If a `marketplace.json` exists at the root, bump the matching plugin entry too (the historical "marketplace.json drift" gotcha — see commit `b89c71c`).

17. Commit: `Release v<next> — <one-line summary>` with a longer body listing the changes (read commits since the previous tag).

18. Tag: `git tag -a v<next> -m "v<next> — <summary>"`.

19. Push: `git push origin main && git push origin v<next>`.

20. `gh release create v<next> --title "v<next> — <summary>" --generate-notes`. Always pass `--generate-notes` so every release ships with a body auto-built from the PRs since the previous tag — no intervention required, and never an empty release page. If the repo has a `.github/release.yml`, GH will group the entries by category. If `--draft` is also set, append it.

## Phase C — AC screenshots (FE-touching releases only)

Skipped if `--no-screenshots` was passed.

21. Detect FE diff since the previous tag:
    ```sh
    git diff --name-only "v<latest>..v<next>" -- \
      '*.tsx' '*.ts' '*.jsx' '*.js' '*.css' '*.scss' '*.html' '*.vue' '*.svelte'
    ```
    If empty → skip Phase C.

22. Detect dev script:
    - Read `package.json`. Look for `scripts.dev`, `scripts.dev:client`, `scripts.start`, in that order.
    - If none → skip Phase C with a note in the release summary ("FE files changed but no dev script found — manual screenshots needed").

23. If a `.claude/release-setup.sh` exists in the repo, run it first (login seeding, fixture loading).

24. Spin up the dev server in the background; poll the task's output file with an `until` loop until you see the ready line; extract the actual port (Vite picks an alternate if 5173 is busy).

25. Drive Chrome via the browser-driver MCP (`mcp__chrome-devtools__*` preferred, `mcp__claude-in-chrome__*` fallback — same selection rule as `/p2e-verify-story`):
    - `new_page` at the dev URL
    - `resize_page` 1280×720
    - `evaluate_script` to inspect the changed UI's bounding box (model picks the selector by reading the diff — e.g. status-bar change → `.statusbar`)
    - `take_screenshot` saving to `${TMPDIR}/<feature>-v<next>-full.png`
    - Crop a focused strip with PIL or `sips` based on the bounding box

26. Upload: `gh release upload v<next> <files> --clobber`.

27. Edit notes: `gh release edit v<next> --notes "<original notes>\n\n## Acceptance criteria — verified\n\n![](asset-url)\n..."`.

28. Stop the dev server task.

## Phase D — Report

29. `gh release view v<next> --json url -q .url` and report the URL plus a one-line summary of phases run (which phases fired, which skipped, story-closeout outcome).

## Phase E — Story closeout (when a story-id resolved)

Skipped when no story-id resolved per the rules in Phase 0.

30. **Gate the closeout.** Fetch the story: `mcp__p2e__stories op=get project_slug=<slug> story_id=<id>`. The closeout fires only if:
    - `status == "IN_REVIEW"` — anything else (`DRAFT`, `OPEN`, `IN_PROGRESS`, `BLOCKED`, already `DONE`) is a no-op for the status write, but the story-log + GH-label steps still run for `IN_REVIEW` and `DONE` (idempotent). For `IN_PROGRESS` / `BLOCKED` / `OPEN`, stop and surface the lifecycle skip: print "Story `<id>` is at `<status>` — releasing without closing it out. Manually advance via /p2e-update-story or /p2e-work-on-next if appropriate." and emit a `kind: NOTE` story-log entry recording the skip. Do not auto-flip statuses that skip lifecycle steps.

31. **Set status DONE** (only if currently `IN_REVIEW`):
    ```
    mcp__p2e__stories op=update project_slug=<slug> story_id=<id> status=DONE
    ```
    This is the policy carve-out documented in `workflows/p2e-policy.md` (## Status lifecycle → Cut-release carve-out): the pre-flight `AskUserQuestion` in step 8 is the human-authorization gate, satisfying the "IN_REVIEW → DONE is a human action" rule.

32. **Append the VERIFICATION story-log entry.** Always runs when the story resolved AND status is `IN_REVIEW` or `DONE`:
    ```
    mcp__p2e__story_log op=append project_slug=<slug> items=[{
      "story_id": "<id>",
      "kind": "VERIFICATION",
      "author": "orchestrator",
      "message": "Shipped in v<next>. Release: <release-url>. Closed via /p2e-cut-release."
    }]
    ```
    Use `items=[{...}]` array form (mandatory per `workflows/p2e-work-on-next.md` story-log policy).

33. **Flip the GitHub issue label and post a landed comment.** Same shape as `workflows/p2e-sync-labels.md`, scoped to this one issue:
    - Resolve the linked issue: `mcp__p2e__stories op=get` returns `github_issue` if the story has one. If absent, skip steps 33a–c with a `kind: NOTE` log entry ("no linked issue — label and comment skipped").
    - 33a. `gh issue edit <n> --remove-label review --add-label done` (use `scripts/sync-github-label.sh` if present in the repo, otherwise raw `gh`).
    - 33b. `gh issue comment <n> --body "Landed on main in v<next>. Release: <release-url>"`.
    - 33c. If the issue is still open, `gh issue close <n>`.

34. **Print the closeout summary.** One-line per side-effect actually applied. Phase D's report includes this.

## Phase F — Teardown

Best-effort cleanup of the scaffolding this run created. Skip silently anything that doesn't apply. **Never** delete a branch or worktree with commits that aren't on `origin/main` or a pushed tag — if you find one, report it and stop instead.

35. If this run was executed from a git worktree (cwd under `.claude/worktrees/`, or `EnterWorktree` was called this session): `ExitWorktree(action: "remove")`. If it refuses due to changes that are actually already on the remote (the squash-merged feature commit, the pushed `Release v<next>` commit), re-invoke with `discard_changes: true` — those are safe.

36. Delete leftover local branches: the feature branch (if `--delete-branch` left a local copy because the checkout was on it), any auto-generated `worktree-…` / `claude/…` branch the worktree was created on, and any temp release branch (`__release_…`). Verify each is reachable from `origin/main` or the new tag first, then `git branch -D <name>`.

37. `git fetch --prune origin` to drop the stale remote-tracking ref for the deleted PR branch.

38. Confirm clean: `git worktree list` shows no entry for this run's worktree, `git branch -a | grep <topic>` is empty except whatever you intentionally kept. Note in the report if local `main` is intentionally left divergent from `origin/main` (e.g. it carried unrelated unpushed commits you didn't release).

## Failure isolation

- Pre-flight failures (stale manifest, tag exists, repo not in allowlist) → stop before any push. No state mutated.
- Phase A CI failure → stop with the failing check; user decides whether to retry or override. No tag created.
- Phase B failures (push rejected, tag conflict, `gh release create` 4xx) → stop. The local commit + tag may exist on the main worktree; either roll them back manually OR fix the conflict and re-run `git push origin main && git push origin v<next> && gh release create …`.
- Phase E gate-skip (story not at `IN_REVIEW`) → release still ships; story is **not** moved to `DONE`. A `kind: NOTE` entry records the skip and the actual status. The user can advance the story manually.
- Phase E MCP failures (network, auth, bind mismatch) → release still ships. Surface the MCP error, retain a `kind: NOTE` story-log if it succeeded partially, and tell the user the closeout needs manual completion (`/p2e-update-story <id> status=DONE` + `/p2e-sync-labels --story <id>`).

## Story log checkpoints

- `kind: VERIFICATION` (Phase E step 32, always when story resolved + status was `IN_REVIEW` or `DONE`): message shape locked in step 32.
- `kind: NOTE` (Phase E step 30, when the story resolved but status was not `IN_REVIEW`): `"Released v<next> without status closeout — story at <status>. Closeout skipped per /p2e-cut-release lifecycle gate."`
- `kind: NOTE` (Phase E step 33, when story resolved but no linked GH issue): `"Released v<next>; GH label flip and landed comment skipped — story has no linked issue."`

## Platform asymmetries

- **Phase C browser screenshots** are Claude Code and Codex (when a browser-driver MCP is installed). Cursor falls back to a "FE files changed — please capture manual screenshots" note in the release body; no auto-driving of Chrome.
- **`AskUserQuestion`-style confirm** is native to Claude Code. Codex and Cursor fall back to a printed plan + a literal "type 'proceed' to continue" prompt in the chat. The semantic gate is the same: no irreversible action runs without an affirmative human response in the current turn.
- **`ExitWorktree`** is Claude Code only; Codex / Cursor skip Phase F step 35 and just leave the worktree for manual cleanup (or for `git worktree remove` invoked by the user).
- **`mcp__p2e__*` writes** require `.p2e/project.json` to exist (the bind file). On a non-P2E-bound repo, Phase E is a no-op even if `--story-id` was passed — surface the missing bind as an early stop in Phase 0.

## Dry-run behavior

Not currently supported. Cut-release is short enough that adding a dry-run mode duplicates the pre-flight plan presentation in step 8. The "Proceed | Change bump level | Cancel" gate is the canonical dry-run surface — present the full plan, get explicit consent, then act.
