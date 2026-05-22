---
name: p2e-verify-story
description: Cursor entrypoint for the P2E verify-story workflow. Reproduces a P2E story's acceptance criteria against the running app, captures visible-pixel evidence, and outputs a self-contained rich-HTML UAT report.
---

# p2e-verify-story

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-verify-story.md`

Hard rules:
- Your job is to verify ACs and produce a UAT report, not to fix failures. A failing AC is a deliverable, not a trigger to start debugging or patching.
- ALWAYS present the parsed story (title + RRR + ordered ACs + out-of-scope) back to the user and require an explicit go-ahead before driving any browser.
- Visible pixels over JSON probes for any UI AC. Every UI verdict must rest on a screenshot or visually-confirmable artifact.
- The report must be a single self-contained `.html` file — no external CDN, no external script/stylesheet refs, all images by relative path.
- Bind first. If `.p2e/project.json` is missing in the target repo, stop and direct the user to `/p2e-bind` before any project-scoped MCP operation.
- Never trust "the server started" output alone. Verify the actually-bound port via `lsof` before driving the browser — a port-clash with another project's dev server routes requests to stale code.
- If MCP auth, story lookup, or a required browser-driver MCP is unavailable, stop and report the concrete blocker briefly. Do not switch into general debugging unless the user asks for debugging.

Execute the shared workflow exactly.

## Cursor-specific notes

Cursor has no `AskUserQuestion` primitive. For the Phase 1 preview-and-confirm gate, batch the four options (`Proceed with verification`, `Adjust ACs`, `Change artifacts dir`, `Abort`) into a single chat message and parse the user's reply inline. Bundled resources (references, scripts, assets) live in `skills/p2e-verify-story/` — same paths the workflow body cites. Cross-platform mirrors: `commands/p2e-verify-story.md` (Claude), `skills/p2e-verify-story/SKILL.md` (Codex).
