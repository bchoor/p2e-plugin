---
title: Rich HTML doc rendering — implementation plan
hash: rich-html-docs-v1
status: DRAFT
date: 2026-05-10
owner: bchoor
---

# Rich HTML doc rendering — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make human-review docs (spec, design, ADR, retro, postmortem) auto-render as rich single-file HTML through CLAUDE.md classification + a new opinionated p2e-plugin skill, with `/p2e-html`, `/p2e-md`, and `/p2e-md-to-html` slash commands as overrides and a manual MD-to-HTML conversion path.

**Architecture:** Three pieces, all behavior-routing through the highest-priority instruction layer (CLAUDE.md). (1) New "Doc Output Conventions" section in `~/.claude/CLAUDE.md` classifies each doc-write call by audience and steers the producing skill to HTML or MD. (2) New skill `writing-rich-html-docs` in the existing `bchoor/p2e-plugin` repo carries the opinionated template, theme tokens, component library, layout templates, and pedagogical-strategy menu — agent picks pedagogy, skill provides rendering. (3) Three thin commands in the same plugin (`/p2e-html`, `/p2e-md`, `/p2e-md-to-html`) override the auto-classification and convert legacy MD on demand.

**Tech Stack:** Plain HTML5 + hand-written CSS in a single `<style>` block (no JS, no Tailwind CDN — per the doc-reviewer-rail constraints in `feedback_html_doc_no_interactive`). Inter + JetBrains Mono via Google Fonts `<link>`. Inline SVG for diagrams. Plugin packaging follows the existing `bchoor/p2e-plugin` layout (skills/, commands/, workflows/).

---

## Scope and assumptions

This plan touches **three locations**:

