---
name: p2e-sync
description: Explicit Codex entrypoint for on-demand drift reconciliation between a P2E story and its linked GitHub issue body. Renders a field-level diff and reconciles in one confirm.
---

# p2e-sync

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-sync.md`

Execute the shared on-demand drift reconciliation workflow exactly.

## Hard rules

- NEVER start a reconcile write without the user having reviewed the field-level diff.
- NEVER reconcile labels — `/p2e-sync-labels` owns lifecycle labels; this skill only touches the issue body.
- NEVER call `src/lib/audit.ts` directly — every mutation goes through MCP and the MCP layer records audit rows server-side.
- Abort with a diagnostic if the GH issue body is missing the `<!-- p2e-sync:start v1 -->` fence. Instruct the user to re-run `/p2e-update-story` to regenerate the body before retrying.
- This skill is user-invoked on-demand (no polling, no webhook, no git-hook trigger).

## Codex host limitations

In the Codex host, the reconciliation direction menu exposes only:
- `Update GH from story`
- `Update story from GH`
- `Abort`

Cherry-pick per-field mode is Claude-host-only (requires `AskUserQuestion` per field). Do not expose or describe cherry-pick mode when executing in the Codex host.

## Sizing rubric

Not applicable to this skill. For sizing, see `workflows/p2e-sizing-rubric.md` (used by p2e-update-story and p2e-add-story).

## Relationship to adjacent skills

- `p2e-sync-labels` — lifecycle label reconciliation only; never touches body.
- `p2e-update-story` — write-through body patch on every update; this skill is the explicit repair path for out-of-band GH edits.
