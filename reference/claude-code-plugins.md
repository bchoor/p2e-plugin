---
title: Claude Code plugin reference (distilled)
hash: ref-claude-code
status: living
date: 2026-05-10
owner: bchoor
source: https://code.claude.com/docs/en/plugins-reference
---

# Claude Code plugin reference

Distilled from the upstream plugin reference. Refresh when the upstream schema changes.

## Plugin layout

```
my-plugin/
├── .claude-plugin/
│   ├── plugin.json         # required
│   └── marketplace.json    # optional, for marketplace-published plugins
├── commands/               # slash commands (.md per command)
├── skills/                 # skills (each is its own dir with SKILL.md)
├── agents/                 # subagents (.md per agent)
├── hooks/hooks.json        # optional event handlers
├── .mcp.json               # optional MCP server config
└── assets/                 # images, icons
```

## `.claude-plugin/plugin.json`

Minimum:

```json
{
  "name": "kebab-case",
  "version": "0.1.0",
  "description": "One-line summary"
}
```

Common optional fields: `author` (object), `homepage`, `repository`, `license`, `keywords`.

## Commands (`commands/<name>.md`)

Each command is a single markdown file. Frontmatter:

```yaml
---
name: command-name
description: One-line summary shown in slash menu
argument-hint: <arg> [--flag]
---
```

Body is the prompt Claude executes when the user runs `/command-name`. Treat it as a thin wrapper that delegates to a shared workflow definition (see `reference/cross-platform-pattern.md`).

## Skills (`skills/<name>/SKILL.md`)

Each skill is a directory with at least `SKILL.md`. Frontmatter:

```yaml
---
name: skill-name
description: When this skill applies and what it does
---
```

Optional sibling files (`reference.md`, `scripts/`) are loaded on demand. Skills are discovered automatically and may be invoked by Claude based on context, or explicitly via the Skill tool.

## Agents (`agents/<name>.md`)

Subagent definitions. Frontmatter fields supported by plugin agents: `name`, `description`, `model`, `effort`, `maxTurns`, `tools`, `disallowedTools`, `skills`, `memory`, `background`, `isolation` (only `"worktree"` is valid). `hooks`, `mcpServers`, and `permissionMode` are NOT supported in plugin agents.

## Hooks (`hooks/hooks.json`)

JSON config keyed by event name. Common events: `SessionStart`, `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`. Hook types: `command`, `http`, `mcp_tool`, `prompt`, `agent`. Use `${CLAUDE_PLUGIN_ROOT}` to resolve plugin-rooted paths in commands.

## MCP servers (`.mcp.json`)

Standard MCP server config. Servers start automatically when the plugin is enabled. Use `${CLAUDE_PLUGIN_ROOT}` for paths.

## Discovery

- Slash commands: `/<name>` from chat
- Skills: auto-invoked by Claude or explicit via Skill tool
- Agents: appear in `/agents` and may be invoked by Claude or by name

## What this repo uses

- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- `commands/` (one slash command per workflow)
- `skills/` (codex-facing routing skills, also discoverable by Claude)
- `agents/` (`p2e-architect`, `p2e-staff-engineer`)
- `hooks/` (PreToolUse status gate, SessionStart project briefing)
- `.mcp.json` (P2E MCP)
