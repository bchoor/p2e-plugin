# Workflow — writing rich docs (Markdown + embedded HTML blocks)

Source of truth for the `writing-rich-docs` skill and the Claude-Code-only `/p2e-html`, `/p2e-md`, `/p2e-md-to-html` override commands.

## The model: Markdown carries structure, HTML blocks carry fidelity

A human-review doc — `spec.md`, `design.md`, `adr-*.md`, `retro.md`, `postmortem.md` — is **Markdown with embedded HTML blocks**. The split is deliberate:

- **Markdown does the structural ~50%** — YAML front-matter, headings, prose, RRR/background, simple bulleted/numbered lists, simple 2–3-column tables, code fences, links, inline `code`. It's the cheapest way to produce text: fast, token-light, line-diffable, and doc-reviewer anchors comments to lines.
- **HTML blocks carry the high-fidelity rest** — anything where visual encoding (a layout, a color, a grid, a status pill, an SVG) communicates faster than prose: decision cards with status pills, color-coded comparison matrices, anatomy / three-pieces grids, callouts, premise ladders, before/after panels, step lists with per-step cost, and **all diagrams** (inline SVG — never Mermaid).

Neither extreme is forbidden. A config-only ADR can be 100% Markdown; an intricate architecture explainer can be 90% HTML blocks. The default is the blend: write the words in Markdown, and promote a region to an HTML block the moment a visual structure would carry it better. This mirrors how bundled-template skills work (e.g. `playground`): the skill ships the CSS + component snippets so the agent never re-derives visual implementation — it only chooses *what* to say and *which* regions to promote.

## Output format by trigger

| Trigger | Output |
|---|---|
| `/p2e-html` invoked this turn | **Pure HTML** — one self-contained `.html` from `skills/writing-rich-docs/references/template.html`. No Markdown wrapper. |
| `/p2e-md` invoked this turn | **Plain Markdown** — no `<style>` preamble, no HTML blocks. For trivial config-only ADRs or fast MD-only specs. |
| `/p2e-md-to-html <file.md>` | Convert a legacy/plain `.md` to pure HTML; source `.md` preserved. |
| default (no override) | **Rich Markdown** — `.md` with embedded HTML blocks per this workflow. |

Audience classification (from `~/.claude/CLAUDE.md`): human-review docs (`spec`, `design`, `adr-*`, `retro`, `postmortem`) default to **rich Markdown** with the `.md` extension. AI-execution docs (`plan.md`, test fixtures, hook configs) and mixed-audience docs (`README.md`, `CLAUDE.md`) stay plain Markdown. When a doc-producing skill resolves a default path like `docs/feat-X/spec.md`, keep the `.md` extension — the richness comes from embedded blocks, not the extension. The `/p2e-html` command is the escape hatch when a pure-HTML artifact is genuinely wanted.

## When producing rich Markdown (default)

1. **Front-matter.** YAML front-matter with `title`, `hash`, `status` (default `DRAFT`), `date`, `owner`. `doc-reviewer-id` is added on demand. These are the same fields the pure-HTML path carries via `<meta name="doc-…">` tags.
2. **Style preamble.** Immediately after the front-matter, paste the `<style>` block from `skills/writing-rich-docs/references/template.md` once. It carries the theme tokens + every component's CSS, scoped under `.rich-doc` so it does not leak into doc-reviewer's own Markdown styling. Do not edit it.
3. **Body in Markdown.** Headings, prose, RRR/background, simple lists, code fences, simple tables — all Markdown. Keep `##`/`###` heading text stable (Markdown heading IDs are derived from it) so doc-reviewer can anchor comments.
4. **Promote a region to an HTML block when** it matches one of the components in `skills/writing-rich-docs/references/components.md` and the Markdown-native rendering would lose fidelity — consult the promote-or-not table in `skills/writing-rich-docs/references/strategies.md`. Wrap each block in `<div class="rich-doc" id="…">…</div>` with a stable `id`. Drop in the component snippet; fill the content; do not re-derive CSS.
5. **Diagrams are always HTML blocks** — inline SVG only. Never Mermaid (needs JS); never an image file.
6. **Constraints inside HTML blocks** (doc-reviewer sandbox — same as the pure-HTML path): no `<script>`; no `<details>`/`<summary>` for content discovery; no `<a href="#…">` anchor nav; no `position: sticky`/`fixed`; no in-doc TOC / sections sidebar. Visual hierarchy comes from typography, color, grids, and SVG. Single linear scroll; doc-reviewer's rail handles the outline.