1. **`~/.claude/CLAUDE.md`** — user-level instructions (one section replaced)
2. **`bchoor/p2e-plugin` repo** (https://github.com/bchoor/p2e-plugin, currently at v0.8.0) — new skill + 3 commands + 1 workflow file. Engineer must clone or already have a working tree.
3. **This `doc-reviewer` repo** — only the spec/design/plan colocation. No code touched.

**Out of scope for v1** (deferred — see design.html "Deferred / out of scope"):
- Cursor and Opencode adapters. The plan delivers Claude Code + Codex parity (the existing p2e-plugin pattern). Other-tool wrappers ship as a follow-up.
- Component library extraction to a shared `spec-ui.css`. Tracked as a P2E story per the design (label: `html-docs`).

**Reference artifact:** `/Users/bchoor/Downloads/projects/doc-reviewer/docs/feat-rich-html-docs/design.html` is the canonical worked example. The skill's `references/template.html` is extracted directly from it — see Task 4.

---

## File structure

| File | Action | Responsibility |
|---|---|---|
| `~/.claude/CLAUDE.md` | Modify | Replace "Markdown Conventions" section with "Doc Output Conventions" |
| `<p2e-plugin>/skills/writing-rich-html-docs/SKILL.md` | Create | Skill entry point — frontmatter + brief instructions, points to workflow + references |
| `<p2e-plugin>/skills/writing-rich-html-docs/references/template.html` | Create | Canonical single-file HTML template, extracted from design.html |
| `<p2e-plugin>/skills/writing-rich-html-docs/references/components.md` | Create | Copy-paste blocks: callouts, decision-cards, premise-list, anatomy-grid, three-pieces, comparison-table, code-block, total-card |
| `<p2e-plugin>/skills/writing-rich-html-docs/references/strategies.md` | Create | Pedagogical-strategy menu: which visual pattern for which cognitive task |
| `<p2e-plugin>/workflows/p2e-rich-html-docs.md` | Create | Shared workflow contract — referenced by skill + all three commands |
| `<p2e-plugin>/commands/p2e-html.md` | Create | Override: force next doc-producing skill to HTML |
| `<p2e-plugin>/commands/p2e-md.md` | Create | Override: force next doc-producing skill to MD |
| `<p2e-plugin>/commands/p2e-md-to-html.md` | Create | Convert: read a target `.md` file and rewrite as `.html` using the template |
| `<p2e-plugin>/plugin.json` | Modify | Bump version to 0.9.0 |
| `<p2e-plugin>/marketplace.json` (in `.claude-plugin/`) | Modify | Bump version to 0.9.0; mention new commands in description |
| `<p2e-plugin>/CHANGELOG.md` | Modify | Add 0.9.0 entry |
| `<p2e-plugin>/README.md` | Modify | Add the three new commands to the command list |

In what follows, `<p2e-plugin>` refers to the local checkout of the bchoor/p2e-plugin repo. **Engineer prerequisite:** clone it side-by-side with this repo before starting Task 2:

```bash
cd /Users/bchoor/Downloads/projects
git clone https://github.com/bchoor/p2e-plugin.git
cd p2e-plugin
git checkout -b feat/rich-html-docs-skill
```

---

## Task 1 — Update `~/.claude/CLAUDE.md`

**Files:**
- Modify: `~/.claude/CLAUDE.md` (the "## Markdown Conventions" section)

- [ ] **Step 1.1: Read current CLAUDE.md to locate the "Markdown Conventions" section**

```bash
grep -n "## Markdown Conventions" ~/.claude/CLAUDE.md
```

Expected: one line number returned (e.g. `42:## Markdown Conventions`). Note the line number; the section ends at the next `##` heading.

- [ ] **Step 1.2: Verify the section's exact current contents**

```bash
sed -n '/## Markdown Conventions/,/^## /p' ~/.claude/CLAUDE.md | head -n -1
```

Expected output (verbatim, current text):

```markdown
## Markdown Conventions
Apply when writing or editing any markdown file:
- **No hard-wrapped paragraphs.** One paragraph = one line. Hard wraps look fine in terminals but break paragraph flow in GitHub, Obsidian, VS Code preview, and other rendered markdown viewers. Lists, blockquotes, code blocks, and tables are unaffected.
- **Doc locations.** All design docs, specs, and plans live under `docs/feat-<name>/{spec,design,plan}.md` where `<name>` is a kebab-case feature or capability identifier. One folder per feature; multiple file types coexist (e.g. `docs/feat-procedure-registry/spec.md`, `docs/feat-procedure-registry/plan.md`, `docs/feat-procedure-registry/design.md`). Do NOT use `docs/superpowers/{specs,plans}/*.md`, top-level `docs/<topic>.md`, date-prefixed filenames, or any other ad-hoc layout for new docs — the feature-grouped layout supersedes them. This overrides default paths in skills like `superpowers:writing-plans`, `superpowers:brainstorming`, and the doc-reviewer skill.
- **Mandatory front-matter for spec/design/plan docs.** Any file under `docs/feat-*/` must start with YAML front-matter containing `title`, `hash`, `status`, `date`, `owner`. The `doc-reviewer-id` field is added on demand by the doc-reviewer skill or by user instruction — never preemptively.
```

If the current text differs, stop and reconcile with the user before continuing.

- [ ] **Step 1.3: Replace the section with the new "Doc Output Conventions" content**

Use the Edit tool (not sed) for safety. Replace the entire block above with:

```markdown
## Doc Output Conventions
Apply when writing or editing any doc that lives under `docs/feat-<name>/` or any other human-review surface. Supersedes the prior Markdown Conventions section.

**Audience determines the format.** The split is by *who reads the doc*, not by the file's extension or location:

| Doc type | Primary audience | Default format |
|---|---|---|
| `spec.html`, `design.html`, `adr-*.html`, `retro.html`, `postmortem.html` | Human review at decision time | **HTML** (rich single-file) |
| `plan.md`, test fixtures, hook configs | AI execution (with human spot-check) | **Markdown** |
| `README.md`, `CLAUDE.md` | Mixed | **Markdown** |

**For HTML (human-review) docs**, use the `bchoor/p2e-plugin` skill `writing-rich-html-docs`. The skill carries the opinionated template, theme tokens, component library, layout templates, and pedagogical-strategy menu. Agent picks pedagogy; skill provides rendering. Doc must be a single self-contained `.html` file: no JS, no Tailwind CDN, no `<details>`, no anchor-link nav, no sticky positioning (per `feedback_html_doc_no_interactive` memory) — single linear scroll, inline SVG diagrams, hand-written CSS in one `<style>` block.

**For MD (AI-execution) docs**, the prior conventions still apply: no hard-wrapped paragraphs (one paragraph = one line); mandatory YAML front-matter with `title`, `hash`, `status`, `date`, `owner` for any file under `docs/feat-*/`; the `doc-reviewer-id` field is added on demand. HTML docs carry the same metadata via `<meta name="doc-...">` tags in `<head>`.

**Doc locations.** All design docs, specs, and plans live under `docs/feat-<name>/{spec.html,design.html,plan.md}` (or `.md` if the audience is AI execution). One folder per feature; multiple file types coexist. Do NOT use `docs/superpowers/{specs,plans}/*.md`, top-level `docs/<topic>.md`, date-prefixed filenames, or any other ad-hoc layout — the feature-grouped layout supersedes them. This overrides default paths in skills like `superpowers:writing-plans`, `superpowers:brainstorming`, and the doc-reviewer skill.

**Override commands** (in `bchoor/p2e-plugin`):
- `/p2e-html` — force HTML on the next doc-producing skill in the same turn (use when the auto-classifier would have picked MD).
- `/p2e-md` — force MD (use for trivial config-only ADRs or when you want a fast MD-only spec).
- `/p2e-md-to-html` — convert an existing legacy MD spec to a rich HTML doc on demand. Pass the file path as the argument.
```

- [ ] **Step 1.4: Verify the edit**

```bash
grep -A2 "^## Doc Output Conventions" ~/.claude/CLAUDE.md | head -3
```

Expected: shows the new heading and the first two lines of the new section.

- [ ] **Step 1.5: Commit**

CLAUDE.md is not version-controlled inside any repo by default. If the user keeps `~/.claude/` in a personal dotfiles repo, commit there per their convention. Otherwise skip this step. Ask the user if unclear.

---

## Task 2 — Bootstrap the new skill in p2e-plugin

**Files:**
- Create directories: `<p2e-plugin>/skills/writing-rich-html-docs/`, `<p2e-plugin>/skills/writing-rich-html-docs/references/`

- [ ] **Step 2.1: Inspect the existing skill conventions in p2e-plugin**

Read one existing skill end-to-end so you copy the pattern:

```bash
cat <p2e-plugin>/skills/p2e-add-story/SKILL.md
cat <p2e-plugin>/commands/p2e-add-story.md
cat <p2e-plugin>/workflows/p2e-add-story.md
```

Expected: SKILL.md has frontmatter (`name`, `description`), then a short body that points to the workflow file. Command has frontmatter (`name`, `description`, `argument-hint`), then a short body that says "this command is a thin wrapper over `workflows/...`". Workflow files contain the actual logic.

This pattern is the contract for the new skill + commands.

- [ ] **Step 2.2: Create the skill directory tree**

```bash
cd <p2e-plugin>
mkdir -p skills/writing-rich-html-docs/references
ls skills/writing-rich-html-docs/
```

Expected: prints `references/`.

- [ ] **Step 2.3: Commit the empty scaffold**

Empty directories aren't tracked by git, so add a placeholder `.gitkeep` and commit:

```bash
touch skills/writing-rich-html-docs/.gitkeep skills/writing-rich-html-docs/references/.gitkeep
git add skills/writing-rich-html-docs/
git commit -m "feat(skill): scaffold writing-rich-html-docs directories"
```

---

## Task 3 — Write `references/template.html`

The canonical single-file HTML template. Extracted from `design.html` in the doc-reviewer repo, with the doc-specific content stripped down to placeholder section comments so it's reusable.

**Files:**
- Create: `<p2e-plugin>/skills/writing-rich-html-docs/references/template.html`

- [ ] **Step 3.1: Read the source design.html**

The source file is at `/Users/bchoor/Downloads/projects/doc-reviewer/docs/feat-rich-html-docs/design.html` (the worked example you produced during brainstorming). It contains the full canonical structure: `<head>` with meta + Google Fonts link + single `<style>` block, `<body>` with `.wrap`, `.doc-header`, then `<section>` blocks for 5-min brief, decisions, problem & context, approaches, recommendation, implementation, deferred, and footer.

- [ ] **Step 3.2: Create `references/template.html`**

Copy `design.html` into the new file as the starting point, then perform exactly these edits:

1. Replace `<title>Rich HTML doc rendering — design</title>` with `<title>{{TITLE}} — {{TYPE}}</title>` and update the four `<meta name="doc-*">` tags to placeholders (`{{TITLE}}`, `{{STATUS}}`, `{{DATE}}`, `{{OWNER}}`, `{{HASH}}`).
2. Replace the `<h1>Rich HTML doc rendering</h1>` and the `.doc-meta` paragraph with placeholders (`<h1>{{TITLE}}</h1>` and `<p class="doc-meta">{{TYPE}} · {{DATE}} · owner: {{OWNER}} · hash: {{HASH}}</p>`).
3. Strip every `<section>`'s content (between the section comment and `</section>`) down to a single placeholder comment showing what belongs there. Keep the section structure intact. Example:

```html
<!-- ────────────── 5-min brief ────────────── -->
<section>
  <h2>5-minute brief</h2>
  <p class="lead">Stop here if you only have 2 minutes.</p>
  <!-- TL;DR card with 3 emerald-arrow bullets covering: (1) the change, (2) the mechanism, (3) why it matters -->
  <!-- "Recommendation in one diagram" card with an inline SVG diagram (NEVER mermaid — must be inline SVG; no scripts) -->
</section>
```

4. Strip the `<!-- @doc-review-state ... @end-doc-review-state -->` block at the bottom (template should NOT carry the doc-reviewer state — that gets added per-doc when comments are made).
5. Keep the entire `<style>` block verbatim — it IS the design system.
6. Keep the `<link>` to Google Fonts verbatim.

- [ ] **Step 3.3: Verify the template parses as valid HTML**

```bash
python3 -c "
import html.parser, sys
class P(html.parser.HTMLParser): pass
P().feed(open('skills/writing-rich-html-docs/references/template.html').read())
print('OK')
"
```

Expected: `OK` printed (no parse exception).

- [ ] **Step 3.4: Verify the template carries no forbidden constructs**

```bash
python3 <<'EOF'
import re
src = open('skills/writing-rich-html-docs/references/template.html').read()
checks = {
  'no <script>': not re.search(r'<script', src),
  'no <details>': not re.search(r'<details', src),
  'no anchor #links': not re.search(r'href="#', src),
  'no position:sticky': 'position:sticky' not in src and 'position: sticky' not in src,
  'no Tailwind CDN': 'tailwindcss.com' not in src and '@tailwindcss' not in src,
  'has <style>': '<style>' in src,
  'has Inter font link': 'Inter' in src,
  'has placeholder slots': '{{TITLE}}' in src and '{{STATUS}}' in src,
}
for k, v in checks.items():
    print(f'{"PASS" if v else "FAIL"} — {k}')
assert all(checks.values()), 'template has constraint violations'
EOF
```

Expected: all 8 checks PASS.

- [ ] **Step 3.5: Commit**

```bash
git add skills/writing-rich-html-docs/references/template.html
git commit -m "feat(skill): add canonical HTML template extracted from design.html"
```

---

## Task 4 — Write `references/components.md`

Copy-paste blocks for every named component in the template. Each block is the literal HTML the agent can copy verbatim into a new doc.

**Files:**
- Create: `<p2e-plugin>/skills/writing-rich-html-docs/references/components.md`

- [ ] **Step 4.1: Create the file with the exact content below**

```markdown
# Component snippets

Copy-paste blocks for every component in the canonical template. The CSS for these is already in `template.html`'s `<style>` block — these snippets only show the HTML to drop into the body.

## Status pill (in header)

Variants: DRAFT (amber), ACCEPTED (sky), RESOLVED (emerald), DEPRECATED (slate).

DRAFT (default — uses the bare `.pill` class):

```html
<span class="pill"><span class="dot"></span>DRAFT</span>
```

For the other variants, override the pill colors inline (the `.pill` base class is amber by default):

```html
<!-- ACCEPTED -->
<span class="pill" style="background: var(--info-bg); color: var(--info); border-color: var(--info-border);">
  <span class="dot" style="background:#0284c7;"></span>ACCEPTED
</span>

<!-- RESOLVED -->
<span class="pill" style="background: var(--good-bg); color: var(--good); border-color: var(--good-border);">
  <span class="dot" style="background:#10b981;"></span>RESOLVED
</span>
```

## TL;DR card (in 5-min brief)

```html
<div class="card">
  <p class="label">TL;DR</p>
  <ul class="tldr-list">
    <li><span><strong>{Bullet 1 lead.</strong> {Detail prose.}</span></li>
    <li><span><strong>{Bullet 2 lead.</strong> {Detail prose.}</span></li>
    <li><span><strong>{Bullet 3 lead.</strong> {Detail prose.}</span></li>
  </ul>
</div>
```

## Diagram card (in 5-min brief)

```html
<div class="card" style="margin-top: 14px;">
  <p class="label">Recommendation in one diagram</p>
  <div class="diagram-wrap">
    <svg viewBox="0 0 720 360" role="img" aria-label="{accessible description}">
      <!-- inline SVG markup; never use Mermaid. See template.html for the marker/defs/styles pattern. -->
    </svg>
  </div>
</div>
```

## Decision card (open)

Use amber border to signal action-required.

```html
<div class="decision-card">
  <div class="head">
    <div class="num">{N}</div>
    <div style="flex:1; min-width:0;">
      <h3>{Decision title}</h3>
      <p class="desc">{One-sentence framing of what's being decided and why it matters.}</p>
      <div class="options">
        <div class="option">
          <p class="opt-title">Option A · {label} <span class="opt-rec">(recommended)</span></p>
          <p class="opt-note">{Pros/cons in one short paragraph.}</p>
        </div>
        <div class="option">
          <p class="opt-title">Option B · {label}</p>
          <p class="opt-note">{Pros/cons in one short paragraph.}</p>
        </div>
      </div>
    </div>
  </div>
</div>
```

## Decision card (RESOLVED)

After the decision is made, transform the open card with emerald accent + RESOLVED pill. Add `style="border-left-color: var(--good-border);"` to the outer `.decision-card`, change `.num` background to emerald, and replace the options with a one-paragraph recap that links to the review thread.

```html
<div class="decision-card" style="border-left-color: var(--good-border);">
  <div class="head">
    <div class="num" style="background: var(--good-bg); color: var(--good);">{N}</div>
    <div style="flex:1; min-width:0;">
      <div style="display:flex; align-items:center; gap:10px; flex-wrap:wrap;">
        <h3 style="margin:0;">{Decision title}</h3>
        <span class="pill" style="background: var(--good-bg); color: var(--good); border-color: var(--good-border);"><span class="dot" style="background:#10b981;"></span>RESOLVED</span>
      </div>
      <p class="desc" style="margin: 6px 0 0;">Closed via review (T{thread-id-prefix}): {one-sentence recap of the resolution + brief justification}.</p>
    </div>
  </div>
</div>
```

## Callouts

Four variants — use them consistently across docs:

| Variant | Use for |
|---|---|
| `callout-info` (sky) | Background facts, theses, definitions, etymologies |
| `callout-warn` (amber) | Risks, caveats, "agent does NOT" boundaries |
| `callout-good` (emerald) | Recommendations, resolutions, "agent does" patterns |

```html
<div class="callout callout-info">
  <p class="kicker">Thesis</p>
  <p>{One-paragraph callout body.}</p>
</div>
```

## Premise list

Numbered P1…P6 markers via CSS counters (already styled).

```html
<ol class="premise-list">
  <li>{Premise 1 — one sentence.}</li>
  <li>{Premise 2 — one sentence.}</li>
  <li>{...}</li>
</ol>
```

## Comparison table (approaches considered)

```html
<table>
  <thead>
    <tr>
      <th style="width: 22%;">Approach</th>
      <th class="col-pros" style="width: 26%;">Pros</th>
      <th class="col-cons" style="width: 26%;">Cons</th>
      <th style="width: 26%;">Concession / verdict</th>
    </tr>
  </thead>
  <tbody>
    <tr class="row-chosen">
      <td>
        <strong>{A. Title}</strong><br>
        <span style="font-size: 12px; color: var(--text-3);">{One-line description}</span><br>
        <span class="verdict-pill verdict-chosen">Chosen</span>
      </td>
      <td>{Pros prose}</td>
      <td>{Cons prose}</td>
      <td>{Concession / verdict prose}</td>
    </tr>
    <tr>
      <td>
        <strong>{B. Title}</strong><br>
        <span style="font-size: 12px; color: var(--text-3);">{One-line description}</span><br>
        <span class="verdict-pill verdict-rejected">Rejected</span>
      </td>
      <td>{Pros prose}</td>
      <td>{Cons prose}</td>
      <td>{Concession / verdict prose}</td>
    </tr>
  </tbody>
</table>
```

## Three-pieces grid (in Recommended approach)

```html
<div class="three-pieces">
  <div class="piece">
    <div class="badge">1</div>
    <h3>{Piece name}</h3>
    <p class="path">{file path or location}</p>
    <p>{One-paragraph description.}</p>
  </div>
  <div class="piece">…</div>
  <div class="piece">…</div>
</div>
```

## Anatomy / strategy grid

For "what makes the doc rich" or "skill quality bar" enumerations.

```html
<div class="anatomy-grid">
  <div><strong>{Element name}</strong> — {one-sentence what-it-is}.</div>
  <div><strong>{Element name}</strong> — {one-sentence what-it-is}.</div>
  <!-- 6-10 entries usually -->
</div>
```

## Implementation steps list

```html
<ol class="steps">
  <li>
    <div class="step-num">1</div>
    <div>
      <p class="step-title">{Step title}</p>
      <p class="step-desc">{What to do; what files; what to verify.}</p>
      <p class="step-cost">~{N} td · ~{M}K output tokens · ~{L} LoC equivalent</p>
    </div>
  </li>
  <!-- ... -->
</ol>

<div class="total-card">
  <span class="total-label">Total</span>
  <span>~<strong>{N} token-day</strong> (~${cost}, ~{tokens}, ~{LoC} LoC equivalent).</span>
</div>
```

## Code block

```html
<pre class="code-block"><span class="com"># comment line</span>
actual command or code line</pre>
```

## Deferred bullets

```html
<ul class="deferred-list">
  <li><span><strong>{Item title.}</strong> {Why deferred + tracking mechanism if any.}</span></li>
</ul>
```
```

- [ ] **Step 4.2: Verify the file is valid markdown**

```bash
python3 -c "import re; t = open('skills/writing-rich-html-docs/references/components.md').read(); assert t.startswith('# Component snippets'); assert '## Decision card (open)' in t; print('OK')"
```

Expected: `OK`.

- [ ] **Step 4.3: Commit**

```bash
git add skills/writing-rich-html-docs/references/components.md
git commit -m "feat(skill): add component snippet library"
```

---

## Task 5 — Write `references/strategies.md`

The pedagogical strategy menu. For each cognitive task the agent might face when writing a doc, name the visual strategy and point to the component.

**Files:**
- Create: `<p2e-plugin>/skills/writing-rich-html-docs/references/strategies.md`

- [ ] **Step 5.1: Create the file with this exact content**

```markdown
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
```

- [ ] **Step 5.2: Commit**

```bash
git add skills/writing-rich-html-docs/references/strategies.md
git commit -m "feat(skill): add pedagogical strategy menu"
```

---

## Task 6 — Write the workflow file

Shared workflow contract that the skill + all 3 commands point to. Mirrors the existing p2e pattern (skills/commands are thin pointers to workflows).

**Files:**
- Create: `<p2e-plugin>/workflows/p2e-rich-html-docs.md`

- [ ] **Step 6.1: Create the file**

```markdown
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
```

- [ ] **Step 6.2: Commit**

```bash
git add workflows/p2e-rich-html-docs.md
git commit -m "feat(workflow): add p2e-rich-html-docs shared workflow"
```

---

## Task 7 — Write the SKILL.md

The agent-facing entry point. Thin — points to the workflow and references.

**Files:**
- Create: `<p2e-plugin>/skills/writing-rich-html-docs/SKILL.md`

- [ ] **Step 7.1: Create the file**

```markdown
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
```

- [ ] **Step 7.2: Verify the SKILL.md frontmatter parses**

```bash
python3 <<'EOF'
import re
src = open('skills/writing-rich-html-docs/SKILL.md').read()
m = re.match(r'^---\n(.*?)\n---\n', src, re.DOTALL)
assert m, 'no frontmatter'
fm = m.group(1)
assert 'name: writing-rich-html-docs' in fm
assert 'description:' in fm
print('OK')
EOF
```

Expected: `OK`.

- [ ] **Step 7.3: Commit**

```bash
git add skills/writing-rich-html-docs/SKILL.md
git rm skills/writing-rich-html-docs/.gitkeep skills/writing-rich-html-docs/references/.gitkeep
git commit -m "feat(skill): add writing-rich-html-docs SKILL.md"
```

---

## Task 8 — Write the three slash commands

All three are thin wrappers over the workflow file.

**Files:**
- Create: `<p2e-plugin>/commands/p2e-html.md`
- Create: `<p2e-plugin>/commands/p2e-md.md`
- Create: `<p2e-plugin>/commands/p2e-md-to-html.md`

- [ ] **Step 8.1: Create `commands/p2e-html.md`**

```markdown
---
name: p2e-html
description: Force the next doc-producing skill in this turn to write rich HTML output (overrides the audience classification in CLAUDE.md). Use when you want HTML for a doc that would have defaulted to MD.
argument-hint: <followed by the doc-producing skill invocation, e.g. /p2e-html /superpowers:brainstorming redesign the comments rail>
---

# /p2e-html

This command is a thin override that loads HTML-output instructions into context for the next doc-producing skill in the same turn.

Follow the contract in `workflows/p2e-rich-html-docs.md` § "When producing HTML". Use the canonical template, components, and strategies from the `writing-rich-html-docs` skill.

The override applies only to the next doc write in this turn. After that, default audience-classification resumes.
```

- [ ] **Step 8.2: Create `commands/p2e-md.md`**

```markdown
---
name: p2e-md
description: Force the next doc-producing skill in this turn to write markdown output (overrides the audience classification in CLAUDE.md). Use for trivial config-only ADRs or when you want a fast MD-only spec.
argument-hint: <followed by the doc-producing skill invocation, e.g. /p2e-md /superpowers:brainstorming trivial config-only ADR>
---

# /p2e-md

This command is a thin override that loads MD-output instructions into context for the next doc-producing skill in the same turn.

Follow the contract in `workflows/p2e-rich-html-docs.md` § "When producing MD". The doc-producing skill's normal MD output is used; the existing CLAUDE.md MD conventions still apply.

The override applies only to the next doc write in this turn. After that, default audience-classification resumes.
```

- [ ] **Step 8.3: Create `commands/p2e-md-to-html.md`**

```markdown
---
name: p2e-md-to-html
description: Convert an existing markdown spec/design/ADR/retro to a rich HTML doc using the writing-rich-html-docs template. Reads the .md file, maps its sections to the canonical HTML shape, writes the result as .html alongside the source. Source .md is preserved for audit.
argument-hint: <path-to-md-file>, e.g. /p2e-md-to-html docs/feat-comments-rail-redesign/spec.md
---

# /p2e-md-to-html

This command converts an existing markdown doc into a rich single-file HTML doc using the canonical template + components.

Follow the contract in `workflows/p2e-rich-html-docs.md` § "When converting MD → HTML". Source `.md` is preserved; output written to the same path with `.html` extension.

After conversion, print a one-line summary of which sections were mapped and which were left as plain prose blocks (so the user can review and adjust if needed).
```

- [ ] **Step 8.4: Verify all three commands have valid frontmatter**

```bash
python3 <<'EOF'
import re, os
for cmd in ['p2e-html', 'p2e-md', 'p2e-md-to-html']:
    src = open(f'commands/{cmd}.md').read()
    m = re.match(r'^---\n(.*?)\n---\n', src, re.DOTALL)
    assert m, f'no frontmatter in {cmd}'
    fm = m.group(1)
    assert f'name: {cmd}' in fm, f'wrong name in {cmd}'
    assert 'description:' in fm
    assert 'argument-hint:' in fm
    print(f'OK — {cmd}')
EOF
```

Expected: 3 lines, one `OK — <name>` per command.

- [ ] **Step 8.5: Commit**

```bash
git add commands/p2e-html.md commands/p2e-md.md commands/p2e-md-to-html.md
git commit -m "feat(commands): add /p2e-html, /p2e-md, /p2e-md-to-html"
```

---

## Task 9 — Bump version + update CHANGELOG and README

**Files:**
- Modify: `<p2e-plugin>/plugin.json`
- Modify: `<p2e-plugin>/.claude-plugin/marketplace.json`
- Modify: `<p2e-plugin>/CHANGELOG.md`
- Modify: `<p2e-plugin>/README.md`

- [ ] **Step 9.1: Bump `plugin.json` version**

Current: `"version": "0.8.0"`. Update to `"version": "0.9.0"`. Use Edit tool, not sed.

- [ ] **Step 9.2: Bump `.claude-plugin/marketplace.json` version + description**

Update the matching `version` field to `"0.9.0"`. Update the `description` field for the `p2e` plugin entry to also mention the three new commands. Current description (read from file before editing):

```
"Adds /p2e-bootstrap, /p2e-add-story, /p2e-update-story, /p2e-work-on-next, /p2e-sync-labels, and the p2e-architect / p2e-staff-engineer agents. Backed by the P2E MCP server (configurable via P2E_MCP_URL)."
```

New description:

```
"Adds /p2e-bootstrap, /p2e-add-story, /p2e-update-story, /p2e-work-on-next, /p2e-sync-labels, /p2e-html, /p2e-md, /p2e-md-to-html, and the p2e-architect / p2e-staff-engineer agents. Includes the writing-rich-html-docs skill for opinionated rich-HTML doc rendering. Backed by the P2E MCP server (configurable via P2E_MCP_URL)."
```

- [ ] **Step 9.3: Add CHANGELOG entry**

Read the current CHANGELOG to see the entry format, then prepend:

```markdown
## 0.9.0 — 2026-05-10

### Added
- New skill `writing-rich-html-docs` — opinionated rich-HTML template + design system + pedagogical-strategy menu for human-review docs.
- New commands `/p2e-html` (force HTML output), `/p2e-md` (force MD output), `/p2e-md-to-html` (convert legacy MD spec to rich HTML).
- New shared workflow `workflows/p2e-rich-html-docs.md`.
```

- [ ] **Step 9.4: Update README**

Find the section listing existing commands. Add the three new commands at the end of that list with one-line descriptions:

```markdown
- `/p2e-html` — force the next doc-producing skill to write rich HTML
- `/p2e-md` — force the next doc-producing skill to write markdown
- `/p2e-md-to-html <file.md>` — convert a legacy MD spec to a rich HTML doc using the canonical template
```

- [ ] **Step 9.5: Commit**

```bash
git add plugin.json .claude-plugin/marketplace.json CHANGELOG.md README.md
git commit -m "chore(release): bump to 0.9.0 — rich HTML doc rendering"
```

---

## Task 10 — End-to-end test

Drive a real brainstorming session through the new skill on a tiny example feature, and verify the output meets the spec.

**Files:**
- Test scratch dir: `/tmp/p2e-rht-e2e-test/` (created during the test, removed after)

- [ ] **Step 10.1: Set up a fresh test workspace**

```bash
rm -rf /tmp/p2e-rht-e2e-test
mkdir -p /tmp/p2e-rht-e2e-test/docs
cd /tmp/p2e-rht-e2e-test
git init -q
echo "# test repo" > README.md
git add . && git commit -q -m "init"
```

- [ ] **Step 10.2: Run the brainstorming skill on a tiny example**

Open a fresh Claude Code session in `/tmp/p2e-rht-e2e-test` (so the new p2e-plugin commands are available, plus the updated `~/.claude/CLAUDE.md`). Prompt:

```
/superpowers:brainstorming  Add a `--quiet` flag to my CLI that suppresses the per-step progress lines but keeps errors.
```

Walk through the brainstorming flow normally (answer 2-3 clarifying questions; pick recommended options). When the skill writes the design doc, verify the output path is `docs/feat-cli-quiet-flag/design.html` (NOT `.md`), per the new audience classification in CLAUDE.md.

- [ ] **Step 10.3: Verify the produced design.html**

```bash
test -f docs/feat-cli-quiet-flag/design.html && echo "PASS — file exists at correct path"
python3 <<'EOF'
import re
src = open('docs/feat-cli-quiet-flag/design.html').read()
checks = {
  'no <script>': not re.search(r'<script', src),
  'no <details>': not re.search(r'<details', src),
  'no anchor #links': not re.search(r'href="#', src),
  'no position:sticky': 'position: sticky' not in src and 'position:sticky' not in src,
  'no Tailwind CDN': 'tailwindcss.com' not in src,
  'has <style> block': '<style>' in src,
  'has Inter font link': 'Inter' in src,
  'has TL;DR card': 'TL;DR' in src or 'tldr-list' in src,
  'has 5-min brief section': '5-minute brief' in src or '5-min brief' in src,
  'no Mermaid': 'mermaid' not in src.lower(),
  'has at least one inline svg': '<svg' in src,
}
for k, v in checks.items():
    print(f'{"PASS" if v else "FAIL"} — {k}')
assert all(checks.values()), 'output has constraint violations'
EOF
```

Expected: all 12 checks PASS (1 file-exists + 11 in the python block).

- [ ] **Step 10.4: Test `/p2e-md` override**

In the same session:

```
/p2e-md  /superpowers:brainstorming  Add a `--quiet` flag to my CLI that suppresses the per-step progress lines but keeps errors.
```

Verify the override produces `docs/feat-cli-quiet-flag/design.md` (NOT `.html`):

```bash
ls docs/feat-cli-quiet-flag/
```

Expected: shows both `design.html` (from step 10.3) and `design.md` (from this step).

- [ ] **Step 10.5: Test `/p2e-md-to-html` conversion**

Convert the just-created `design.md` to HTML:

```
/p2e-md-to-html  docs/feat-cli-quiet-flag/design.md
```

Verify it overwrites or creates `design.html` and preserves the `.md`:

```bash
ls docs/feat-cli-quiet-flag/
```

Expected: both files present. Read the regenerated `design.html` and confirm it has the canonical sections (5-min brief, problem & context, recommendation, etc.) — it should look structurally similar to the design.html in step 10.3.

- [ ] **Step 10.6: Cross-tool smoke test (Codex)**

The p2e-plugin already supports Codex. Open a Codex session in `/tmp/p2e-rht-e2e-test`. Run:

```
/p2e-html  Tell me what file you would create and what its first 5 lines would be.
```

Expected: Codex acknowledges the override is loaded, names a target path under `docs/feat-*/`, and shows the start of a doctype-html document with the Inter font link in the head. (Full file generation isn't required for the smoke test — just confirmation that the command surfaces in Codex and loads the override instructions.)

- [ ] **Step 10.7: Clean up the test workspace**

```bash
rm -rf /tmp/p2e-rht-e2e-test
```

- [ ] **Step 10.8: Tune the skill if needed**

If steps 10.3, 10.5, or 10.6 surfaced any issues (missing components, wrong shape, agent confused), edit the relevant reference file (template, components, or strategies) and re-run. Expect 0-1 iteration cycles.

Commit any tuning changes:

```bash
cd <p2e-plugin>
git add skills/writing-rich-html-docs/
git commit -m "fix(skill): tune rich-html template after E2E test"
```

---

## Task 11 — Push, PR, release

**Files:** none locally

- [ ] **Step 11.1: Push the branch and open a PR**

```bash
cd <p2e-plugin>
git push -u origin feat/rich-html-docs-skill
gh pr create \
  --title "feat: rich HTML doc rendering — writing-rich-html-docs skill + 3 commands" \
  --body "$(cat <<'EOF'
## Summary
- New skill `writing-rich-html-docs` with opinionated single-file HTML template, component library, and pedagogical-strategy menu.
- New commands `/p2e-html`, `/p2e-md`, `/p2e-md-to-html` — override audience classification + convert legacy MD on demand.
- New shared workflow `workflows/p2e-rich-html-docs.md`.
- Bump to v0.9.0.

Spec / design lives in the `doc-reviewer` repo at `docs/feat-rich-html-docs/{design.html,plan.md}`.

## Test plan
- [x] Validated SKILL.md frontmatter (Task 7.2)
- [x] Validated template.html constraints (no JS, no `<details>`, no anchors, no sticky) (Task 3.4)
- [x] Validated all 3 command frontmatters (Task 8.4)
- [x] E2E: ran `/superpowers:brainstorming` on a tiny example; output landed as `design.html` with all 12 constraint checks PASS (Task 10.3)
- [x] E2E: `/p2e-md` override produced `design.md` (Task 10.4)
- [x] E2E: `/p2e-md-to-html` round-tripped MD → HTML preserving sections (Task 10.5)
- [x] Codex smoke test: `/p2e-html` surfaces and loads override (Task 10.6)
EOF
)"
```

Expected: PR URL printed.

- [ ] **Step 11.2: After PR merges, tag and release**

Once the PR is reviewed and merged to main:

```bash
cd <p2e-plugin>
git checkout main
git pull
git tag -a v0.9.0 -m "v0.9.0 — rich HTML doc rendering"
git push origin v0.9.0
gh release create v0.9.0 --title "v0.9.0 — rich HTML doc rendering" --notes-from-tag
```

---

## Done criteria

- [ ] `~/.claude/CLAUDE.md` has the new "Doc Output Conventions" section; old "Markdown Conventions" is gone.
- [ ] `bchoor/p2e-plugin` v0.9.0 is released with the new skill + 3 commands + workflow.
- [ ] A fresh `/superpowers:brainstorming` invocation produces `design.html` (not `.md`) in `docs/feat-*/` with all the constraint checks passing.
- [ ] `/p2e-html`, `/p2e-md`, `/p2e-md-to-html` all surface in both Claude Code and Codex.

---

## Cost summary (from design.html)

| Task | td | Output tokens | LoC equivalent |
|---|---|---|---|
| 1 — Update CLAUDE.md | 0.03 | ~19K | ~300 |
| 2-7 — Skill + workflow + references | 0.15 | ~96K | ~1.5K |
| 8 — Three commands | 0.07 | ~45K | ~700 |
| 9 — Version bump + CHANGELOG + README | 0.02 | ~13K | ~200 |
| 10 — E2E test | 0.05 | ~32K | ~500 |
| 11 — PR + release | 0.03 | ~19K | ~300 |
| **Total** | **~0.35 td** | **~225K** | **~3.5K LoC** | (~$105)
