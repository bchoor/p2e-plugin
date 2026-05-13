# Component snippets

Each component below is an HTML block you drop into a rich-Markdown doc. The CSS is already in `template.md`'s `<style>` block (scoped under `.rich-doc`) — these snippets are just the markup. **Every block must be wrapped in `<div class="rich-doc" id="…">…</div>`** with a stable `id` (omitted in the snippets below for brevity — add it). The same classes work in the pure-HTML path (`template.html`), just without the `.rich-doc` wrapper since the whole `<body>` is the scope there.

For each component: **MD-native** = what to write if you *don't* promote; **promote when** = the trigger to use the HTML block instead.

---

## Status (front-matter + heading line)

- **MD-native:** `status:` in the YAML front-matter, plus a `status: **DRAFT**` token on the title line. Use this always — the status lives in metadata, not in a block.
- A status *pill* (the colored chip) only appears inside other HTML blocks (e.g. a RESOLVED decision card). Variants: DRAFT (amber, the bare `.pill`), ACCEPTED (sky), RESOLVED (emerald), DEPRECATED (slate).

```html
<span class="pill"><span class="dot"></span>DRAFT</span>

<!-- ACCEPTED -->
<span class="pill" style="background:var(--info-bg); color:var(--info); border-color:var(--info-border);"><span class="dot" style="background:#0284c7;"></span>ACCEPTED</span>

<!-- RESOLVED -->
<span class="pill" style="background:var(--good-bg); color:var(--good); border-color:var(--good-border);"><span class="dot" style="background:#10b981;"></span>RESOLVED</span>
```

---

## TL;DR card + one-glance diagram

- **MD-native:** a bold-lead bullet list — `- **The change.** …` ×3.
- **Promote when:** it's the top of a spec/design/ADR (it almost always is) — the card + an inline-SVG diagram beside it is the single highest-leverage block in the doc.

```html
<div class="card">
  <p class="label">TL;DR</p>
  <ul class="tldr-list">
    <li><span><strong>{The change.}</strong> {one clause}</span></li>
    <li><span><strong>{The mechanism.}</strong> {one clause}</span></li>
    <li><span><strong>{Why it matters.}</strong> {one clause}</span></li>
  </ul>
</div>
<div class="card" style="margin-top:14px;">
  <p class="label">In one diagram</p>
  <div class="diagram-wrap">
    <svg viewBox="0 0 720 320" role="img" aria-label="{accessible description}"><!-- see Inline-SVG diagram below --></svg>
  </div>
</div>
```

---

## Inline-SVG diagram

- **MD-native:** none — Markdown can't draw. (Mermaid would need JS, which the doc-reviewer sandbox blocks. ASCII art is illegible at doc width.)
- **Promote when:** always, for any architecture / flow / state / sequence figure. Diagrams are *always* HTML blocks.

Minimal worked SVG (box + labeled arrow). The arrowhead `<marker>` is defined once per SVG even with multiple arrows.

```html
<svg viewBox="0 0 720 320" role="img" aria-label="Two boxes connected by a labeled arrow">
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" fill="#475569"/>
    </marker>
  </defs>
  <rect x="60" y="120" width="180" height="80" rx="10" fill="#ffffff" stroke="#cbd5e1" stroke-width="1.5"/>
  <text x="150" y="165" text-anchor="middle" font-family="Inter" font-size="14" fill="#0f172a">Source</text>
  <line x1="240" y1="160" x2="480" y2="160" stroke="#475569" stroke-width="1.5" marker-end="url(#arrow)"/>
  <text x="360" y="150" text-anchor="middle" font-family="Inter" font-size="12" fill="#475569">transforms</text>
  <rect x="480" y="120" width="180" height="80" rx="10" fill="#eef2ff" stroke="#c7d2fe" stroke-width="1.5"/>
  <text x="570" y="165" text-anchor="middle" font-family="Inter" font-size="14" fill="#0f172a">Target</text>
</svg>
```

---

## Decision card (open)

- **MD-native:** a `### Decision N — {title}` heading, a sentence of framing, then a bullet per option with a `**(recommended)**` tag. Fine for a single low-stakes decision.
- **Promote when:** there are ≥2 decisions, or the decision is consequential and deserves visual isolation from the surrounding analysis. Amber left border = action required.

```html
<div class="decision-card">
  <div class="head">
    <div class="num">{N}</div>
    <div style="flex:1; min-width:0;">
      <h3>{Decision title}</h3>
      <p class="desc">{One sentence: what's being decided and why it matters.}</p>
      <div class="options">
        <div class="option">
          <p class="opt-title">Option A · {label} <span class="opt-rec">(recommended)</span></p>
          <p class="opt-note">{trade-off in one short paragraph}</p>
        </div>
        <div class="option">
          <p class="opt-title">Option B · {label}</p>
          <p class="opt-note">{trade-off in one short paragraph}</p>
        </div>
      </div>
    </div>
  </div>
</div>
```

---

## Decision card (RESOLVED)

Once the decision is made, transform the open card: emerald left border, emerald `.num`, a RESOLVED pill, and the options replaced by a one-paragraph recap linking the review thread.

```html
<div class="decision-card" style="border-left-color:var(--good-border);">
  <div class="head">
    <div class="num" style="background:var(--good-bg); color:var(--good);">{N}</div>
    <div style="flex:1; min-width:0;">
      <div style="display:flex; align-items:center; gap:10px; flex-wrap:wrap;">
        <h3 style="margin:0;">{Decision title}</h3>
        <span class="pill" style="background:var(--good-bg); color:var(--good); border-color:var(--good-border);"><span class="dot" style="background:#10b981;"></span>RESOLVED</span>
      </div>
      <p class="desc" style="margin:6px 0 0;">Closed via review (T{thread-id-prefix}): {one-sentence recap + brief justification}.</p>
    </div>
  </div>
</div>
```

