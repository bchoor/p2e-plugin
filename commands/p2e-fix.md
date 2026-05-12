---
name: p2e-fix
description: Fix one or more bugs by uprooting and re-implementing — not by layering patches. Enforces a fix-shape gate (what to delete first, then what to replace) per bug.
argument-hint: <bug-1>[, <bug-2>, ...] [--dry-run] [--allow-band-aid="<bug-id>=<reason>"]
---

# /p2e-fix

This command is a thin wrapper over `workflows/p2e-policy.md` and `workflows/p2e-fix.md`.
Follow the shared workflow contract exactly.

## Inputs

A free-form list of bug descriptors (comma- or newline-separated). Each item may be a plain-language description, a file path with optional line, a GitHub issue ref (`#123` or `owner/repo#123`), or a P2E story id (`B-05-L21`).

## Phase 2 primitive (Claude only)

Use `superpowers:systematic-debugging` for the root-cause phase. If it returns without a confident cause, escalate one round and then stop — do not move past the fix-shape gate without a written cause.

## Flags

- `--dry-run` — render intake, root cause, and the fix-shape gate output for each bug; stop before applying.
- `--allow-band-aid="<bug-id>=<reason>"` — record an explicit per-bug exception with justification. Logged verbatim. Use sparingly per Operative 1C.

## Cross-platform note

This command exists in equivalent form as the Codex skill `p2e-fix` and the Cursor skill `p2e-fix`. All three read the same `workflows/p2e-fix.md`. See `reference/cross-platform-pattern.md`.
