# Workflow — writing rich HTML docs

This workflow is the source of truth for the `writing-rich-html-docs` skill and the `/p2e-html`, `/p2e-md`, `/p2e-md-to-html` commands.

## Audience classification

A doc-producing skill is invoked. Decide the output format:

1. If the user invoked `/p2e-html` in the same turn → produce HTML.
2. If the user invoked `/p2e-md` in the same turn → produce MD.
3. Otherwise consult the audience classification table in `~/.claude/CLAUDE.md`:
   - Targets named `spec.html`, `design.html`, `adr-*.html`, `retro.html`, `postmortem.html` → HTML.
   - Targets named `plan.md`, `README.md`, `CLAUDE.md`, test fixtures, hook configs → MD.
   - When a doc-producing skill resolves a default path like `docs/feat-X/spec.md` and the audience is human review, the workflow rewrites the target to `.html`.

## When producing HTML

1. Read `references/template.html` and use it as the structural skeleton — DO NOT modify the `<style>` block, the `<head>` `<link>`, or the `.wrap`/`.doc-header` shell.
2. Fill in the placeholders (`{{TITLE}}`, `{{TYPE}}`, `{{STATUS}}`, `{{DATE}}`, `{{OWNER}}`, `{{HASH}}`) from the doc's metadata. Default `{{STATUS}}` is `DRAFT` and the pill stays amber.
3. For each section in the template, pick the appropriate components from `references/components.md` and the strategies from `references/strategies.md`. The agent's job is content + strategy choice; the components handle rendering.
4. Inline SVG diagrams only. Never `<script>`, `<details>`, anchor-link nav, or sticky positioning. Refer to the doc-reviewer compatibility rules in `feedback_html_doc_no_interactive` memory.
5. Doc-reviewer's rail handles the outline — never add an in-doc TOC or sidebar.
6. Element IDs on each `<section>` and major `<h2>`/`<h3>` should be stable so doc-reviewer can anchor comments.

## When producing MD

Pass through to the calling skill's normal MD output. Apply the existing CLAUDE.md MD conventions (no hard-wrapped paragraphs; YAML front-matter for `docs/feat-*/` files).

## When converting MD → HTML (`/p2e-md-to-html`)

1. Read the target `.md` file.
2. Parse its YAML front-matter into the HTML `<meta>` slots.
3. Map each MD section to a section shape from `references/strategies.md`:
   - The first paragraph after the title becomes the TL;DR card body (split into 3 bullets if it doesn't already have them).
   - "Background" / "Context" / "Problem" → Problem & context section with premise-list extraction if there's a numbered list.
   - "Approaches" / "Alternatives considered" → Comparison table.
   - "Recommendation" / "Decision" → Recommended approach section with three-pieces grid if there are 3 sub-points, otherwise plain prose with anatomy grid.
   - "Implementation" / "Plan" → Steps list + total card.
   - "Out of scope" / "Deferred" / "Future work" → Deferred bullets.
4. Decisions surfaced in the source MD become decision cards. If the MD has explicit "open question" or "TBD" markers, surface them as open decision cards (amber).
5. Write the result to the same path with `.html` extension. Do NOT delete the source `.md` — leave it for diff/audit.
6. After writing, print a one-line summary of which sections were mapped and which were left as plain prose blocks.

## Doc-reviewer compatibility (mandatory for HTML output)

| Forbidden | Why |
|---|---|
| `<script>` tags (including Tailwind CDN, Mermaid CDN, any JS library) | Doc-reviewer iframe sandbox blocks JS |
| `<details>` / `<summary>` for content discovery | Sandbox doesn't pass clicks through reliably; defeats single linear scroll |
| `<a href="#section">` anchor nav | Sandbox doesn't pass scroll through |
| `position: sticky` or `position: fixed` | Breaks under sandbox scroll |
| In-doc TOC / sections sidebar / heading outline | Doc-reviewer's rail already renders this |

Visual hierarchy comes from typography, color, layout grids, and inline SVG. Single linear scroll. The reader scans top-to-bottom; the rail handles navigation.

## Skill quality bar

The agent's job is choosing pedagogy. Picking colors / fonts / spacing / component CSS is NOT the agent's job — those are provided.

| Agent does | Agent does NOT |
|---|---|
| Choose strategy from `references/strategies.md` | Pick colors, fonts, spacing |
| Write the prose | Re-derive callout/card/table CSS |
| Decide what's above the fold | Reach for Tailwind / Bootstrap |
| Adapt placeholders to content | Re-discover doc-reviewer constraints |
