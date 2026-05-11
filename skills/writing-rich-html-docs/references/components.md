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
    <li><span><strong>{Bullet 1 lead.}</strong> {Detail prose.}</span></li>
    <li><span><strong>{Bullet 2 lead.}</strong> {Detail prose.}</span></li>
    <li><span><strong>{Bullet 3 lead.}</strong> {Detail prose.}</span></li>
  </ul>
</div>
```

## Diagram card (in 5-min brief)

```html
<div class="card" style="margin-top: 14px;">
  <p class="label">Recommendation in one diagram</p>
  <div class="diagram-wrap">
    <svg viewBox="0 0 720 360" role="img" aria-label="{accessible description}">
      <!-- inline SVG markup; never use Mermaid. -->
    </svg>
  </div>
</div>
```

Minimal worked SVG (box + labeled arrow with an arrowhead marker) — copy and adapt for your diagram. The arrowhead `<marker>` only needs to be defined once per SVG even if you use multiple arrows.

```html
<svg viewBox="0 0 720 360" role="img" aria-label="Two boxes connected by a labeled arrow">
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" fill="#475569"/>
    </marker>
  </defs>
  <!-- Box 1 -->
  <rect x="60"  y="140" width="180" height="80" rx="10"
        fill="#ffffff" stroke="#cbd5e1" stroke-width="1.5"/>
  <text x="150" y="185" text-anchor="middle"
        font-family="Inter" font-size="14" fill="#0f172a">Source</text>
  <!-- Arrow + label -->
  <line x1="240" y1="180" x2="480" y2="180"
        stroke="#475569" stroke-width="1.5" marker-end="url(#arrow)"/>
  <text x="360" y="170" text-anchor="middle"
        font-family="Inter" font-size="12" fill="#475569">transforms</text>
  <!-- Box 2 -->
  <rect x="480" y="140" width="180" height="80" rx="10"
        fill="#eef2ff" stroke="#c7d2fe" stroke-width="1.5"/>
  <text x="570" y="185" text-anchor="middle"
        font-family="Inter" font-size="14" fill="#0f172a">Target</text>
</svg>
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
