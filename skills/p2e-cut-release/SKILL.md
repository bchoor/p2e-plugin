---
name: p2e-cut-release
description: Explicit Codex entrypoint for the P2E cut-release workflow. Cut a release through the proper gate (push → PR → CI → squash-merge → bump + tag + release on main) with an authoritative version-detection path that no longer trusts the worktree's manifest. Optionally closes out a linked P2E story (status DONE, story-log VERIFICATION entry, GH label review→done, landed comment) when --story-id=<id> is passed or inferred from the branch name. Use when the user asks to "cut a release", "ship a release", "tag and release", or "publish vX.Y.Z".
---

# p2e-cut-release

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-cut-release.md`

Execute the shared cut-release workflow exactly. The Phase 0 version-detection rewrite (fetch first → version-sort over the tag namespace → manifest cross-check) is the load-bearing fix over the previous global `/cut-release` — do not regress to reading `package.json` from the worktree.

## Codex-specific notes

- **`AskUserQuestion`** is Claude Code native. On Codex, fall back to printing the full plan (step 8 body) in the chat and waiting for an explicit `proceed` / `change bump level` / `cancel` reply before any push or merge. The semantic gate stays the same: no irreversible action runs without an affirmative human response in the current turn.
- **Browser-driver MCPs for Phase C screenshots** — Codex supports `mcp__chrome-devtools__*` and `mcp__claude-in-chrome__*` when installed. If neither is available, skip Phase C with a note in the release body ("FE files changed — please capture manual screenshots").
- **`ExitWorktree`** is Claude Code only. On Codex, skip Phase F step 35 and leave the worktree for manual cleanup or for the user's own `git worktree remove`.
- **`mcp__p2e__*` writes** require `.p2e/project.json`. On a non-P2E-bound repo, Phase E is a no-op even if `--story-id` was passed — surface the missing bind as an early stop in Phase 0.

Cross-platform mirrors: `commands/p2e-cut-release.md` (Claude), `.cursor/skills/p2e-cut-release/SKILL.md` (Cursor).
