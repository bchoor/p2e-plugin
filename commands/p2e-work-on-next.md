---
name: p2e-work-on-next
description: Thin wrapper for the canonical P2E orchestrator workflow.
argument-hint: [release=v0.3] [phase=Build] [tag=plugin] [story_id=X-00-L0] [--full-team] [--dry-run]
---

# /p2e-work-on-next

This command is a thin wrapper over `workflows/p2e-policy.md`, `workflows/p2e-work-on-next.md`, and `workflows/p2e-first-turn-briefing.md`.
Execute the shared orchestrator workflow exactly as defined there.

Pass `--full-team` to force the architect + external `superpowers:writing-plans` path on thick Standard/Architectural stories. Otherwise the implementer self-plans inline from the first-turn briefing.
