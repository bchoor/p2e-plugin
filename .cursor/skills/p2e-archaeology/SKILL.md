---
name: p2e-archaeology
description: Cursor entrypoint for the P2E archaeology workflow. Autonomously onboard an existing repo into P2E by inferring phases, UXOs, DONE layers from merged PRs, and DRAFT stories from open gaps.
---

# p2e-archaeology

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-archaeology.md`

Execute the shared archaeology workflow exactly.

## Argument hints

- `[repo-path]` (optional): path to the repo root; defaults to cwd.
- `project=<slug>` (required): P2E project slug to write into.
- `--dry-run`: read-only; prints proposed payloads without writing.
- `--max-pr-age=<days>` (optional): only consider merged PRs newer than this age (default: 365 days).
- `--todo-age=<days>` (optional): only surface TODO/FIXME comments older than this age (default: 30 days).

## Cursor-specific notes

Cross-platform mirrors: `commands/p2e-archaeology.md` (Claude), `skills/p2e-archaeology/SKILL.md` (Codex).
