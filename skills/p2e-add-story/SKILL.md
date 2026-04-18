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
- At add time, set `sizing: M` annotated `defaulted`. Do NOT run any sizing heuristic — heuristic inference only runs on `/p2e-update-story` thicken, per `workflows/p2e-sizing-rubric.md`.
- ALWAYS show a preview and ask for review or confirmation before any write. The preview must include the `sizing` row, and the confirm step must let the user override it before the write.
- NEVER silently create the story or issue without that preview gate.
- If MCP auth or project lookup fails, stop and report the concrete blocker briefly. Do not switch into general debugging unless the user asks for debugging.

Execute the shared add-story workflow exactly.
