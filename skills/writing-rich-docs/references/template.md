---
title: "{{TITLE}}"
hash: "{{HASH}}"
status: DRAFT          # DRAFT | ACCEPTED | RESOLVED | DEPRECATED
date: "{{DATE}}"
owner: "{{OWNER}}"
# doc-reviewer-id: ...  # added on demand by the doc-reviewer workflow
---

<!--
  RICH MARKDOWN DOC — Markdown carries structure (~50%), HTML blocks carry fidelity (the rest).

  • Write headings, prose, RRR/background, simple lists, simple 2–3-col tables, code fences in PLAIN MARKDOWN.
  • Promote a region to an HTML block (snippets in references/components.md) only when a visual structure
    carries it better — see the promote-or-not table in references/strategies.md.
  • Diagrams are ALWAYS HTML blocks: inline SVG only, never Mermaid (needs JS), never an image file.
  • Every HTML block lives inside <div class="rich-doc">…</div> so the <style> below scopes to it and does
    not fight doc-reviewer's Markdown rendering. Give each block a stable id so doc-reviewer can anchor comments.
  • Inside HTML blocks: NO <script>, NO <details>/<summary> for content discovery, NO <a href="#…"> anchor nav,
    NO position:sticky/fixed, NO in-doc TOC. doc-reviewer's rail handles the outline. Single linear scroll.

  Delete this comment and every "<!-- promote-if … -->" / placeholder comment before shipping.
-->

<style>
/* Component CSS for embedded HTML blocks. Scoped under .rich-doc so it never leaks into doc-reviewer's
   own Markdown styling. Do NOT edit — pick components from references/components.md and drop them in. */
.rich-doc {
  --surface:#ffffff; --surface-2:#f1f5f9; --border:#e2e8f0; --border-2:#cbd5e1;
  --text:#0f172a; --text-2:#334155; --text-3:#64748b; --text-4:#94a3b8;
  --accent:#4f46e5; --accent-bg:#eef2ff;
  --good:#047857; --good-bg:#ecfdf5; --good-border:#6ee7b7;
  --warn:#92400e; --warn-bg:#fffbeb; --warn-border:#fbbf24;
  --bad:#9f1239; --bad-bg:#fff1f2;
  --info:#075985; --info-bg:#eff6ff; --info-border:#7dd3fc;
  --code-bg:#f1f5f9; --radius:12px; --radius-sm:8px;
  --font-sans:"Inter",ui-sans-serif,system-ui,sans-serif;
  --font-mono:"JetBrains Mono",ui-monospace,SFMono-Regular,monospace;
  font-family:var(--font-sans); color:var(--text-2); line-height:1.55; font-size:15px;
}
.rich-doc *, .rich-doc *::before, .rich-doc *::after { box-sizing:border-box; }
.rich-doc h2 { font-size:20px; font-weight:700; margin:0 0 12px; color:var(--text); letter-spacing:-0.01em; }
.rich-doc h3 { font-size:15px; font-weight:600; margin:0 0 6px; color:var(--text); }
.rich-doc p { margin:0 0 12px; }
.rich-doc a { color:var(--accent); text-decoration:underline; text-underline-offset:2px; }
.rich-doc code { font-family:var(--font-mono); font-size:0.92em; background:var(--code-bg); padding:1px 6px; border-radius:4px; color:var(--text-2); }

/* pill (status / verdict) */
.rich-doc .pill { display:inline-flex; align-items:center; gap:6px; padding:3px 10px; border-radius:999px; font-size:10px; font-weight:700; letter-spacing:0.06em; text-transform:uppercase; background:var(--warn-bg); color:var(--warn); border:1px solid var(--warn-border); }
.rich-doc .pill .dot { width:6px; height:6px; border-radius:50%; background:#f59e0b; }

/* card + TL;DR list */
.rich-doc .card { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); padding:18px 20px; }
.rich-doc .card + .card { margin-top:14px; }
.rich-doc .card .label { font-size:10px; font-weight:700; letter-spacing:0.1em; text-transform:uppercase; color:var(--text-4); margin-bottom:10px; }
.rich-doc .tldr-list { list-style:none; padding:0; margin:0; }
.rich-doc .tldr-list li { display:flex; gap:12px; padding:6px 0; color:var(--text-2); }
.rich-doc .tldr-list li::before { content:"→"; color:var(--good); font-weight:700; flex:none; }
.rich-doc .tldr-list strong { color:var(--text); }

