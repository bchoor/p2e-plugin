---
name: p2e-verify-story
description: Cursor entrypoint for the P2E verify-story workflow. Reproduces a story's ACs against the running app, records per-AC verdicts and screenshot evidence in the tracker, and optionally produces a rich-HTML UAT report.
---

# p2e-verify-story

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-verify-story.md`

Hard rules:
- Your job is to verify ACs and record verdicts with evidence — not to fix failures. A failing AC is a deliverable, not a trigger to start debugging or patching.
- In standalone mode: ALWAYS present the parsed story (title + RRR + ordered ACs + out-of-scope) back to the user and require an explicit go-ahead before driving any browser. In gate-engine mode (`--gate-engine`): skip the confirm step.
- Visible pixels over JSON probes for any UI AC. Every UI verdict must rest on a screenshot or visually-confirmable artifact.
- Record each verdict in the tracker via `mcp__p2e__criteria op=verdict items=[{"id":"<ac-cuid>","verdict":"PASS|FAIL|BLOCKED","note":"<evidence ref>"}]` — this IS a story mutation and is required.
- Upload each screenshot using the TOKEN-CARRY pattern: (1) call `mcp__p2e__story_assets op=upload_url`, (2) Write the full JSON response to a temp file verbatim, (3) run `skills/p2e-verify-story/scripts/upload-asset.sh <ticket.json> <local-file> [content_type]` — the helper reads `client_token`/`upload_url`/`pathname` from the file via a JSON parser and executes the PUT. See `## Screenshot evidence upload → TOKEN-CARRY DISCIPLINE` in `workflows/p2e-policy.md` for the canonical recipe. Never inline the HMAC-signed token into a shell command. Do NOT use base64 `op=upload` (being removed server-side, B-01-L15).
- The HTML report is optional in gate-engine mode; in standalone mode it is produced unless `--no-report` is passed.
- Bind first. If `.p2e/project.json` is missing in the target repo, stop and direct the user to `/p2e-bind` before any project-scoped MCP operation.
- Never trust "the server started" output alone. Verify the actually-bound port via `lsof` before driving the browser — a port-clash with another project's dev server routes requests to stale code.
- If MCP auth, story lookup, or a required browser-driver MCP is unavailable, stop and report the concrete blocker briefly. Do not switch into general debugging unless the user asks for debugging.

Execute the shared workflow exactly.

## Cursor-specific notes

Cursor has no `AskUserQuestion` primitive. For the Phase 1 preview-and-confirm gate (standalone mode only), batch the four options (`Proceed with verification`, `Adjust ACs`, `Change artifacts dir`, `Abort`) into a single chat message and parse the user's reply inline. Bundled resources (references, scripts, assets) live in `skills/p2e-verify-story/` — same paths the workflow body cites. Cross-platform mirrors: `commands/p2e-verify-story.md` (Claude), `skills/p2e-verify-story/SKILL.md` (Codex).
