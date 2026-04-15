# P2E Bootstrap Workflow

This workflow turns a free-form product description into a draft journey map: phases, tiers, and UXOs. It is a shared behavior spec, not a wrapper-specific command description.

## Purpose

- Produce the initial story-map skeleton for a new or lightly drafted P2E project.
- Preserve the current MCP-first workflow.
- Keep the language wrapper-agnostic: the wrapper should ask, render, and confirm, but not hard-code platform entrypoint details.

## Preconditions

- The target project must already exist in P2E.
- If the project already has a drafted journey, the workflow should prefer append semantics and ask before overwriting.
- The workflow may accept an inline description or a referenced document as the source.

## Workflow

1. Parse the source for product vision, primary persona, user journey, stage outcomes, quality ambitions, and constraints.
2. If the source is ambiguous, the wrapper should ask at most four clarifying questions. Prefer one combined question over multiple rounds.
3. Draft the journey metadata, phases, and UXOs in memory.
4. The wrapper should render a preview matrix that shows phases across tiers and the proposed UXOs in each cell.
5. The wrapper should ask the user what to do next: accept and write, adjust a phase, adjust a cell, dive deeper, regenerate, or abort.
6. If the user chooses to dive deeper, the wrapper may use brainstorming-style exploration to refine a phase or UXO before re-rendering.
7. On acceptance, write the structure through MCP in a single batch per entity type, preserving fail-fast behavior.

## Drafting rules

- Phases should be action-oriented and reflect the user journey.
- UXOs should be concrete objectives, not abstract benefits.
- Empty cells are allowed and are better than inventing filler.
- CORE rows should capture the baseline viable journey.
- ADVANCED and STRETCH rows should only appear when the source text supports them.

## Write behavior

- Create phases first, then UXOs.
- Reuse existing phases or UXOs when the project already has partial structure and the user chose append behavior.
- Surface the final matrix and the write payloads when running in dry-run mode.

