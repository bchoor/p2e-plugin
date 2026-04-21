---
name: p2e-manage-uxo
description: Explicit Codex entrypoint for the P2E manage-uxo workflow. Edit an existing UXO (`--edit`, default) or add a new one (`--add`), applying the canonical writing recipe with an annotated preview + confirm gate.
---

# p2e-manage-uxo

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-manage-uxo.md`
- `workflows/p2e-uxo-recipe.md`

Hard rules:
- Your job is to edit or add a single UXO's `title`, `description`, `objectives[]`, `tier`, or phase — not to edit stories, not to run bootstrap, and not to detect drift.
- ALWAYS show an annotated preview and require explicit accept before any write. The preview must render `title`, `tier`, `description`, and `objectives[]` with provenance annotations (`populated` / `empty` / `derived-from-source` / `derived-from-stories` / `derived-from-brainstorming` / `steered-by-user`).
- Apply the canonical recipe: objectives[] first → MECE-audit within the UXO → description as succinct articulation. The description's em-dash enumeration must match the `objectives[]` 1:1.
- When the UXO has stories, render the MECE audit section with a story-landing coverage table; orphan and multi-landed stories are flagged as MECE violations.
- **Flag gap** confirm action captures a scope gap per the recipe — as a thin-DRAFT story under this UXO, a new UXO proposal, or a leave-as-note. Never silently add the gap to the current UXO's `objectives[]` (recipe forbids dilution).
- **Brainstorming escalation**: if after the first thicken pass the staged `objectives[]` has fewer than 3 bullets AND the UXO's title + stories + sibling UXOs don't supply enough evidence, invoke the Codex-native brainstorming primitive once (equivalent to `superpowers:brainstorming` on Claude). Batch 2–4 concrete questions in a single turn, fold answers back, annotate resulting bullets `derived-from-brainstorming`, and re-render the preview. A single round per flow. Empty cells are preferred over filler.
- NEVER silently mutate the UXO or its stories without the preview gate.
- If MCP auth, UXO lookup, or required source context is unavailable, stop and report the concrete blocker briefly. Do not switch into general debugging unless the user asks for debugging.

Write form:
- Use `mcp__p2e__uxos` with the `items:[{...}]` call form on both `op=update` (for `--edit`) and `op=create` (for `--add`). This is the verified shape that round-trips `objectives` as a native array across Opus 4.7 and Sonnet 4.6.

Execute the shared manage-uxo workflow exactly.