/* decision card */
.rich-doc .decision-card { background:var(--surface); border:1px solid var(--border); border-left:4px solid var(--warn-border); border-radius:var(--radius); padding:16px 18px; }
.rich-doc .decision-card + .decision-card { margin-top:12px; }
.rich-doc .decision-card .head { display:flex; align-items:flex-start; gap:12px; }
.rich-doc .decision-card .num { flex:none; width:28px; height:28px; border-radius:999px; background:var(--warn-bg); color:var(--warn); font-weight:700; font-size:13px; display:grid; place-items:center; }
.rich-doc .decision-card h3 { margin-bottom:4px; }
.rich-doc .decision-card .desc { font-size:13px; color:var(--text-3); margin:4px 0 12px; }
.rich-doc .options { display:grid; gap:10px; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); }
.rich-doc .option { border:1px solid var(--border); border-radius:var(--radius-sm); padding:10px 12px; background:var(--surface); }
.rich-doc .option .opt-title { font-size:12px; font-weight:600; color:var(--text-2); margin:0; }
.rich-doc .option .opt-rec { font-size:11px; color:var(--text-4); font-weight:400; margin-left:4px; }
.rich-doc .option .opt-note { font-size:12px; color:var(--text-3); margin-top:6px; line-height:1.5; }

/* callouts */
.rich-doc .callout { border-radius:var(--radius-sm); padding:14px 16px; border-left:4px solid; }
.rich-doc .callout .kicker { font-size:10px; font-weight:700; letter-spacing:0.08em; text-transform:uppercase; margin-bottom:4px; }
.rich-doc .callout p { margin:0; }
.rich-doc .callout-info { background:var(--info-bg); border-color:var(--info-border); }
.rich-doc .callout-info .kicker { color:var(--info); }
.rich-doc .callout-info p { color:var(--text); }
.rich-doc .callout-warn { background:var(--warn-bg); border-color:var(--warn-border); }
.rich-doc .callout-warn .kicker { color:var(--warn); }
.rich-doc .callout-good { background:var(--good-bg); border-color:var(--good-border); }
.rich-doc .callout-good .kicker { color:var(--good); }

/* premise list */
.rich-doc .premise-list { list-style:none; padding:0; margin:0; counter-reset:prem; }
.rich-doc .premise-list li { display:flex; gap:12px; padding:7px 0; font-size:14px; color:var(--text-2); counter-increment:prem; }
.rich-doc .premise-list li::before { content:"P" counter(prem); flex:none; width:30px; height:22px; background:var(--surface-2); color:var(--text-3); border-radius:4px; font-size:11px; font-weight:600; display:grid; place-items:center; }

