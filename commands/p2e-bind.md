---
name: p2e-bind
description: Bind this repo to a P2E project by reading git remote origin, matching against projects you are a member of, and writing .p2e/project.json as the committed anchor.
argument-hint: (no arguments — repo is detected from git remote origin)
---

# /p2e-bind

This command is a thin wrapper over `workflows/p2e-policy.md` and `workflows/p2e-bind.md`.
Follow the shared workflow contract exactly.

Run this once per repo checkout to anchor it to a P2E project. The resulting
`.p2e/project.json` file should be committed so all team members share the same binding.
