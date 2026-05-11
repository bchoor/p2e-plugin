# Pedagogical strategy menu

The agent picks the strategy; this file names it and points to the component to use. Goal: amortized comprehension — the doc is structured once so each reader scans it cheaply.

| Cognitive task | Visual strategy | Component to use |
|---|---|---|
| "Reader needs the gist in 2 minutes" | Above-the-fold 5-minute brief: 3-bullet TL;DR card + 1 inline-SVG diagram card | TL;DR card + Diagram card (in 5-min brief section) |
| "Reader needs to make a choice" | Surface decisions as their own section, isolated from analysis. One card per decision, options visible inline | Decision card (open). Move to RESOLVED variant once answered |
| "Compare 2-4 alternatives with trade-offs" | Comparison table with Pros / Cons / Concession columns. Highlight the chosen row with `.row-chosen` and a green verdict pill | Comparison table |
| "Build up an argument from premises" | Numbered premise list — each premise gets a P1/P2 marker via CSS counters. Lets the reader scan the chain without prose buildup | Premise list |
| "Show the architecture or flow" | Inline SVG diagram. Never Mermaid — Mermaid needs JS, which violates the no-JS constraint. Hand-write nodes/edges with `<rect>`, `<path>`, `<text>` | SVG inside Diagram card |
| "Sequence concrete tasks" | Numbered step list with title + description + cost-per-step | Implementation steps list |
| "Highlight a thesis, definition, or risk" | Color-coded callout (sky=info, amber=warn, emerald=good). One-paragraph max | Callouts |
| "Enumerate features without ranking" | Anatomy grid — 6-10 short bold-label + description cells, auto-fit grid | Anatomy / strategy grid |
| "Three pillars of the architecture" | Three-pieces grid — each with a numbered badge, title, file-path subtitle, paragraph | Three-pieces grid |
| "Items deferred / out-of-scope" | Deferred-list bullets at the end of the doc. Each item explains why deferred and (if applicable) the tracking mechanism (e.g. P2E story label) | Deferred bullets |
| "Compare N alternative approaches/designs side-by-side" | N-variant grid in a single HTML file. Each variant gets its own card; label each with the trade-off it's making. Use `display:grid; grid-template-columns: repeat(auto-fit, minmax(...))` so the layout scales 2/3/4 wide based on N. Per Thariq: "lay them out as a single HTML file in a grid so I can compare them side by side. Label each with the tradeoff it's making." | New: variant-grid (3-pieces-grid CSS works for N=3; for N=4-6 use the anatomy-grid CSS scaled up) |
| "Explain a complex mechanism" | Annotated-explainer pattern: open with one inline-SVG diagram of the flow, then 3-4 annotated code-snippet blocks (each with a kicker explaining what to look at), then a "Gotchas" callout-warn at the bottom. Optimized for "read once, then use" — the reader leaves with the diagram in their head. | New: combination of Diagram card + multiple Code blocks (each in its own callout-info with a kicker) + a closing callout-warn for gotchas |

## Section-shape templates

Standard section shapes that recur across most specs/designs/ADRs. Use them in this order:

1. **5-minute brief** — TL;DR card, then Diagram card. Above the fold, before anything else.
2. **Decisions you need to make** (or "Decisions resolved" if all answered) — open or resolved decision cards.
3. **Problem & context** — Thesis callout + prose + premise list + amortization paragraph.
4. **Approaches considered** — Comparison table.
5. **Recommended approach** — Three-pieces grid + supporting tables/grids/callouts.
6. **Implementation plan** — Numbered steps list + total card.
7. **Deferred / out of scope** — Deferred bullets, optionally with a "Removed during review" line.

Each section ends with `<hr class="…">` only when separating major narrative phases (rare). Default is to let the section margin do the work.

## Cognitive-amortization rules of thumb

- If the same fact is buried in three paragraphs, surface it as a callout or anatomy-grid cell.
- If a paragraph compares two alternatives, the comparison table is faster.
- If a paragraph lists 3+ items the reader will scan, make it a list with bold lead-ins.
- If a paragraph is doing a job that a diagram could do in one glance, replace it with an inline SVG.
- If the reader has to scroll past 1.5 screens of prose before reaching the open decisions, the decisions are too far down.

## What the agent does NOT do

- Never re-derive colors, fonts, spacing, or component CSS — they're in `template.html`'s `<style>` block.
- Never reach for Tailwind, Bootstrap, or any CSS framework — the template's hand-written CSS is the design system.
- Never add JS, sticky positioning, anchor-link nav, or `<details>` collapsibles — these break the doc-reviewer rail per `feedback_html_doc_no_interactive`.
- Never duplicate doc-reviewer's outline navigation in-doc — the rail handles it.