/* rich table (only inside .rich-doc — plain Markdown tables keep doc-reviewer's default styling) */
.rich-doc table { width:100%; border-collapse:collapse; background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); overflow:hidden; font-size:13px; }
.rich-doc thead { background:var(--surface-2); }
.rich-doc th { text-align:left; font-weight:600; color:var(--text-2); padding:10px 14px; border-bottom:1px solid var(--border); font-size:12px; }
.rich-doc td { padding:12px 14px; vertical-align:top; color:var(--text-2); border-bottom:1px solid var(--border); }
.rich-doc tbody tr:last-child td { border-bottom:0; }
.rich-doc th.col-pros { color:var(--good); }
.rich-doc th.col-cons { color:var(--bad); }
.rich-doc .row-chosen { background:rgba(16,185,129,0.06); }
.rich-doc .verdict-pill { display:inline-block; font-size:9px; font-weight:700; letter-spacing:0.08em; text-transform:uppercase; padding:2px 8px; border-radius:999px; margin-top:6px; }
.rich-doc .verdict-chosen { background:var(--good); color:#fff; }
.rich-doc .verdict-rejected { background:var(--surface-2); color:var(--text-3); }

/* three-pieces grid */
.rich-doc .three-pieces { display:grid; gap:12px; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); margin-bottom:8px; }
.rich-doc .piece { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); padding:16px 18px; }
.rich-doc .piece .badge { display:inline-grid; place-items:center; width:24px; height:24px; background:var(--accent-bg); color:var(--accent); border-radius:6px; font-size:11px; font-weight:700; margin-bottom:8px; }
.rich-doc .piece h3 { font-size:14px; margin-bottom:4px; }
.rich-doc .piece .path { font-family:var(--font-mono); font-size:11px; color:var(--text-4); margin-bottom:8px; }
.rich-doc .piece p { font-size:13px; margin:0; }

/* anatomy grid */
.rich-doc .anatomy-grid { display:grid; gap:8px; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); font-size:13px; }
.rich-doc .anatomy-grid > div { background:var(--surface-2); padding:10px 12px; border-radius:8px; color:var(--text-2); }
.rich-doc .anatomy-grid strong { color:var(--text); }

