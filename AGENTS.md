# AGENTS.md — p2e-plugin

This file is the orientation any AI agent (Codex CLI, Cursor agent, generic AGENTS.md-aware tool) reads on first contact with the repo.

## What this repo is

A multi-platform plugin that surfaces P2E story-map guidance on Claude Code, Codex, and Cursor — all backed by the shared P2E MCP server.

**v0.12+ ships a single skill: `p2e-mode`.** Legacy `/p2e-*` slash commands, granular workflow skills, and bundled subagents are removed.

## How to work in this repo

1. **Read `p2e-mode` at session start.** Lifecycle contract and assessment gates live in `skills/p2e-mode/SKILL.md` (Codex) and `.cursor/skills/p2e-mode/SKILL.md` (Cursor).
2. **MCP is authoritative.** Domain reads/writes go through `mcp__p2e__*` tools.
3. **Bind first.** If `.p2e/project.json` is missing in a target repo, create a binding before any project-scoped MCP operation.

## Where to look

- `README.md` — install + MCP configuration
- `CLAUDE.md` — contributor conventions for this repo
- `skills/p2e-mode/SKILL.md` — operating mode (entry point)
- `reference/` — platform schema summaries
