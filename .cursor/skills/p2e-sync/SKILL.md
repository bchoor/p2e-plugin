---
name: p2e-sync
description: Cursor entrypoint for on-demand drift reconciliation between a P2E story and its linked GitHub issue body. Renders a field-level diff and reconciles in one confirm.
---

# p2e-sync

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-sync.md`

Execute the shared on-demand drift reconciliation workflow exactly.

## Cursor-specific notes

Like the Codex host, Cursor's reconciliation direction menu exposes only:
- `Update GH from story`
- `Update story from GH`
- `Abort`

Cherry-pick per-field mode is Claude-host-only (it requires `AskUserQuestion`). Do not expose or describe cherry-pick mode in Cursor.

Cross-platform mirrors: `commands/p2e-sync.md` (Claude), `skills/p2e-sync/SKILL.md` (Codex).
