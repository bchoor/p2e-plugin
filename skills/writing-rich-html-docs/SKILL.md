---
name: writing-rich-html-docs
description: Use when producing or modifying a human-review doc (spec.html, design.html, adr-*.html, retro.html, postmortem.html). Provides an opinionated single-file HTML template, theme tokens, component library, and pedagogical-strategy menu so the agent picks pedagogy and never spends thinking tokens on visual implementation. Required for any HTML output under docs/feat-*/.
---

# writing-rich-html-docs

Read first:
- `workflows/p2e-rich-html-docs.md` — the full workflow contract (audience classification, HTML production, MD→HTML conversion, doc-reviewer compatibility, skill quality bar)
- `skills/writing-rich-html-docs/references/template.html` — the canonical single-file HTML skeleton (placeholders for title/status/date/owner/hash; section comments showing what each section should contain)
- `skills/writing-rich-html-docs/references/components.md` — copy-paste blocks for every named component (TL;DR card, decision card open + RESOLVED, callouts, premise list, comparison table, three-pieces grid, anatomy grid, steps list, code block, deferred bullets)
- `skills/writing-rich-html-docs/references/strategies.md` — pedagogical strategy menu mapping cognitive tasks to visual patterns; section-shape templates; cognitive-amortization rules of thumb

Hard rules:
- The agent's job is content + strategy choice. NEVER re-derive colors, fonts, spacing, or component CSS — these are in `template.html`'s `<style>` block. NEVER reach for Tailwind, Bootstrap, or any CSS framework.
- Doc must be a single self-contained `.html` file. Forbidden: `<script>` tags, `<details>` / `<summary>` for content discovery, `<a href="#...">` anchor nav, `position: sticky` / `position: fixed`, in-doc TOC. These break the doc-reviewer rail (memory: `feedback_html_doc_no_interactive`).
- Doc-reviewer's rail handles outline navigation — never duplicate it in-doc.
- Inline SVG for diagrams. NEVER Mermaid — Mermaid needs JS.
- Stable element IDs on each `<section>` and major `<h2>`/`<h3>` so doc-reviewer can anchor comments.
- Single linear scroll. Visual hierarchy via typography, color, layout grids, inline SVG.
- Default status is DRAFT (amber pill). Status updates flip the pill color via the existing CSS variants documented in `components.md`.
