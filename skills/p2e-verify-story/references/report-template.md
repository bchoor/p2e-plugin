# Report Template — Rich-Doc HTML Structure

The report is a single self-contained `.html` file optimized for human review. Visual hierarchy, color-coded verdicts, and side-by-side comparisons let a reviewer scan all results in one scroll. This reference documents the component patterns that the template implements.

## Document shape

```
┌─────────────────────────────────────────────────┐
│ HEADER                                          │
│ Title · Overall verdict pill                    │
│ Sub: branch · date · driver tools used          │
│ Story context · setup notes (collapsed)         │
├─────────────────────────────────────────────────┤
│ SUMMARY GRID                                    │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                 │
│ │ AC1 │ │ AC2 │ │ AC3 │ │ AC4 │                 │
│ │PASS │ │PASS │ │FAIL │ │PASS │                 │
│ └─────┘ └─────┘ └─────┘ └─────┘                 │
├─────────────────────────────────────────────────┤
│ ANCHOR NAV (optional)                           │
│ Jump: AC1 · AC2 · AC3 · AC4 · Assessment        │
├─────────────────────────────────────────────────┤
│ AC1 SECTION                                     │
│ AC1 · Title · [PASS pill]                       │
│ Description (one paragraph)                     │
│ ┌─ Expected ─┐ ┌─ Observed ─┐                   │
│ │ - ...      │ │ - ...      │                   │
│ │ - ...      │ │ - ...      │                   │
│ └────────────┘ └────────────┘                   │
│ ┌─ Evidence figure (1-up or 2-up) ─┐            │
│ │ [screenshot]    [screenshot]     │            │
│ │ caption         caption          │            │
│ └──────────────────────────────────┘            │
│ Verdict: [PASS pill] short note                 │
│ [optional caveat callout — orange border]       │
├─────────────────────────────────────────────────┤
│ AC2 SECTION                                     │
│ ...                                             │
├─────────────────────────────────────────────────┤
│ OVERALL ASSESSMENT                              │
│ Verdict statement                               │
│ ▸ What was verified                             │
│ ▸ What was NOT verified                         │
│ ▸ Recommendation                                │
└─────────────────────────────────────────────────┘
```

## Critical conventions

- **Wrap everything in `<div class="rich-doc" id="<story-id>-uat">`** — all CSS is scoped under `.rich-doc` so it doesn't leak when the file is opened in a parent context that has its own styles.
- **Embed all styles in a single `<style>` block** inside `<head>`. No external stylesheets, no Tailwind CDN.
- **No external assets.** All images are relative-path references to files in the same artifacts dir. No CDN images, no jsDelivr, no Google Fonts (use system font stacks).
- **No `position: sticky` or `position: fixed`.** Breaks layout in iframe-embedded renderers that may host this HTML.
- **No in-doc TOC.** the renderer (if any) typically renders its own outline; an in-document TOC duplicates that. Use anchor nav (short row of jump links) instead.

## Permitted interactivity

Per the `feedback_html_doc_interactivity_scope` convention, these are typically allowed by iframe-renderers (sandbox allow-scripts permitting) and add real value when comparing variants:

- **`<details>` / `<summary>`** for collapsible sections. Great for pre-flight notes, raw curl output, long observation lists.
- **`<a href="#section-id">`** for anchor nav within the document.
- **CSS-only tabs** via `<input type="radio" name="tabs" id="tabN">` + sibling selector. Use to compare 2–4 variants that share shape (e.g. before/after, three implementation approaches).
- **Inline `<script>`** (no external `src`) — for richer interactivity like filtering ACs by verdict, expanding all/collapsing all, or animating between before/after states. Keep small (< 100 lines) and dependency-free.

Default to single linear scroll. Reach for tabs / inline scripts only when comparing 2–4 alternatives that share shape — they save a reviewer's scroll without adding visual complexity.

## Component patterns

### Verdict pill

```html
<span class="pill pass">PASS</span>
<span class="pill fail">FAIL</span>
<span class="pill warn">CAVEAT</span>
```

CSS:
```css
.pill {
  display: inline-block;
  padding: 2px 9px;
  border-radius: 99px;
  font-size: 11.5px;
  font-weight: 600;
  letter-spacing: 0.02em;
}
.pill.pass {
  background: rgba(52, 199, 89, 0.16);
  color: var(--pass);
  border: 1px solid color-mix(in srgb, var(--pass) 40%, transparent);
}
.pill.fail { /* same shape with --fail color */ }
.pill.warn { /* same shape with --warn color */ }
```

Use the pill in three places per AC: the summary card, the section header, and the verdict block at the end of the section. Triple-encoding reinforces the verdict for skimmers.

### Summary grid

```html
<div class="summary">
  <div class="card"><div class="label">AC1 · <short name></div><div class="value"><span class="pill pass">PASS</span></div></div>
  <div class="card"><div class="label">AC2 · <short name></div><div class="value"><span class="pill pass">PASS</span></div></div>
  ...
</div>
```

CSS:
```css
.summary { display: grid; grid-template-columns: repeat(<N>, 1fr); gap: 10px; margin: 16px 0 28px; }
.summary .card { background: var(--pane); border: 1px solid var(--rule); border-radius: 8px; padding: 12px 14px; }
```

