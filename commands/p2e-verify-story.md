---
name: p2e-verify-story
description: Verify a P2E story by reproducing every AC against the running app, capturing visible-pixel evidence, and producing a self-contained rich-HTML UAT report.
argument-hint: <story_id-or-spec-path-or-issue-url> [--artifacts-dir=<path>] [--workspace-dir=<path>]
---

# /p2e-verify-story

This command is a thin wrapper over `workflows/p2e-policy.md` and `workflows/p2e-verify-story.md`.
Follow the shared workflow contract exactly.

## Claude-Code-specific notes

The preview-and-confirm gate (Phase 1) uses `AskUserQuestion` with the four options the workflow specifies (`Proceed with verification`, `Adjust ACs`, `Change artifacts dir`, `Abort`). The browser-driver MCP defaults to `mcp__chrome-devtools__*` (load via `ToolSearch query: "chrome-devtools" max_results: 30` in one bulk call rather than per-tool); fall back to `mcp__claude-in-chrome__*` only if chrome-devtools is not connected.
