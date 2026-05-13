# Promote-or-not menu + pedagogy

A rich-Markdown doc is Markdown carrying structure (~50% of the value: front-matter, headings, prose, simple lists/tables, code fences — fast and token-cheap) plus HTML blocks carrying fidelity (the rest: anything a visual structure renders faster than prose). This file tells you *when to promote* and *which component* to reach for. The agent picks; the components (in `components.md`, CSS in `template.md`) render.

## Default to Markdown. Promote only when fidelity demands it.

| Content | Stays Markdown | Promote to an HTML block when… | Component |
|---|---|---|---|
| Title, metadata | always (front-matter + a `status:` token on the title line) | never | — |
| Body prose, RRR/background, narrative | always | never — prose is prose | — |
| Simple list (≤~8 items, read top-to-bottom) | yes | the reader *scans* the set rather than reading it; bold-label cells in an auto-fit grid read faster | Anatomy / strategy grid |
| Simple comparison (2–3 alternatives) | yes — plain Markdown table | the comparison is the doc's centerpiece and needs color-coded Pros/Cons, a highlighted chosen row, or verdict pills | Comparison table |
| Code / commands / config | yes — ``` fence with a lang tag | you want the dark inline style woven into an explainer (rare) | Code block |
| The doc's gist | a 3-bullet bold-lead list works | it's the top of a spec/design/ADR — pair the TL;DR card with a one-glance inline-SVG diagram (highest-leverage block in the doc) | TL;DR card + Inline-SVG diagram |
| A choice the reader must make | a `### Decision N` heading + option bullets, for one low-stakes decision | there are ≥2 decisions, or it's consequential and deserves isolation from the analysis | Decision card (open → RESOLVED) |
| An argument built from premises | numbered list | the doc concludes *from* the chain and you want citable P1/P2/… markers | Premise list |
| A thesis / definition / risk / boundary | blockquote | the reader must not miss it — color-code it (info=sky, warn=amber, good=emerald) | Callout |
| A concept with 2–4 moving parts | `### Piece N` sub-sections | the parts should be seen side by side at a glance | Three-pieces grid |
| An implementation plan | numbered list with inline cost | ≥4 steps each with a cost line, and you want the cost de-emphasized + a summed total | Steps list + total card |
| Out-of-scope items | bullet list | you want the lighter "parking lot" styling | Deferred bullets |
| Architecture / flow / state / sequence figure | — (Markdown can't draw) | always | Inline-SVG diagram (never Mermaid — needs JS) |
| Complex mechanism explainer | — | always — open with one inline-SVG flow diagram, then 3–4 annotated code blocks (each in a `callout-info` with a kicker), then a closing `callout-warn` for gotchas. Optimized for "read once, then use" | Diagram + Code blocks + Callouts |

## Section-shape templates

The recurring spec/design/ADR section order — `template.md` ships this scaffold:

1. **5-minute brief** — TL;DR card + one-glance inline-SVG diagram. Above everything. (HTML block.)
2. **Decisions you need to make** (or "Decisions resolved") — open or RESOLVED decision cards if ≥2, otherwise a `###`-heading + bullets in Markdown.
3. **Problem & context** — prose in Markdown; optional thesis `callout-info`; promote the premise chain to a `premise-list` if it's an argument; optional `callout-warn` for honest costs.
4. **Approaches considered** — plain Markdown table for 2–3; promote to the rich comparison table if it's the centerpiece.
5. **Recommended approach** — `three-pieces` grid for the moving parts; supporting `###` sub-sections in Markdown, each promoted (anatomy grid / callout / code block) only when a visual carries it better.
6. **Implementation plan** — numbered Markdown list, or the styled `steps` + `total-card` block for ≥4 costed steps.
7. **Deferred / out of scope** — Markdown bullets, or the `deferred-list` block.

## Cognitive-amortization rules of thumb

- If the same fact is buried in three paragraphs, surface it once — as a callout or an anatomy-grid cell.
- If a paragraph compares two alternatives, a table is faster — Markdown table first, rich table only if it's the centerpiece.
- If a paragraph lists 3+ things the reader will scan, make it a list with bold lead-ins (Markdown), or a grid if they're scanned rather than read.
- If a paragraph is doing a job a diagram could do in one glance, replace it with an inline SVG.
- If the reader has to scroll past ~1.5 screens of prose before reaching the open decisions, the decisions are too far down.
- Don't promote for decoration. An HTML block earns its place by rendering the content faster than Markdown would — not by looking fancier.

## What the agent does NOT do

- Never re-derive colors, fonts, spacing, or component CSS — they're in `template.md`'s `<style>` block (and `template.html`'s for the `/p2e-html` path).
- Never reach for Tailwind, Bootstrap, or any CSS framework — the bundled hand-written CSS is the design system.
- Never add JS, `position: sticky`/`fixed`, `<a href="#…">` anchor nav, or `<details>` collapsibles inside any HTML block — these break the doc-reviewer sandbox per `feedback_html_doc_no_interactive`.
- Never add an in-doc TOC or sections sidebar — doc-reviewer's rail renders the outline.
- Never wrap an HTML block without `<div class="rich-doc" id="…">` — the scoped CSS won't apply and doc-reviewer can't anchor comments.
