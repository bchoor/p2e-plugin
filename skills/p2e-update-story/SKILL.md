---
name: p2e-update-story
description: Explicit Codex entrypoint for the P2E update-story workflow.
---

# p2e-update-story

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-update-story.md`
- `workflows/p2e-sizing-rubric.md`

Hard rules:
- Your job is to update specific fields of an existing P2E story, not to create a new one.
- ALWAYS show an annotated preview and require explicit accept before any write. The preview must include the `sizing` row annotated with its provenance (`populated`, `derived-from-source: <evidence>`, `derived-from-brainstorming`, or `steered-by-user`).
- On the Thicken path, re-infer `sizing` from the staged title + capabilities + AC count + tags + `files_hint` length per `workflows/p2e-sizing-rubric.md`; cite the specific inputs in the annotation. On the Steer path or the confirm step's Adjust sizing action, the user's choice overrides unconditionally.
- **Brainstorming escalation (Thicken path only)**: if after the first thicken pass ≥ 2 of the six thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`) remain empty AND neither the provided source nor sibling stories under the same UXO supply enough evidence, invoke the Codex-native brainstorming primitive once (equivalent to `superpowers:brainstorming` on Claude). Batch 2–4 concrete questions in a single turn, fold answers back into the staged draft, annotate resulting fields `derived-from-brainstorming`, and re-render the preview. Never recurse — a single round per flow. Empty cells are preferred over filler.
- NEVER silently mutate the story or its linked GitHub issue without that preview gate.
- If MCP auth or story lookup fails, stop and report the concrete blocker briefly. Do not switch into general debugging unless the user asks for debugging.

Execute the shared update-story workflow exactly.
