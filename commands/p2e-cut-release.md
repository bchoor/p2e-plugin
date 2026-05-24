---
name: p2e-cut-release
description: Cut a release through the proper gate (push → PR → CI → squash-merge → bump + tag + release on main) with an authoritative version-detection path that no longer trusts the worktree's manifest. Optionally closes out a linked P2E story (status DONE, story-log VERIFICATION entry, GH label review→done, landed comment) when --story-id=<id> is passed or inferred from the branch name. Replaces the previous global /cut-release.
argument-hint: [--story-id=<id>] [--no-pr] [--no-screenshots] [--draft]
---

# /p2e-cut-release

This command is a thin wrapper over `workflows/p2e-policy.md` and `workflows/p2e-cut-release.md`.

Read both, then execute `workflows/p2e-cut-release.md` end-to-end exactly as written.

## Flags

- `--story-id=<id>` — explicit P2E story to close out on release. ID matches `[A-Z]+-[0-9]+-L[0-9]+` (e.g. `DR-08-L8`, `P-01-L3`, `A-04-L7`). If omitted, the workflow infers from the current branch name (`feat/DR-08-L8-foo` → `DR-08-L8`); if no unambiguous inference is possible, it asks via `AskUserQuestion` before proceeding.
- `--no-pr` — emergency hotfix. Skip Phase A; cut directly on `main` from the current branch. Requires an explicit `AskUserQuestion` confirm because it bypasses CI.
- `--no-screenshots` — skip Phase C even if FE files changed.
- `--draft` — pass `--draft` to `gh release create`.

## Why this replaces /cut-release

The previous global `/cut-release` read the current version from `package.json` in the worktree and computed "last tag" via `git describe --tags --abbrev=0`. Both sources are local-worktree-relative: a branch made off an older tag produces a stale read of both, and the proposed bump clashes with an already-released tag. This workflow's Phase 0 replaces both reads with `git fetch --tags` first + `git tag --sort=-v:refname` (which is tag-namespace authoritative, not HEAD-bounded), plus a manifest cross-check that *informs* but does not *drive* the bump.

## Story closeout policy carve-out

`workflows/p2e-policy.md` reserves the `IN_REVIEW → DONE` transition for humans. This command's pre-flight `AskUserQuestion` plan-approval gate IS the human authorization, so the carve-out applies — see `workflows/p2e-policy.md → ## Status lifecycle → Cut-release carve-out`. When `--story-id` resolves and the story is at `IN_REVIEW`, the workflow flips it to `DONE`, appends a `kind: VERIFICATION` story-log entry, posts a landed-on-main comment to the linked GitHub issue, and flips its `review → done` label.

Cross-platform mirrors: `skills/p2e-cut-release/SKILL.md` (Codex), `.cursor/skills/p2e-cut-release/SKILL.md` (Cursor).
