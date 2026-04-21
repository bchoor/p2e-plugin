---
name: p2e-manage-uxo
description: Edit or add a UXO via the canonical writing recipe with an annotated preview + confirm gate; `--edit` (default) steers an existing UXO, `--add` creates a new one.
argument-hint: <uxo_id> [--edit | --add] [--phase=<title>] [--tier=<name>] [--dry-run]
---

# /p2e-manage-uxo

This command is a thin wrapper over `workflows/p2e-policy.md`, `workflows/p2e-manage-uxo.md`, and `workflows/p2e-uxo-recipe.md`.
Follow the shared workflow contract exactly.

## Modes

- **`--edit <uxo_id>`** (default) — fetch the target UXO plus its story stack, run the recipe's MECE-audit against staged state, render the annotated preview, and on Accept write via `mcp__p2e__uxos op=update`.
- **`--add <uxo_id> --phase=<title> --tier=<name>`** — scaffold a blank UXO under the given phase+tier, run the recipe-driven drafting pass, render the annotated preview, and on Accept write via `mcp__p2e__uxos op=create`.

Both modes share the same preview layout, the same confirm actions (Thicken objectives[] / Steer `<field>` / Flag gap / Accept / Abort), and the same recipe. `--dry-run` renders the preview + MCP payload without writing in either mode.

## Preview rendering

The preview must show `title`, `tier`, `description`, and `objectives[]` (current vs proposed) each annotated with provenance (`populated` / `empty` / `derived-from-source: <evidence>` / `derived-from-stories: <story_ids>` / `derived-from-brainstorming` / `steered-by-user`). When the UXO has stories, the preview also renders a **MECE audit section** with a story-landing coverage table (every story placed on exactly one proposed objective; orphan and multi-landed rows flagged) and a **gap-flag section** listing concerns the audit surfaced but that are not in the proposed `objectives[]`.

## Flag gap

The **Flag gap** confirm action opens a sub-prompt to capture a scope gap per `workflows/p2e-uxo-recipe.md` `## Gap flagging`. The capture path can be: a thin-DRAFT story under this UXO (writes immediately via `mcp__p2e__stories op=create`), a new UXO proposal (recorded in the preview's gap-flag section), or a leave-as-note (reference only). The gap is never silently added to the current UXO's `objectives[]` — the recipe forbids dilution.

## Brainstorming escalation

The thicken path may invoke the host brainstorming primitive (`superpowers:brainstorming` on Claude; Codex's native equivalent) when the staged `objectives[]` has fewer than 3 bullets AND the UXO's title + stories + sibling UXOs do not supply enough evidence to credibly reach 3. The escalation batches 2–4 clarifying questions in a single turn, folds the answers back into the staged draft, and annotates resulting bullets `derived-from-brainstorming` in the re-rendered preview. Single round per flow; never bypasses the preview/confirm gate. See `workflows/p2e-manage-uxo.md` `## Brainstorming escalation` for the full contract.
