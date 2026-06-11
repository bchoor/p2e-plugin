---
name: p2e-work-on-next
description: Pick the next open P2E story/stories (story_id= or limit=N) and run the v2 supervisor — parallel story-lead waves, tiered reviews, stories end at IN_REVIEW (no release).
argument-hint: [release=v0.3] [phase=Build] [tag=plugin] [story_id=X-00-L0] [limit=3] [--full-team] [--workflow] [--dry-run]
---

# /p2e-work-on-next

This command is a thin wrapper over `workflows/p2e-policy.md`, `workflows/p2e-work-on-next.md`, and `workflows/p2e-first-turn-briefing.md`.
Execute the shared orchestrator workflow exactly as defined there. The main session acts as the supervisor (`/model fable` high-effort recommended); story implementation is delegated to `p2e-story-lead` subagents per wave.

Flags: `limit=N` selects up to N stories (default 1). `--full-team` forces the architect + `superpowers:writing-plans` path. `--workflow` forces the dynamic-Workflow batch mode (auto at N ≥ 4). The run ends with stories at `IN_REVIEW` — releases are user-triggered via `/p2e-cut-release`, never by this command.