/* code block (use a plain Markdown ``` fence unless you need the dark inline style) */
.rich-doc pre.code-block { background:#0f172a; color:#e2e8f0; border-radius:8px; padding:14px 16px; font-size:12px; line-height:1.65; overflow-x:auto; margin:10px 0 0; }
.rich-doc pre.code-block .com { color:#64748b; }

/* steps + total */
.rich-doc .steps { list-style:none; padding:0; margin:0; }
.rich-doc .steps li { display:flex; gap:12px; padding:10px 0; border-bottom:1px dashed var(--border); }
.rich-doc .steps li:last-child { border-bottom:0; }
.rich-doc .steps .step-num { flex:none; width:26px; height:26px; border-radius:6px; background:var(--accent-bg); color:var(--accent); font-weight:700; font-size:12px; display:grid; place-items:center; }
.rich-doc .steps p { margin:0; }
.rich-doc .steps .step-title { color:var(--text); font-weight:600; font-size:14px; margin-bottom:2px; }
.rich-doc .steps .step-desc { font-size:13px; color:var(--text-3); }
.rich-doc .steps .step-cost { font-size:11px; color:var(--text-4); margin-top:4px; }
.rich-doc .total-card { margin-top:14px; padding:12px 16px; background:var(--surface-2); border-radius:8px; display:flex; align-items:baseline; gap:12px; font-size:13px; color:var(--text-2); }
.rich-doc .total-card .total-label { font-size:10px; font-weight:700; letter-spacing:0.1em; text-transform:uppercase; color:var(--text-3); }

/* deferred bullets */
.rich-doc .deferred-list { list-style:none; padding:0; margin:0; }
.rich-doc .deferred-list li { display:flex; gap:10px; padding:8px 0; font-size:13px; color:var(--text-2); }
.rich-doc .deferred-list li::before { content:"·"; color:var(--text-4); flex:none; }
.rich-doc .deferred-list strong { color:var(--text); }

/* svg diagram */
.rich-doc .diagram-wrap { text-align:center; margin-top:8px; }
.rich-doc .diagram-wrap svg { max-width:100%; height:auto; }
</style>

# {{TITLE}}

`{{TYPE}}` · {{DATE}} · owner: {{OWNER}} · hash: `{{HASH}}` · status: **{{STATUS}}**

## 5-minute brief

Stop here if you only have 2 minutes.

<!-- promote-if: a 3-bullet TL;DR + a one-glance diagram beats a paragraph (it almost always does for a spec/design/ADR) -->
<div class="rich-doc" id="tldr">
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
      <svg viewBox="0 0 720 320" role="img" aria-label="{accessible description}"><!-- inline SVG only --></svg>
    </div>
  </div>
</div>

## Decisions you need to make

<!-- If there are no open decisions, retitle to "Decisions resolved" and use the RESOLVED card variant (see components.md).
     One decision-card per question requiring the reader's input. -->
<div class="rich-doc" id="decision-1">
  <div class="decision-card">
    <div class="head">
      <div class="num">1</div>
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
</div>

## Problem & context

<!-- Prose in Markdown. RRR shape if it's a story/spec: "As [role], I want [request], so that [rationale]." -->
{Background paragraph(s) — what exists today, why it's inadequate. Plain Markdown.}

<!-- promote-if: the argument is a chain of premises the reader should be able to scan without prose buildup -->
<div class="rich-doc" id="premises">
  <ol class="premise-list">
    <li>{Premise — one sentence.}</li>
    <li>{Premise — one sentence.}</li>
  </ol>
</div>

<!-- promote-if: there's an honest cost/risk the reader must weigh before reading on -->
<div class="rich-doc">
  <div class="callout callout-warn">
    <p class="kicker">Cost</p>
    <p>{the trade-off, stated plainly}</p>
  </div>
</div>

## Approaches considered

<!-- 2–3 alternatives in a plain Markdown table is fine. Promote to the rich comparison table only when you
     need color-coded Pros/Cons columns or a highlighted chosen row. -->
<div class="rich-doc" id="approaches-table">
  <table>
    <thead><tr><th style="width:22%;">Approach</th><th class="col-pros" style="width:26%;">Pros</th><th class="col-cons" style="width:26%;">Cons</th><th style="width:26%;">Verdict</th></tr></thead>
    <tbody>
      <tr class="row-chosen"><td><strong>{A. Title}</strong><br><span style="font-size:12px;color:var(--text-3);">{one line}</span><br><span class="verdict-pill verdict-chosen">Chosen</span></td><td>{pros}</td><td>{cons}</td><td>{why}</td></tr>
      <tr><td><strong>{B. Title}</strong><br><span style="font-size:12px;color:var(--text-3);">{one line}</span><br><span class="verdict-pill verdict-rejected">Rejected</span></td><td>{pros}</td><td>{cons}</td><td>{why}</td></tr>
    </tbody>
  </table>
</div>

## Recommended approach

<!-- promote-if: the recommendation has 2–4 distinct moving parts the reader should see side by side -->
<div class="rich-doc" id="recommendation-pieces">
  <div class="three-pieces">
    <div class="piece"><div class="badge">1</div><h3>{Piece}</h3><p class="path">{path or location}</p><p>{one paragraph}</p></div>
    <div class="piece"><div class="badge">2</div><h3>{Piece}</h3><p class="path">{path or location}</p><p>{one paragraph}</p></div>
    <div class="piece"><div class="badge">3</div><h3>{Piece}</h3><p class="path">{path or location}</p><p>{one paragraph}</p></div>
  </div>
</div>

{Supporting detail in Markdown sub-sections (`###`). Promote any sub-section to an anatomy grid / callout / code block per references/components.md when a visual structure carries it better.}

## Implementation plan

<!-- promote-if: numbered steps with per-step cost read better as a styled list than a Markdown ol -->
<div class="rich-doc" id="plan">
  <ol class="steps">
    <li><div class="step-num">1</div><div><p class="step-title">{Step}</p><p class="step-desc">{what + which files + what to verify}</p><p class="step-cost">~{N} td · ~{M}K output tokens · ~{L} LoC equivalent</p></div></li>
  </ol>
  <div class="total-card"><span class="total-label">Total</span><span>~<strong>{N} token-day</strong> (~${cost}, ~{tokens} output tokens, ~{LoC} LoC equivalent).</span></div>
</div>

## Deferred / out of scope

Things that came up but don't need to ship in v1.

<div class="rich-doc" id="deferred">
  <ul class="deferred-list">
    <li><span><strong>{Item.}</strong> {why deferred + how it's tracked, e.g. P2E story label}</span></li>
  </ul>
</div>
