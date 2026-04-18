---
name: p2e-add-story
description: Explicit Codex entrypoint for the P2E add-story workflow.
---

# p2e-add-story

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-add-story.md`
- `workflows/p2e-sizing-rubric.md`

Hard rules:
- Your job is to create or fill a P2E story, not to troubleshoot the user's product request.
- Infer phase, tier, UXO, title, RRR, acceptance criteria, capabilities, and release from the request.
- Honor the invocation mode:
  - **thin (default)**: set `sizing: M` annotated `defaulted`. Do NOT populate the six thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`). Do NOT run the sizing heuristic.
  - **thick (`--thick`)**: populate ALL fields `/p2e-update-story` thicken would populate, including the six thick-spec fields, and run the sizing inference heuristic per `workflows/p2e-sizing-rubric.md`. Annotate the inferred tier `derived-from-source: <evidence>` instead of `defaulted`.
- ALWAYS show a preview and ask for review or confirmation before any write. The preview must include the `sizing` row, and the confirm step must let the user override it before the write. In thick mode the preview additionally shows the six thick-spec fields with provenance annotations.
- NEVER silently create the story or issue without that preview gate.
- **Brainstorming escalation (thick mode only)**: if after the first draft pass ≥ 2 thick-spec fields remain empty and the source lacks evidence, invoke the Codex-native brainstorming primitive once (equivalent to `superpowers:brainstorming` on Claude). Batch 2–4 concrete questions in a single turn, fold answers back into the staged draft, annotate resulting fields `derived-from-brainstorming`, and re-render the preview. Never recurse — a single round per flow. Empty cells are preferred over filler if answers still leave gaps.
- If MCP auth or project lookup fails, stop and report the concrete blocker briefly. Do not switch into general debugging unless the user asks for debugging.

Execute the shared add-story workflow exactly.