## When producing pure HTML (`/p2e-html`)

Read `skills/writing-rich-docs/references/template.html` and use it as the structural skeleton — do not modify its `<style>` block, the `<head>` `<link>`, or the `.wrap`/`.doc-header` shell. Fill the `{{TITLE}}/{{TYPE}}/{{STATUS}}/{{DATE}}/{{OWNER}}/{{HASH}}` placeholders from the doc's metadata (default `{{STATUS}}` is `DRAFT`, amber pill). Compose each section from the components in `references/components.md` and the pedagogy in `references/strategies.md`. Inline SVG only; obey the same doc-reviewer constraints as above. Stable element IDs on each `<section>` and major `<h2>`/`<h3>`.

## When producing plain Markdown (`/p2e-md`)

Pass through to the calling skill's normal Markdown output — no `<style>` preamble, no HTML blocks. The existing CLAUDE.md MD conventions apply: no hard-wrapped paragraphs (one paragraph = one line); YAML front-matter with `title`, `hash`, `status`, `date`, `owner` on any file under `docs/feat-*/`.

## When converting MD → HTML (`/p2e-md-to-html`)

1. Read the target `.md` file.
2. Parse its YAML front-matter into the HTML `<meta name="doc-…">` slots.
3. Map each MD section to a section shape from `skills/writing-rich-docs/references/strategies.md`:
   - The first paragraph after the title becomes the TL;DR card body (split into 3 bullets if it doesn't already have them).
   - "Background" / "Context" / "Problem" → Problem & context section, with premise-list extraction if there's a numbered list.
   - "Approaches" / "Alternatives considered" → Comparison table.
   - "Recommendation" / "Decision" → Recommended approach section, with the three-pieces grid if there are 3 sub-points, otherwise plain prose with an anatomy grid.
   - "Implementation" / "Plan" → Steps list + total card.
   - "Out of scope" / "Deferred" / "Future work" → Deferred bullets.
   - Any HTML blocks already in the source `.md` carry over as-is (rewrap from `<div class="rich-doc">` into the pure-HTML `.wrap` shell; the component classes are identical).
4. Decisions surfaced in the source become decision cards. Explicit "open question" / "TBD" markers become open (amber) decision cards.
5. Write the result to the same path with the `.html` extension. Do NOT delete the source `.md` — leave it for diff/audit.
6. After writing, print a one-line summary of which sections were mapped and which were left as plain prose blocks.

## Doc-reviewer compatibility

doc-reviewer renders **mixed Markdown + HTML** and anchors comments to both Markdown lines and HTML element `id`s — so the blend carries no review penalty over pure HTML or pure MD. The sandbox constraints still bind every HTML block (and every pure-HTML doc):

| Forbidden in any HTML block / HTML doc | Why |
|---|---|
| `<script>` tags (incl. Tailwind / Mermaid / any JS CDN) | doc-reviewer's iframe sandbox blocks JS |
| `<details>` / `<summary>` for content discovery | sandbox doesn't pass clicks reliably; defeats single linear scroll |
| `<a href="#section">` anchor nav | sandbox doesn't pass scroll through |
| `position: sticky` / `position: fixed` | breaks under sandbox scroll |
| in-doc TOC / sections sidebar / heading outline | doc-reviewer's rail already renders this |

When the user asks to address review comments on any doc (`.md` or `.html`, mixed or not), invoke `/doc-reviewer-review` — it handles the group → reply → unanchored-sweep workflow. Never self-resolve threads.

## Quality bar

| Agent does | Agent does NOT |
|---|---|
| Write the prose in Markdown | Re-derive callout / card / table / grid CSS — it's in `references/template.md` |
| Decide which regions to promote to HTML blocks | Reach for Tailwind / Bootstrap / any CSS framework |
| Choose the pedagogy from `references/strategies.md` | Pick colors, fonts, spacing |
| Keep heading text + block `id`s stable | Re-discover the doc-reviewer constraints |
| Default to Markdown; promote only when fidelity demands it | Wrap trivial prose in HTML for decoration |
