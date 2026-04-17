---
name: p2e-archaeology
description: Explicit Codex entrypoint for the P2E archaeology workflow. Autonomously reads git history, merged PRs, test.todo stubs, TODO/FIXME comments, open GH issues, and README roadmap items to emit DONE layers and DRAFT stories for an existing repo — no human interview.
---

# p2e-archaeology

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-archaeology.md`

Argument hints:

- `[repo-path]` (optional): path to the repo root; defaults to cwd.
- `project=<slug>` (required): P2E project slug to write into.
- `--dry-run`: read-only; prints proposed payloads without writing.
- `--max-pr-age=<days>` (optional): only consider merged PRs newer than this age (default: 365 days).
- `--todo-age=<days>` (optional): only surface TODO/FIXME comments older than this age (default: 30 days).

Execute the shared archaeology workflow exactly.
