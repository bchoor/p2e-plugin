---
name: p2e-bootstrap
description: Cursor entrypoint for the P2E bootstrap workflow. Supports --mode={new,onboarding}, --backfill-built (onboarding), and --all batch drafting.
---

# p2e-bootstrap

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-bootstrap.md`

Execute the shared workflow exactly.

## Argument hints

- `--mode=new` (default): source is a PRD, storyboard, or free-form description.
- `--mode=onboarding`: source is an existing repo path (defaults to cwd).
- `--backfill-built` (onboarding only): proposes DONE layers from merged PRs.
- `--all`: fan per-UXO drafting across every UXO with one combined accept.
- `--dry-run`: read-only.

## Cursor-specific notes

Cursor has no `AskUserQuestion` primitive — use the equivalent in-chat prompt the workflow describes. Cross-platform mirrors: `commands/p2e-bootstrap.md` (Claude), `skills/p2e-bootstrap/SKILL.md` (Codex).
