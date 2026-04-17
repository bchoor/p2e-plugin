---
name: p2e-update-story
description: Explicit Codex entrypoint for the P2E update-story workflow.
---

# p2e-update-story

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-update-story.md`

Hard rules:
- Your job is to update specific fields of an existing P2E story, not to create a new one.
- ALWAYS show an annotated preview and require explicit accept before any write.
- NEVER silently mutate the story or its linked GitHub issue without that preview gate.
- If MCP auth or story lookup fails, stop and report the concrete blocker briefly. Do not switch into general debugging unless the user asks for debugging.

Execute the shared update-story workflow exactly.
