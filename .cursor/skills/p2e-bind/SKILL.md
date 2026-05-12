---
name: p2e-bind
description: Cursor entrypoint for the P2E bind workflow. Derives owner/name from git remote origin, matches against projects you are a member of, and writes .p2e/project.json as the committed repo anchor.
---

# p2e-bind

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-bind.md`

Execute the shared bind workflow exactly.

This skill has no arguments — the repo is detected automatically from `git remote get-url origin`.

## Cursor-specific notes

The Claude `SessionStart` and `PreToolUse` hooks that activate after binding (project briefing, slug-mismatch gate) are NOT available in Cursor. Use `/p2e-bind` to write `.p2e/project.json`, then rely on the always-applied `.cursor/rules/p2e-policy.mdc` for orientation in Cursor sessions.

Cross-platform mirrors: `commands/p2e-bind.md` (Claude), `skills/p2e-bind/SKILL.md` (Codex).
