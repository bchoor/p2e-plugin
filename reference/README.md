---
title: Reference docs for platform compliance
hash: ref-readme
status: living
date: 2026-08-27
owner: bchoor
---

# Reference

Distilled platform requirements that the p2e-plugin must stay compliant with. Since v0.12, the plugin ships a single **`p2e-mode`** skill — the historical 4-file workflow pattern in `cross-platform-pattern.md` is kept for schema reference only.

## Files

- [`claude-code-plugins.md`](./claude-code-plugins.md) — Claude Code plugin reference (commands, skills, agents, hooks, plugin.json schema). Source: <https://code.claude.com/docs/en/plugins-reference>.
- [`codex-plugins.md`](./codex-plugins.md) — Codex plugin reference (`.codex-plugin/plugin.json`, skills, MCP). Source: <https://developers.openai.com/codex/plugins/build>.
- [`cursor-skills-rules.md`](./cursor-skills-rules.md) — Cursor skills and rules (`.cursor/skills/`, `.cursor/rules/*.mdc`). Source: <https://cursor.com/docs/context/rules>.
- [`cross-platform-pattern.md`](./cross-platform-pattern.md) — **Historical** (pre-v0.12). The shared-workflow + thin-wrapper pattern. Superseded by the single `p2e-mode` skill in v0.12.

## When to refresh these

Refresh whenever a platform releases a breaking schema change (frontmatter fields, manifest shape, discovery paths). Capture the date and source URL in the file header. These are summaries — when in doubt, follow the linked upstream source.
