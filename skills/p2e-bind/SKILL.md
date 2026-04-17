---
name: p2e-bind
description: Codex entrypoint for the P2E bind workflow. Derives owner/name from git remote origin, matches against projects you are a member of, and writes .p2e/project.json as the committed repo anchor.
---

# p2e-bind

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-bind.md`

Execute the shared bind workflow exactly.

This skill has no arguments — the repo is detected automatically from `git remote get-url origin`.
