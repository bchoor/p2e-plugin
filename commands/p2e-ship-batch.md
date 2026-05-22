---
name: p2e-ship-batch
description: Heavyweight batch ship — delegates per-story implementation to /p2e-work-on-next, then layers 360° verify, per-story PR + review, conditional security review (auto-detected from diff paths), and a rich-Markdown roll-up doc.
argument-hint: [release=v0.13] [phase=Build] [tag=plugin] [priority=P0,P1] [story_id=X-00-L0]... [--exclude=Y-11-L2]... [--max=5] [--full-team] [--security|--no-security] [--stop-on-fail] [--cut-release] [--budget=<token-days>] [--yes] [--dry-run]
---

# /p2e-ship-batch

This command is a thin wrapper over `workflows/p2e-policy.md`, `workflows/p2e-ship-batch.md`, `workflows/p2e-work-on-next.md` (Phase B delegates to it), and `workflows/p2e-first-turn-briefing.md` (carries the implementer deviation-reporting contract).

Read all four, then execute `workflows/p2e-ship-batch.md` end-to-end exactly as written.

Pass `--full-team` through to work-on-next to force the architect + `superpowers:writing-plans` path on thick Standard/Architectural stories. Pass `--security` to force `/security-review` on every story regardless of diff-path trigger, or `--no-security` to suppress it even when triggered (document the override reason in a `kind: DECISION` story-log entry per the workflow).
