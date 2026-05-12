# AGENTS.md — p2e-plugin

This file is the orientation any AI agent (Codex CLI, Cursor agent, generic AGENTS.md-aware tool) reads on first contact with the repo. Authoritative project conventions live in `CLAUDE.md` (project-level) and the per-platform reference in `reference/`. This file is the short version.

## What this repo is

A multi-platform plugin that adds P2E story-map workflows to Claude Code, Codex, and Cursor — all backed by the shared P2E MCP server.

## How to work in this repo

1. **Behavior lives in `workflows/`.** Per-platform wrappers in `commands/`, `skills/`, and `.cursor/skills/` are thin and point at the workflow.
2. **MCP is authoritative.** Domain reads/writes go through `mcp__p2e__*` tools.
3. **Cross-platform compliance is mandatory.** Every workflow ships as four files (one shared workflow + one wrapper per platform). See `reference/cross-platform-pattern.md`.
4. **Bind first.** If `.p2e/project.json` is missing, run `/p2e-bind` before any project-scoped MCP operation.

## Where to look

- `README.md` — install + command table
- `CLAUDE.md` — full project conventions (read this if you'll be writing code)
- `reference/` — distilled platform requirements (Claude / Codex / Cursor) + the cross-platform pattern
- `workflows/` — the canonical behavior for every command/skill
- `commands/` (Claude), `skills/` (Codex), `.cursor/skills/` (Cursor) — thin wrappers

## Available workflows

`p2e-bootstrap`, `p2e-add-story`, `p2e-update-story`, `p2e-work-on-next`, `p2e-sync-labels`, `p2e-sync`, `p2e-bind`, `p2e-manage-uxo`, `p2e-archaeology`, `p2e-fix`. Each is invocable as `/<name>` on Claude and Cursor and as `<name>` (or via the `p2e` router skill) on Codex.
