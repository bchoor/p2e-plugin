---
title: Reference docs for cross-platform compliance
hash: ref-readme
status: living
date: 2026-05-10
owner: bchoor
---

# Reference

Distilled platform requirements that the p2e-plugin must stay compliant with. Every new command/skill in this repo MUST satisfy all three platforms (Claude Code, Codex, Cursor). The shared-workflow pattern in `reference/cross-platform-pattern.md` is the canonical way to do that.

## Files

- [`claude-code-plugins.md`](./claude-code-plugins.md) — Claude Code plugin reference (commands, skills, agents, hooks, plugin.json schema). Source: <https://code.claude.com/docs/en/plugins-reference>.
- [`codex-plugins.md`](./codex-plugins.md) — Codex plugin reference (`.codex-plugin/plugin.json`, skills, MCP). Source: <https://developers.openai.com/codex/plugins/build>.
- [`cursor-skills-rules.md`](./cursor-skills-rules.md) — Cursor skills and rules (`.cursor/skills/`, `.cursor/rules/*.mdc`). Source: <https://cursor.com/docs/context/rules>.
- [`cross-platform-pattern.md`](./cross-platform-pattern.md) — **The pattern**. How the same workflow ships as a Claude command + Codex skill + Cursor skill from one shared `workflows/<name>.md`.

## When to refresh these

Refresh whenever a platform releases a breaking schema change (frontmatter fields, manifest shape, discovery paths). Capture the date and source URL in the file header. These are summaries — when in doubt, follow the linked upstream source.
