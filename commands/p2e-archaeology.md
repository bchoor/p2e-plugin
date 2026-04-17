---
name: p2e-archaeology
description: Autonomously onboard an existing repo into P2E by inferring phases, UXOs, DONE layers from merged PRs, and DRAFT stories from open gaps — no interview required.
argument-hint: [repo-path] project=<slug> [--dry-run] [--max-pr-age=<days>] [--todo-age=<days>]
---

# /p2e-archaeology

This command is a thin wrapper over `workflows/p2e-policy.md` and `workflows/p2e-archaeology.md`.
Follow the shared workflow contract exactly.

Argument hints:

- `[repo-path]` (optional): path to the repo root; defaults to cwd.
- `project=<slug>` (required): P2E project slug to write into. Never hardcode; always pass through from the operator.
- `--dry-run`: read-only; prints proposed payloads without writing.
- `--max-pr-age=<days>` (optional): only consider merged PRs newer than this age (default: 365 days).
- `--todo-age=<days>` (optional): only surface TODO/FIXME comments older than this age (default: 30 days).
