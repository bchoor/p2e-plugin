---
name: p2e-bootstrap
description: Thin wrapper for the shared P2E bootstrap workflow.
argument-hint: <doc-path or inline description or repo path> [project=<slug>] [--mode={new,onboarding}] [--backfill-built] [--all] [--dry-run]
---

# /p2e-bootstrap

This command is a thin wrapper over `workflows/p2e-policy.md` and `workflows/p2e-bootstrap.md`.
Follow the shared workflow contract exactly.

Argument hints:

- `--mode=new` (default): source is a PRD, storyboard, or free-form description.
- `--mode=onboarding`: source is an existing repo path (defaults to cwd); runs a brainstorming interview and parses repo docs, route tree, test titles, recent git history, and open GH issues.
- `--backfill-built` (onboarding only): optional post-accept sub-step that proposes DONE layers from merged PRs.
- `--all`: fan per-UXO story drafting across every UXO and render one combined multi-select accept.
- `--dry-run`: read-only; prints payloads without writing.