For 1–4 ACs use `repeat(N, 1fr)`. For 5+ ACs use `repeat(auto-fit, minmax(140px, 1fr))` to wrap.

### Per-AC section

```html
<section class="ac">
  <header>
    <span class="num">AC1</span>
    <h2>Visible diff overlay when baseline=Git:HEAD and working copy diverges</h2>
    <span class="pill pass" style="margin-left:auto">PASS</span>
  </header>
  <p class="desc">One-paragraph description of what the AC requires.</p>

  <div class="row">
    <div class="col">
      <h3>Expected</h3>
      <ul><li>...</li></ul>
    </div>
    <div class="col">
      <h3>Observed</h3>
      <ul><li>...</li></ul>
    </div>
  </div>

  <figure>
    <img src="01-ac1.png" alt="...">
    <figcaption>One-line caption</figcaption>
  </figure>

  <div class="verdict">
    <span class="label">Verdict</span>
    <span class="pill pass">PASS</span>
    <span class="muted">One-line rationale.</span>
  </div>
</section>
```

### Before/After 2-up grid

For ACs where a visual change is the verification:

```html
<div class="figs-2up">
  <figure>
    <img src="01-ac1-before.png" alt="...">
    <figcaption>Before · context</figcaption>
  </figure>
  <figure>
    <img src="02-ac1-after.png" alt="...">
    <figcaption>After · change applied</figcaption>
  </figure>
</div>
```

CSS:
```css
.figs-2up { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin: 12px 0; }
```

### Caveat callout

When an AC passes but the implementation has a known UX issue worth flagging:

```html
<p class="caveat">
  <span class="pill warn">UX caveat (follow-up)</span>
  Description of the caveat, with link to the follow-up issue.
</p>
```

CSS:
```css
.caveat {
  margin-top: 12px;
  padding: 10px 12px;
  background: rgba(255, 176, 32, 0.10);
  border-left: 3px solid var(--warn);
  border-radius: 4px;
}
```

Use sparingly. A caveat is not a fail — it's "this works, but here's a follow-up." If you find yourself adding caveats to most ACs, the implementation probably isn't ready and the verdict should be FAIL.

### Pre-flight notes (collapsible)

```html
<details>
  <summary>Pre-flight notes (what was set up before testing)</summary>
  <ul>
    <li>Killed stale dev process on the default port...</li>
    <li>Launched bun run dev:server / dev:client as detached nohup...</li>
    <li>Set docs root via POST /api/set-root...</li>
  </ul>
</details>
```

Collapsing by default keeps the report scan-friendly while preserving the audit trail.

### Curl evidence block

For backend-only ACs, embed the curl matrix in a `<pre>`:

```html
<h3>Captured stdout</h3>
<pre>--- 1. Happy path (200) ---
$ curl -s -w 'HTTP %{http_code}\n' '...'
HTTP 200
...
</pre>
<p class="muted">Full output saved to <code>05-curl-evidence.txt</code>.</p>
```

### Overall assessment

```html
<section class="assessment">
  <h2>Overall assessment</h2>
  <p><strong>Verdict: PASS — ready to ...</strong> ...one sentence summary.</p>

  <h3>What was verified</h3>
  <ul><li>...</li></ul>

  <h3>What was NOT verified (out of scope)</h3>
  <ul><li>...</li></ul>

  <h3>Recommendation</h3>
  <p>...</p>
</section>
```

The "What was NOT verified" list is critical — every UAT has scope limits, and being explicit prevents the reviewer from assuming coverage you didn't actually provide.

## Theme tokens

Use CSS custom properties scoped under `.rich-doc`. Default to dark; switch via `@media (prefers-color-scheme: light)`:

```css
.rich-doc {
  --bg: #0f1115;
  --pane: #161a22;
  --pane-2: #1d2230;
  --fg: #e6e8ee;
  --fg-muted: #9aa3b2;
  --rule: #2a3142;
  --accent: #6aa9ff;
  --pass: #34c759;
  --fail: #ff453a;
  --warn: #ffb020;
  --code-bg: #0b0d12;
  --code-fg: #d2d6df;
}

@media (prefers-color-scheme: light) {
  .rich-doc {
    --bg: #fafbfd;
    --pane: #ffffff;
    --pane-2: #f3f5f9;
    --fg: #1f2330;
    /* ... */
  }
}
```

Tokens give the reviewer a familiar visual vocabulary (green = pass, red = fail, yellow = caveat) without prose explanation.

## Typography

```css
.rich-doc {
  font: 14px/1.55 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  max-width: 1080px;
  margin: 0 auto;
  padding: 32px 28px 80px;
}
```

System font stacks render fast and avoid the external-font ban. 1080px max-width keeps line lengths legible on wide monitors.

## Length budget

Aim for the report to be readable in 60 seconds at a glance:
- Summary grid → ~5 seconds
- Per-AC sections → ~10 seconds each
- Overall assessment → ~10 seconds

If a section is longer than ~150 words of prose, ask whether it should be a `<details>` block instead.

## Validating the report

Before declaring done:
1. Open the file in Chrome via `mcp__chrome-devtools__new_page` at the `file://` URL.
2. Verify all images load (no broken figures).
3. Verify the summary grid pills match the per-section verdict pills.
4. Verify pre-flight notes section collapses/expands.
5. Take a full-page screenshot at `00-report-preview.png` as the at-a-glance image.
