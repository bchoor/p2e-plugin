---
name: writing-rich-html-docs
description: Cursor entrypoint for opinionated rich-HTML doc rendering. Use when producing a human-review doc (spec/design/ADR/retro/postmortem) that should render as a single self-contained .html file.
---

# writing-rich-html-docs

This is a thin Cursor wrapper. The canonical skill — template, theme tokens, component library, layout templates, and the pedagogical-strategy menu — lives at `skills/writing-rich-html-docs/SKILL.md` (with `references/template.html`, `references/components.md`, `references/strategies.md`). Read that file and apply it exactly.

Produce a single self-contained `.html`: no JS, no Tailwind CDN, no `<details>`, no anchor-link nav, no sticky positioning — one linear scroll, inline SVG diagrams, hand-written CSS in one `<style>` block. Carry doc metadata via `<meta name="doc-...">` tags in `<head>`.

## Cross-platform note

The `/p2e-html`, `/p2e-md`, and `/p2e-md-to-html` override commands are Claude-Code-specific (they override the audience auto-classifier in `~/.claude/CLAUDE.md`) and have no Cursor or Codex equivalent — that asymmetry is intentional. This `writing-rich-html-docs` skill is the cross-platform doc-rendering surface; the Codex mirror is `skills/writing-rich-html-docs/SKILL.md`.
