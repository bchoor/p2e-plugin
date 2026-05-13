---
name: writing-rich-docs
description: Cursor entrypoint for rich human-review docs (spec/design/ADR/retro/postmortem). Produces Markdown with embedded HTML blocks — Markdown for structure/prose, HTML blocks for high-fidelity content (decision cards, comparison matrices, grids, callouts, inline-SVG diagrams).
paths:
  - "docs/feat-*/**"
  - "docs/adrs/**"
---

# writing-rich-docs

Thin Cursor wrapper. The canonical skill — the MD+HTML-block model, the bundled template, the component snippets, the promote-or-not menu — lives at `skills/writing-rich-docs/SKILL.md` (with `references/template.md`, `references/components.md`, `references/strategies.md`, and `references/template.html` for the pure-HTML path) and the workflow contract at `workflows/p2e-rich-docs.md`. Read those and apply them exactly.

Default output: a `.md` file with YAML front-matter, the `<style>` preamble from `references/template.md`, prose/structure in Markdown, and HTML blocks (each wrapped in `<div class="rich-doc" id="…">`) wherever a visual structure carries the content better. Diagrams are inline SVG only — never Mermaid. Inside HTML blocks: no JS, no `<details>`, no anchor-link nav, no sticky/fixed positioning, no in-doc TOC. doc-reviewer renders mixed Markdown + HTML and anchors comments to both.

## Cross-platform note

The `/p2e-html`, `/p2e-md`, and `/p2e-md-to-html` override commands are Claude-Code-specific (they override the audience auto-classifier in `~/.claude/CLAUDE.md`) and have no Cursor or Codex equivalent — that asymmetry is intentional. This `writing-rich-docs` skill is the cross-platform doc-rendering surface; the Codex mirror is `skills/writing-rich-docs/SKILL.md`.
