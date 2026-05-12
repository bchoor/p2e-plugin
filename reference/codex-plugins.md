---
title: Codex plugin reference (distilled)
hash: ref-codex
status: living
date: 2026-05-10
owner: bchoor
source: https://developers.openai.com/codex/plugins/build
---

# Codex plugin reference

Distilled from the upstream Codex build-plugins guide. Refresh when upstream changes.

## Plugin layout

```
my-plugin/
├── .codex-plugin/
│   └── plugin.json         # required
├── skills/
│   └── <skill-name>/
│       └── SKILL.md
├── .app.json               # optional, app integrations
├── .mcp.json               # optional, MCP servers
├── hooks/hooks.json        # optional
└── assets/                 # icons, images
```

Codex does NOT support Claude-style slash commands, named-agent manifests, or `PreToolUse`-style hooks. The Codex-equivalent surface is **skills** (invoked by name in plain language or via explicit alias).

## `.codex-plugin/plugin.json`

Required:

```json
{
  "name": "kebab-case",
  "version": "0.1.0",
  "description": "One-line summary"
}
```

Component pointers (paths relative to plugin root, must start with `./`):

- `skills`: e.g. `"./skills/"`
- `mcpServers`: e.g. `"./.mcp.json"`
- `apps`: e.g. `"./.app.json"`
- `hooks`: defaults to `./hooks/hooks.json`

Publisher metadata (optional): `author`, `homepage`, `repository`, `license`, `keywords`.

Interface metadata (optional, controls install surface):

- `displayName`, `shortDescription`, `longDescription`
- `developerName`, `category` (e.g. `"Coding"`)
- `capabilities`: subset of `["Interactive", "Read", "Write"]`
- `websiteURL`, `privacyPolicyURL`, `termsOfServiceURL`
- `brandColor`, `composerIcon`, `logo`, `screenshots`
- `defaultPrompt`: array of starter prompts shown to users

## Skills

Each skill is `skills/<name>/SKILL.md` with YAML frontmatter:

```yaml
---
name: skill-identifier
description: When and what this skill does.
---
```

Body is the prompt Codex executes. The standard pattern in this repo: each skill is a thin wrapper that reads one or more files in `workflows/` and follows that workflow exactly.

## MCP servers

Same `.mcp.json` schema as Claude Code. The plugin in this repo shares `.mcp.json` between both adapters.

## Discovery and invocation

- Plain-language: a top-level router skill (e.g. `p2e`) catches free-form requests and selects the right workflow.
- Direct alias: per-workflow skills (e.g. `p2e-work-on-next`) act as named entrypoints.

## What this repo uses

- `.codex-plugin/plugin.json` with `skills`, `mcpServers`, `interface`
- `skills/p2e/SKILL.md` (top-level router)
- `skills/p2e-<workflow>/SKILL.md` (one alias skill per workflow)
- shared `.mcp.json`
- shared `workflows/` (single source of truth for behavior)
