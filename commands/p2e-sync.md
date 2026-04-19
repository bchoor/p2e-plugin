---
name: p2e-sync
description: On-demand drift reconciliation between a P2E story and its linked GH issue — renders a field-level diff and reconciles in one confirm (Update GH from story / Update story from GH / Cherry-pick per-field / Abort). User-invoked only; no polling, no webhook, no git-hook.
argument-hint: <story_id> [project=<slug>] [--dry-run]
---

# /p2e-sync

This command is a thin wrapper over `workflows/p2e-policy.md` and `workflows/p2e-sync.md`.
Follow the shared workflow contract exactly.

Argument hints:

- `<story_id>` (required): the human-readable story id (e.g. `B-05-L4`). If omitted, prints a usage summary.
- `project=<slug>` (optional): P2E project slug. Omit only if the project can be inferred unambiguously from context.
- `--dry-run` (optional): read-only — renders the diff and prints would-be write payloads without issuing any writes.

## What this command does

1. Fetches the P2E story via MCP `stories.get` and the linked GH issue body via `gh api`.
2. Parses the GH issue body (must contain the `<!-- p2e-sync:start v1 -->` fence — abort with a diagnostic if it's missing, pointing at `/p2e-update-story` to regenerate the body).
3. Renders a field-level diff covering: title, RRR (storyAs / storyWant / storySoThat), background, AC list (text only — checkbox state is not reconciled), capabilities list, and release.
4. Presents one `AskUserQuestion` with the reconciliation direction:
   - `Update GH from story` — regenerate the GH issue body from current P2E state using the same `formatIssueBody` template as `/p2e-update-story`'s write-through patch; `gh issue edit` in place, preserving labels and comment thread.
   - `Update story from GH` — parse GH body back into MCP fields; call `stories.update`, `criteria` batch, `capabilities` batch.
   - `Cherry-pick per-field` — `AskUserQuestion` per drifted field to choose which source wins.
   - `Abort` — no changes.
5. Writes an AuditLog entry for every touched field (via MCP — never directly from the plugin) and posts a GH comment summarizing direction + fields.

## Brainstorming escalation

Not applicable. This command does not infer or thicken fields — it reconciles existing state. No escalation to `superpowers:brainstorming`.

## Sizing rubric

Not applicable. This command does not modify sizing. See `workflows/p2e-sizing-rubric.md` for sizing rules used by `/p2e-update-story` and `/p2e-add-story`.

## Relationship to other commands

- **`/p2e-sync-labels`** — reconciles lifecycle labels only; never touches the issue body.
- **`/p2e-update-story`** — write-through body patch on every non-lifecycle write; creates the issue on OPEN promotion.
- **`/p2e-sync`** — explicit repair for GH-to-story drift, user-invoked on-demand.
