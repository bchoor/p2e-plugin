---
name: p2e-add-story
description: Draft a new P2E story from a free-form description; thick by default — all thick-spec fields populated at add time. `--thin` opts out to fast placeholder capture. `--dry-run` previews without writing.
argument-hint: <free-form description> [--thin] [--dry-run]
---

# /p2e-add-story

This command is a thin wrapper over `workflows/p2e-policy.md` and `workflows/p2e-add-story.md`.
Follow the shared workflow contract exactly.

## Modes

- **thick (default)** — populate ALL fields `/p2e-update-story` thicken would populate (including `filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`). Before drafting, gather graph context per `workflows/p2e-thicken.md ## Context gathering`. Run the sizing inference heuristic per `workflows/p2e-sizing-rubric.md`, and render the preview with `derived-from-source` annotations. If the source signal is insufficient, escalate once to the host brainstorming primitive per `workflows/p2e-add-story.md ## Brainstorming escalation`. The legacy `--thick` flag is accepted as an explicit alias for the default thick mode (a no-op).
- **thin (`--thin`)** — the fast opt-out path. Infer phase, tier, UXO, title, RRR, a conservative AC list, and a conservative capabilities list. Leave the six thick-spec fields empty. `sizing: M defaulted`.

## Preview rendering (sizing)

In thin mode, the preview's `sizing` row is `M` annotated `defaulted`. In thick mode, the row shows the inferred tier annotated `derived-from-source: <evidence>`. Either way, the confirm step lets the user override to any of `XS | S | M | L | XL | XXL` before the `mcp__p2e__stories op=create` write. The canonical 6-tier rubric lives in `workflows/p2e-sizing-rubric.md` — the command must reference it rather than inline the tier definitions.

## Brainstorming escalation

Thick mode may invoke the host brainstorming primitive (`superpowers:brainstorming` on Claude; Codex's native equivalent) when ≥ 2 thick-spec fields would otherwise land empty AND the source has no evidence to fill them. The escalation batches 2–4 clarifying questions in a single turn, folds the answers back into the staged draft, and annotates resulting fields `derived-from-brainstorming` in the re-rendered preview. Never recurses — a single round per flow. The preview/confirm gate is unchanged.

## Deprecated: `--fill <storyId>`

`/p2e-add-story --fill <storyId>` is deprecated as of v0.6 and delegates to `/p2e-update-story <storyId>` for one release. The fill-mode shim will be removed in a follow-up release. New thickening work should target `/p2e-update-story` directly.
