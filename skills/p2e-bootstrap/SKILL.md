---
name: p2e-bootstrap
description: Explicit Codex entrypoint for the P2E bootstrap workflow. Supports --mode={new,onboarding}, --backfill-built (onboarding), and --all batch drafting.
---

# p2e-bootstrap

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-bootstrap.md`

Argument hints:

- `--mode=new` (default): source is a PRD, storyboard, or free-form description.
- `--mode=onboarding`: source is an existing repo path (defaults to cwd); runs a brainstorming-style interview and parses repo docs, route tree, test titles, recent git history, and open GH issues.
- `--backfill-built` (onboarding only): optional post-accept sub-step that proposes DONE layers from merged PRs.
- `--all`: fan per-UXO story drafting across every UXO and render one combined multi-select accept.
- `--dry-run`: read-only; prints payloads without writing.

Execute the shared bootstrap workflow exactly.