---

## Callout (info / warn / good)

- **MD-native:** a blockquote `> **Thesis:** …`. Adequate for an aside.
- **Promote when:** the callout carries a thesis/definition (info, sky), a risk or "agent does NOT" boundary (warn, amber), or a recommendation/resolution (good, emerald) that the reader must not miss. One paragraph max.

```html
<div class="callout callout-info">
  <p class="kicker">Thesis</p>
  <p>{one-paragraph body}</p>
</div>
```

`callout-info` (sky) · `callout-warn` (amber) · `callout-good` (emerald). Keep usage consistent across docs.

---

## Premise list

- **MD-native:** a numbered list `1. …`. Use this unless the premises form an argument the reader will reference back to.
- **Promote when:** the doc builds a conclusion from a chain of premises and you want P1/P2/… markers the reader can cite.

```html
<ol class="premise-list">
  <li>{Premise — one sentence.}</li>
  <li>{Premise — one sentence.}</li>
</ol>
```

---

## Comparison table

- **MD-native:** a plain Markdown table with `Approach | Pros | Cons | Verdict` columns. **Default to this for 2–3 alternatives.**
- **Promote when:** you need color-coded Pros (green) / Cons (red) headers, a highlighted chosen row, or verdict pills — i.e. the comparison is the centerpiece of the doc.

```html
<table>
  <thead><tr>
    <th style="width:22%;">Approach</th>
    <th class="col-pros" style="width:26%;">Pros</th>
    <th class="col-cons" style="width:26%;">Cons</th>
    <th style="width:26%;">Concession / verdict</th>
  </tr></thead>
  <tbody>
    <tr class="row-chosen">
      <td><strong>{A. Title}</strong><br><span style="font-size:12px; color:var(--text-3);">{one line}</span><br><span class="verdict-pill verdict-chosen">Chosen</span></td>
      <td>{pros}</td><td>{cons}</td><td>{verdict}</td>
    </tr>
    <tr>
      <td><strong>{B. Title}</strong><br><span style="font-size:12px; color:var(--text-3);">{one line}</span><br><span class="verdict-pill verdict-rejected">Rejected</span></td>
      <td>{pros}</td><td>{cons}</td><td>{verdict}</td>
    </tr>
  </tbody>
</table>
```

---

## Three-pieces grid

- **MD-native:** three `### Piece N — {name}` sub-sections, each with a `path/to/thing` line and a paragraph.
- **Promote when:** the recommendation (or any concept) has 2–4 distinct moving parts the reader should see side by side. Auto-fits 2/3/4 wide.

```html
<div class="three-pieces">
  <div class="piece"><div class="badge">1</div><h3>{Piece}</h3><p class="path">{path or location}</p><p>{one paragraph}</p></div>
  <div class="piece"><div class="badge">2</div><h3>{Piece}</h3><p class="path">{path or location}</p><p>{one paragraph}</p></div>
  <div class="piece"><div class="badge">3</div><h3>{Piece}</h3><p class="path">{path or location}</p><p>{one paragraph}</p></div>
</div>
```

For N=4–6 variants laid out for side-by-side comparison, the same grid CSS scales; label each cell with the trade-off it makes.

---

## Anatomy / strategy grid

- **MD-native:** a bullet list `- **Element** — what it is.` ×6–10. Use this if the items are read top-to-bottom.
- **Promote when:** the reader scans the set rather than reading it linearly (e.g. "what makes the doc rich", "the quality bar"), and a compact auto-fit grid of bold-label + description cells reads faster.

```html
<div class="anatomy-grid">
  <div><strong>{Element name}</strong> — {one-sentence what-it-is}.</div>
  <div><strong>{Element name}</strong> — {one-sentence what-it-is}.</div>
  <!-- 6–10 entries -->
</div>
```

---

## Steps list + total

- **MD-native:** a numbered list, each item `**{Step}** — {what}. (~N td · ~M K tokens · ~L LoC)`.
- **Promote when:** there are ≥4 steps each carrying a cost line and you want the cost de-emphasized below the title plus a summed total card.

```html
<ol class="steps">
  <li><div class="step-num">1</div><div>
    <p class="step-title">{Step title}</p>
    <p class="step-desc">{what to do; which files; what to verify}</p>
    <p class="step-cost">~{N} td · ~{M}K output tokens · ~{L} LoC equivalent</p>
  </div></li>
</ol>
<div class="total-card"><span class="total-label">Total</span><span>~<strong>{N} token-day</strong> (~${cost}, ~{tokens} output tokens, ~{LoC} LoC equivalent).</span></div>
```

---

## Code block

- **MD-native:** a triple-backtick fence with a language tag. **Default to this** — it's syntax-highlighted by every renderer.
- **Promote when:** you want the dark inline style with greyed `# comment` lines woven into an explainer (rare).

```html
<pre class="code-block"><span class="com"># comment line</span>
actual command or code line</pre>
```

---

## Deferred bullets

- **MD-native:** a bullet list `- **Item.** why deferred + how it's tracked.`
- **Promote when:** you want the lighter "·"-marker styling that signals "parking lot, not action items".

```html
<ul class="deferred-list">
  <li><span><strong>{Item.}</strong> {why deferred + tracking mechanism, e.g. P2E story label}</span></li>
</ul>
```
