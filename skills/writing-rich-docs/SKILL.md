---
name: writing-rich-docs
description: Use when producing or modifying a human-review doc (spec, design, adr-*, retro, postmortem). Produces Markdown with embedded HTML blocks — Markdown carries the structure/prose, HTML blocks carry the high-fidelity content (decision cards, comparison matrices, anatomy/three-pieces grids, callouts, inline-SVG diagrams). Ships a bundled template + component snippets + a promote-or-not menu so the agent picks pedagogy and never spends thinking tokens on visual implementation. Required for any human-review doc under docs/feat-*/.
---

# writing-rich-docs

Default output is **Markdown with embedded HTML blocks**: Markdown gets you ~50% there (front-matter, headings, prose, simple lists/tables, code fences — fast and token-cheap); HTML blocks carry the rest (anything where a layout, color, grid, status pill, or inline SVG communicates faster than prose, plus all diagrams). Neither extreme is wrong — a config-only ADR can be all Markdown, an architecture explainer can be mostly HTML — but the blend is the default because it's the most productive mix.

`/p2e-html` is the escape hatch for a pure-HTML artifact; `/p2e-md` for plain Markdown with no blocks.

Read first:
- `workflows/p2e-rich-docs.md` — the full workflow contract (the MD+HTML-block model, output format by trigger, the rich-Markdown production steps, MD→HTML conversion, doc-reviewer compatibility, the quality bar).
- `skills/writing-rich-docs/references/template.md` — the canonical rich-Markdown skeleton: YAML front-matter, the `<style>` preamble (theme tokens + every component's CSS, scoped under `.rich-doc`), and a section scaffold with `<!-- promote-if … -->` hints showing where HTML blocks go.
- `skills/writing-rich-docs/references/components.md` — copy-paste snippets for every component, each paired with its Markdown-native alternative and a "promote when" trigger (TL;DR card, decision card open + RESOLVED, callouts, premise list, comparison table, three-pieces grid, anatomy grid, steps list + total, code block, deferred bullets, inline-SVG diagram).
- `skills/writing-rich-docs/references/strategies.md` — the promote-or-not decision menu (which content stays Markdown vs. gets an HTML block) plus section-shape templates and cognitive-amortization rules.
- `skills/writing-rich-docs/references/template.html` — the pure-HTML skeleton, used only by the `/p2e-html` path. Same component classes as `template.md`, wrapped in a full single-file HTML shell.

Hard rules:
- The agent's job is content + which-regions-to-promote + strategy choice. NEVER re-derive colors, fonts, spacing, or component CSS — they're in `template.md`'s `<style>` block (and `template.html`'s for the pure-HTML path). NEVER reach for Tailwind, Bootstrap, or any CSS framework.
- Default to Markdown. Promote a region to an HTML block only when a visual structure carries it better — never wrap trivial prose in HTML for decoration.
- Every HTML block lives inside `<div class="rich-doc" id="…">…</div>` with a stable `id` so the scoped `<style>` applies and doc-reviewer can anchor comments. Keep `##`/`###` heading text stable for the same reason.
- Diagrams are always HTML blocks: inline SVG only. NEVER Mermaid (needs JS), never an image file.
- Inside any HTML block (and any pure-HTML doc): no `<script>`, no `<details>`/`<summary>` for content discovery, no `<a href="#…">` anchor nav, no `position: sticky`/`fixed`, no in-doc TOC. doc-reviewer's rail handles the outline. Single linear scroll. (Memory: `feedback_html_doc_no_interactive`.)
- YAML front-matter with `title`, `hash`, `status` (default `DRAFT`), `date`, `owner` on any doc under `docs/feat-*/`. doc-reviewer renders mixed Markdown + HTML and anchors comments to both — the blend carries no review penalty.
- When the user asks to address review comments on a doc, invoke `/doc-reviewer-review`. Never self-resolve threads.
