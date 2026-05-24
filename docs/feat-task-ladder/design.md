---
title: "Shared 6-step task ladder for /p2e-work-on-next and /implement-spec"
hash: "task-ladder-v2"
status: DRAFT
date: "2026-05-24"
owner: "bchoor"
---

<style>
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

.rich-doc .pill { display:inline-flex; align-items:center; gap:6px; padding:3px 10px; border-radius:999px; font-size:10px; font-weight:700; letter-spacing:0.06em; text-transform:uppercase; background:var(--warn-bg); color:var(--warn); border:1px solid var(--warn-border); }
.rich-doc .pill .dot { width:6px; height:6px; border-radius:50%; background:#f59e0b; }

.rich-doc .card { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); padding:18px 20px; }
.rich-doc .card + .card { margin-top:14px; }
.rich-doc .card .label { font-size:10px; font-weight:700; letter-spacing:0.1em; text-transform:uppercase; color:var(--text-4); margin-bottom:10px; }
.rich-doc .tldr-list { list-style:none; padding:0; margin:0; }
.rich-doc .tldr-list li { display:flex; gap:12px; padding:6px 0; color:var(--text-2); }
.rich-doc .tldr-list li::before { content:"→"; color:var(--good); font-weight:700; flex:none; }
.rich-doc .tldr-list strong { color:var(--text); }

.rich-doc .decision-card { background:var(--surface); border:1px solid var(--border); border-left:4px solid var(--warn-border); border-radius:var(--radius); padding:16px 18px; }
.rich-doc .decision-card + .decision-card { margin-top:12px; }
.rich-doc .decision-card .head { display:flex; align-items:flex-start; gap:12px; }
.rich-doc .decision-card .num { flex:none; width:28px; height:28px; border-radius:999px; background:var(--warn-bg); color:var(--warn); font-weight:700; font-size:13px; display:grid; place-items:center; }
.rich-doc .decision-card h3 { margin-bottom:4px; }
.rich-doc .decision-card .desc { font-size:13px; color:var(--text-3); margin:4px 0 0; }

.rich-doc .callout { border-radius:var(--radius-sm); padding:14px 16px; border-left:4px solid; margin-bottom:10px; }
.rich-doc .callout .kicker { font-size:10px; font-weight:700; letter-spacing:0.08em; text-transform:uppercase; margin-bottom:4px; }
.rich-doc .callout p { margin:0; }
.rich-doc .callout-info { background:var(--info-bg); border-color:var(--info-border); }
.rich-doc .callout-info .kicker { color:var(--info); }
.rich-doc .callout-info p { color:var(--text); }
.rich-doc .callout-warn { background:var(--warn-bg); border-color:var(--warn-border); }
.rich-doc .callout-warn .kicker { color:var(--warn); }
.rich-doc .callout-good { background:var(--good-bg); border-color:var(--good-border); }
.rich-doc .callout-good .kicker { color:var(--good); }

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

.rich-doc .three-pieces { display:grid; gap:12px; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); margin-bottom:8px; }
.rich-doc .piece { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); padding:16px 18px; }
.rich-doc .piece .badge { display:inline-grid; place-items:center; width:24px; height:24px; background:var(--accent-bg); color:var(--accent); border-radius:6px; font-size:11px; font-weight:700; margin-bottom:8px; }
.rich-doc .piece h3 { font-size:14px; margin-bottom:4px; }
.rich-doc .piece .path { font-family:var(--font-mono); font-size:11px; color:var(--text-4); margin-bottom:8px; }
.rich-doc .piece p { font-size:13px; margin:0; }

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

.rich-doc .deferred-list { list-style:none; padding:0; margin:0; }
.rich-doc .deferred-list li { display:flex; gap:10px; padding:8px 0; font-size:13px; color:var(--text-2); }
.rich-doc .deferred-list li::before { content:"·"; color:var(--text-4); flex:none; }
.rich-doc .deferred-list strong { color:var(--text); }

.rich-doc .diagram-wrap { text-align:center; margin-top:8px; }
.rich-doc .diagram-wrap svg { max-width:100%; height:auto; }

/* anchor jump-pills (top nav) */
.rich-doc .jump-pills { display:flex; gap:6px; flex-wrap:wrap; margin:4px 0 22px; }
.rich-doc .jump-pills a { display:inline-block; padding:4px 10px; border-radius:999px; background:var(--surface-2); color:var(--text-3); font-size:11px; font-weight:600; text-decoration:none; border:1px solid var(--border); }
.rich-doc .jump-pills a:hover { background:var(--accent-bg); color:var(--accent); border-color:var(--accent); }

/* CSS-only tabs */
.rich-doc .tabs { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); overflow:hidden; position:relative; }
.rich-doc .tabs input[type="radio"] { position:absolute; opacity:0; pointer-events:none; }
.rich-doc .tabs .tab-bar { display:flex; background:var(--surface-2); border-bottom:1px solid var(--border); }
.rich-doc .tabs .tab-bar label { padding:10px 16px; font-size:12px; font-weight:600; color:var(--text-3); cursor:pointer; border-right:1px solid var(--border); transition:all 120ms; }
.rich-doc .tabs .tab-bar label:hover { color:var(--text); background:var(--surface); }
.rich-doc .tabs .tab-panel { display:none; padding:18px 20px; }
.rich-doc #tab-work:checked ~ .tab-bar label[for="tab-work"],
.rich-doc #tab-spec:checked ~ .tab-bar label[for="tab-spec"] { background:var(--surface); color:var(--accent); border-bottom:2px solid var(--accent); margin-bottom:-1px; }
.rich-doc #tab-work:checked ~ .tab-panel.panel-work,
.rich-doc #tab-spec:checked ~ .tab-panel.panel-spec { display:block; }

/* collapsibles */
.rich-doc details { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); padding:0; margin:0 0 14px; overflow:hidden; }
.rich-doc details[open] { border-color:var(--border-2); }
.rich-doc summary { padding:12px 16px; font-size:13px; font-weight:600; color:var(--text); cursor:pointer; user-select:none; list-style:none; display:flex; align-items:center; gap:8px; background:var(--surface-2); }
.rich-doc summary::-webkit-details-marker { display:none; }
.rich-doc summary:hover { background:var(--accent-bg); color:var(--accent); }
.rich-doc summary::before { content:"\25B8"; font-size:10px; transition:transform 120ms; color:var(--text-4); }
.rich-doc details[open] summary::before { transform:rotate(90deg); }
.rich-doc summary .count { font-size:11px; color:var(--text-3); font-weight:400; margin-left:auto; }
.rich-doc details > .details-body { padding:16px 20px; border-top:1px solid var(--border); }

/* interactive ladder demo */
.rich-doc .demo { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); padding:18px 20px; margin-top:14px; }
.rich-doc .demo .demo-head { display:flex; align-items:baseline; justify-content:space-between; gap:12px; margin-bottom:4px; }
.rich-doc .demo .demo-title { font-size:14px; font-weight:600; color:var(--text); margin:0; }
.rich-doc .demo .demo-sub { font-size:12px; color:var(--text-3); }
.rich-doc .demo .steps-strip { display:flex; gap:6px; margin:14px 0 0; flex-wrap:wrap; }
.rich-doc .demo .step-chip { flex:1 1 100px; min-width:90px; padding:10px 8px; border-radius:8px; text-align:center; font-size:12px; font-weight:600; background:var(--surface-2); color:var(--text-3); border:1px solid var(--border); transition:all 160ms; }
.rich-doc .demo .step-chip.done { background:var(--good-bg); color:var(--good); border-color:var(--good-border); }
.rich-doc .demo .step-chip.active { background:var(--accent); color:#fff; border-color:var(--accent); transform:translateY(-2px); box-shadow:0 4px 8px rgba(79,70,229,0.18); }
.rich-doc .demo .step-chip .chip-num { font-size:9px; opacity:0.7; display:block; margin-bottom:3px; letter-spacing:0.06em; }
.rich-doc .demo .demo-controls { display:flex; gap:8px; margin-top:14px; align-items:center; flex-wrap:wrap; }
.rich-doc .demo button { padding:8px 14px; border-radius:8px; border:1px solid var(--accent); background:var(--accent); color:#fff; font-size:12px; font-weight:600; cursor:pointer; font-family:inherit; transition:opacity 120ms; }
.rich-doc .demo button:hover { opacity:0.9; }
.rich-doc .demo button.secondary { background:var(--surface); color:var(--accent); }
.rich-doc .demo button:disabled { opacity:0.5; cursor:not-allowed; }
.rich-doc .demo .progress-text { font-size:11px; color:var(--text-3); margin-left:auto; font-family:var(--font-mono); }
.rich-doc .demo .demo-log { margin-top:12px; padding:10px 12px; background:#0f172a; border-radius:8px; font-family:var(--font-mono); font-size:11px; color:#e2e8f0; min-height:72px; max-height:160px; overflow-y:auto; }
.rich-doc .demo .demo-log .log-entry { padding:2px 0; line-height:1.5; }
.rich-doc .demo .demo-log .log-entry .ts { color:#64748b; margin-right:8px; }
.rich-doc .demo .demo-log .log-entry .tag { display:inline-block; padding:0 5px; border-radius:3px; font-size:10px; font-weight:700; margin-right:6px; background:#1e293b; color:#94a3b8; }
.rich-doc .demo .demo-log .log-entry .tag.create { background:#1e3a8a; color:#bfdbfe; }
.rich-doc .demo .demo-log .log-entry .tag.update { background:#14532d; color:#bbf7d0; }
.rich-doc .demo .demo-log .log-entry .tag.log { background:#581c87; color:#e9d5ff; }
.rich-doc .demo .empty-hint { color:#64748b; font-style:italic; }
</style>

# Shared 6-step task ladder for `/p2e-work-on-next` and `/implement-spec`

`design` · 2026-05-24 · owner: bchoor · hash: `task-ladder-v2` · status: **DRAFT**

<div class="rich-doc" id="jump-nav">
  <div class="jump-pills">
    <a href="#tldr">TL;DR</a>
    <a href="#demo">Try it ▶</a>
    <a href="#decision-1">Decisions</a>
    <a href="#before-after">Before / After</a>
    <a href="#views">Per-command views</a>
    <a href="#approaches">Approaches</a>
    <a href="#plan">Plan</a>
    <a href="#deferred">Deferred</a>
  </div>
</div>

## 5-minute brief

<div class="rich-doc" id="tldr">
  <div class="card">
    <p class="label">TL;DR</p>
    <ul class="tldr-list">
      <li><span><strong>What changes.</strong> Both <code>/p2e-work-on-next</code> and <code>/implement-spec</code> codify a single shared 6-step ladder per story — Brief → Implement → Verify → Commit+PR → <code>/review-pr</code> → <code>/p2e-cut-release</code>.</span></li>
      <li><span><strong>Mechanism.</strong> <code>TaskCreate</code> carries live progress (one task per step per story, persisted across session restarts); step 6 invokes the already-shipped <code>/p2e-cut-release</code> (v0.10.4) which absorbs push+PR+CI+merge+bump+tag+release+story-closeout in one atomic call.</span></li>
      <li><span><strong>Why.</strong> Closes the two remaining gaps (codified step 4 commit+PR-open, codified step 5 <code>/review-pr</code>) and wires them into the now-shipped per-story release path. Branch-name convention <code>feat/&lt;STORY-ID&gt;-&lt;topic&gt;</code> auto-infers <code>--story-id</code> for step 6 — no flag needed.</span></li>
    </ul>
  </div>
  <div class="card" style="margin-top:14px;">
    <p class="label">The ladder, in one diagram</p>
    <div class="diagram-wrap">
      <svg viewBox="0 0 760 240" role="img" aria-label="Six-step ladder per story, terminating in /p2e-cut-release which closes the story to DONE">
        <defs>
          <marker id="arr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
            <path d="M0,0 L10,5 L0,10 z" fill="#64748b"/>
          </marker>
          <marker id="arrGood" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
            <path d="M0,0 L10,5 L0,10 z" fill="#047857"/>
          </marker>
        </defs>
        <text x="20" y="30" font-family="Inter" font-size="12" font-weight="700" fill="#64748b" letter-spacing="1">PER STORY (one release per merge)</text>
        <g font-family="Inter" font-size="12" fill="#0f172a">
          <rect x="20"  y="55" width="105" height="64" rx="10" fill="#eef2ff" stroke="#c7d2fe"/>
          <text x="72"  y="82"  text-anchor="middle" font-weight="700">1 · Brief</text>
          <text x="72"  y="100" text-anchor="middle" font-size="10" fill="#64748b">+ confirm</text>
          <rect x="133" y="55" width="105" height="64" rx="10" fill="#eef2ff" stroke="#c7d2fe"/>
          <text x="185" y="82"  text-anchor="middle" font-weight="700">2 · Implement</text>
          <text x="185" y="100" text-anchor="middle" font-size="10" fill="#64748b">agent(s)</text>
          <rect x="246" y="55" width="105" height="64" rx="10" fill="#eef2ff" stroke="#c7d2fe"/>
          <text x="298" y="82"  text-anchor="middle" font-weight="700">3 · Verify</text>
          <text x="298" y="100" text-anchor="middle" font-size="10" fill="#64748b">+ fix · IN_REVIEW</text>
          <rect x="359" y="55" width="105" height="64" rx="10" fill="#fffbeb" stroke="#fbbf24"/>
          <text x="411" y="82"  text-anchor="middle" font-weight="700">4 · Commit + PR</text>
          <text x="411" y="100" text-anchor="middle" font-size="10" fill="#92400e">new — codify</text>
          <rect x="472" y="55" width="105" height="64" rx="10" fill="#fffbeb" stroke="#fbbf24"/>
          <text x="524" y="82"  text-anchor="middle" font-weight="700">5 · /review-pr</text>
          <text x="524" y="100" text-anchor="middle" font-size="10" fill="#92400e">new — codify</text>
          <rect x="585" y="55" width="115" height="64" rx="10" fill="#4f46e5" stroke="#4338ca"/>
          <text x="642" y="80"  text-anchor="middle" font-weight="700" fill="#ffffff">6 · /p2e-cut-release</text>
          <text x="642" y="98"  text-anchor="middle" font-size="10" fill="#c7d2fe">shipped v0.10.4</text>
          <text x="642" y="112" text-anchor="middle" font-size="9" fill="#c7d2fe">push+PR+CI+merge+release+close</text>
        </g>
        <g stroke="#64748b" stroke-width="1.4" fill="none">
          <line x1="125" y1="87" x2="133" y2="87" marker-end="url(#arr)"/>
          <line x1="238" y1="87" x2="246" y2="87" marker-end="url(#arr)"/>
          <line x1="351" y1="87" x2="359" y2="87" marker-end="url(#arr)"/>
          <line x1="464" y1="87" x2="472" y2="87" marker-end="url(#arr)"/>
          <line x1="577" y1="87" x2="585" y2="87" marker-end="url(#arr)"/>
        </g>
        <g stroke="#047857" stroke-width="1.6" fill="none">
          <line x1="700" y1="87" x2="725" y2="87" marker-end="url(#arrGood)"/>
        </g>
        <g>
          <rect x="725" y="69" width="30" height="36" rx="8" fill="#ecfdf5" stroke="#6ee7b7"/>
          <text x="740" y="92" text-anchor="middle" font-family="Inter" font-size="10" font-weight="700" fill="#047857">DONE</text>
        </g>
        <g font-family="Inter" font-size="11" fill="#64748b">
          <text x="20" y="158" font-weight="700" letter-spacing="0.5" fill="#92400e">CONVENTION</text>
          <text x="20" y="178">Name the branch <tspan font-family="JetBrains Mono" font-size="11" fill="#0f172a">feat/&lt;STORY-ID&gt;-&lt;topic&gt;</tspan> (e.g. <tspan font-family="JetBrains Mono" font-size="11" fill="#0f172a">feat/DR-08-L8-folder-walk-progress</tspan>)</text>
          <text x="20" y="196">→ step 6 auto-infers <tspan font-family="JetBrains Mono" font-size="11" fill="#0f172a">--story-id</tspan>, closes IN_REVIEW → DONE on release, posts landed comment, flips GH label.</text>
          <text x="20" y="218" fill="#94a3b8" font-style="italic">No flag needed when the branch name carries the story-id.</text>
        </g>
      </svg>
    </div>
  </div>
</div>

<div class="rich-doc" id="demo">
  <div class="demo">
    <div class="demo-head">
      <p class="demo-title">Try the ladder — click <em>Advance</em> to step through a story</p>
      <span class="demo-sub">Simulates story #41 progressing from Brief to DONE</span>
    </div>
    <div class="steps-strip">
      <div class="step-chip"><span class="chip-num">STEP 1</span>Brief</div>
      <div class="step-chip"><span class="chip-num">STEP 2</span>Implement</div>
      <div class="step-chip"><span class="chip-num">STEP 3</span>Verify</div>
      <div class="step-chip"><span class="chip-num">STEP 4</span>Commit + PR</div>
      <div class="step-chip"><span class="chip-num">STEP 5</span>/review-pr</div>
      <div class="step-chip"><span class="chip-num">STEP 6</span>/p2e-cut-release</div>
    </div>
    <div class="demo-controls">
      <button data-action="advance">Advance →</button>
      <button class="secondary" data-action="reset">Reset</button>
      <span class="progress-text" data-role="progress">0/6 steps complete</span>
    </div>
    <div class="demo-log" data-role="log">
      <div class="log-entry empty-hint">Click "Advance" to see TaskCreate / TaskUpdate / story_log calls fire.</div>
    </div>
  </div>
</div>

## Decisions resolved

<div class="rich-doc" id="decision-1">
  <div class="decision-card" style="border-left-color:var(--good-border);">
    <div class="head">
      <div class="num" style="background:var(--good-bg); color:var(--good);">1</div>
      <div style="flex:1; min-width:0;">
        <div style="display:flex; align-items:center; gap:10px; flex-wrap:wrap;">
          <h3 style="margin:0;">Step 6 — Release scope</h3>
          <span class="pill" style="background:var(--good-bg); color:var(--good); border-color:var(--good-border);"><span class="dot" style="background:#10b981;"></span>RESOLVED</span>
        </div>
        <p class="desc"><strong>Revised post-v0.10.4:</strong> the original "once per batch" answer was wrong — <code>/p2e-cut-release</code> shipped as a per-story command on 2026-05-23 (commit <code>647bb26</code>) with branch-name <code>--story-id</code> inference, making one-release-per-merge the cheap default. "Version explosion" was the wrong concern: that's the cadence, not a bug. Step 6 invokes <code>/p2e-cut-release</code> per story; multi-story batch releases remain available via the separate <code>/p2e-ship-batch</code> command when actually needed.</p>
      </div>
    </div>
  </div>
</div>

<div class="rich-doc" id="decision-2">
  <div class="decision-card" style="border-left-color:var(--good-border);">
    <div class="head">
      <div class="num" style="background:var(--good-bg); color:var(--good);">2</div>
      <div style="flex:1; min-width:0;">
        <div style="display:flex; align-items:center; gap:10px; flex-wrap:wrap;">
          <h3 style="margin:0;">Step 5 — Review tool</h3>
          <span class="pill" style="background:var(--good-bg); color:var(--good); border-color:var(--good-border);"><span class="dot" style="background:#10b981;"></span>RESOLVED</span>
        </div>
        <p class="desc">Invoke the <code>pr-review-toolkit</code> plugin's <code>/review-pr</code> command. <code>/ultrareview</code> stays opt-in (user-triggered + billed; orchestrator can't launch it).</p>
      </div>
    </div>
  </div>
</div>

<div class="rich-doc" id="decision-3">
  <div class="decision-card" style="border-left-color:var(--good-border);">
    <div class="head">
      <div class="num" style="background:var(--good-bg); color:var(--good);">3</div>
      <div style="flex:1; min-width:0;">
        <div style="display:flex; align-items:center; gap:10px; flex-wrap:wrap;">
          <h3 style="margin:0;">/implement-spec convergence</h3>
          <span class="pill" style="background:var(--good-bg); color:var(--good); border-color:var(--good-border);"><span class="dot" style="background:#10b981;"></span>RESOLVED</span>
        </div>
        <p class="desc">Share the ladder structure + <code>TaskCreate</code>; persistence stays separate (<code>/p2e-work-on-next</code> keeps <code>story_log</code>; <code>/implement-spec</code> keeps <code>implementation-notes.html</code>).</p>
      </div>
    </div>
  </div>
</div>

## Problem & context

Two adjacent commands today have **different visibility models** and **incomplete ladders**.

`/p2e-work-on-next` uses status transitions (`OPEN → IN_PROGRESS → IN_REVIEW`) as its only "where are we" signal and writes structured `story_log` entries for the *interesting* events (AC toggles, verifications, blockers, decisions). But the workflow stops at `IN_REVIEW` — **steps 4 (commit + open PR), 5 (PR review), and 6 (release)** are done by other commands or ad hoc, never codified, never visible on a board.

`/implement-spec` keeps a sibling `implementation-notes.html` with design decisions / deviations / tradeoffs / open questions, but has **no step ladder at all** — you can't tell at a glance how far along an implementation is.

**Update — what just shipped (v0.10.4):** `/p2e-cut-release` landed yesterday and already implements step 6 end-to-end per story (Phase A: push + PR + CI + squash-merge; Phase B: bump + tag + `gh release create`; Phase E: `IN_REVIEW → DONE` + `kind:VERIFICATION` story-log + GH label flip + landed comment). The story-id is inferred from the branch name regex `[A-Z]+-[0-9]+-L[0-9]+` — so `feat/DR-08-L8-folder-walk-progress` auto-resolves to story `DR-08-L8` with no flag. **This narrows our scope:** steps 1-3 already work; step 4 (commit + open PR) needs codification; step 5 (`/review-pr`) is the one real missing piece in the auto-chain; step 6 is just an invocation of the shipped command.

<div class="rich-doc" id="thesis">
  <div class="callout callout-info">
    <p class="kicker">The thesis</p>
    <p>Live progress and durable decisions are two different things. <strong>TaskCreate</strong> is the right primitive for the first (persisted, structured, step-shaped); <strong>story_log / implementation-notes.html</strong> are the right primitives for the second. The two layers compose — they don't replace each other.</p>
  </div>
</div>

## Before / after

<div class="rich-doc" id="before-after">
  <table>
    <thead><tr>
      <th style="width:22%;">Surface</th>
      <th style="width:39%;">Today</th>
      <th style="width:39%;">After</th>
    </tr></thead>
    <tbody>
      <tr>
        <td><strong>"Where are we?" signal</strong></td>
        <td>Story status only. No live view across a multi-story wave; nothing survives a session restart unless you re-query MCP.</td>
        <td>One <code>TaskCreate</code> task per step per story; the task list IS the live board, persisted across restarts.</td>
      </tr>
      <tr>
        <td><strong>Step 4 — Commit + open PR</strong></td>
        <td>Implementer does it implicitly; not in the workflow.</td>
        <td>Explicit step in <code>workflows/p2e-work-on-next.md</code>; PR URL captured on the task.</td>
      </tr>
      <tr>
        <td><strong>Step 5 — PR review</strong></td>
        <td>Not part of the auto-chain at all.</td>
        <td>Auto-invokes <code>pr-review-toolkit</code>'s <code>/review-pr</code>; orchestrator addresses findings before marking step 5 done.</td>
      </tr>
      <tr>
        <td><strong>Step 6 — Release + story closeout</strong></td>
        <td>Separate <code>/cut-release</code>, no story-id awareness, no auto status flip. Judgment call when to run.</td>
        <td>Invoke <code>/p2e-cut-release</code> with story-id auto-inferred from branch name. Push + PR + CI + merge + bump + tag + release + <code>IN_REVIEW → DONE</code> in one atomic call. (Shipped v0.10.4 — no implementation work in this design.)</td>
      </tr>
      <tr>
        <td><strong>Branch naming</strong></td>
        <td>Free-form; story-id only manually linked via GH issue.</td>
        <td>Convention: <code>feat/&lt;STORY-ID&gt;-&lt;topic&gt;</code>. Enables zero-flag step-6 closeout. <code>/update-branch-name</code> rewrites mismatched branches.</td>
      </tr>
      <tr>
        <td><strong>Decision audit</strong></td>
        <td>p2e: <code>story_log</code>. implement-spec: <code>implementation-notes.html</code>. Two different mechanisms, no convergence.</td>
        <td>Same two mechanisms — convergence is the <em>ladder structure</em>, not the persistence layer.</td>
      </tr>
      <tr>
        <td><strong>/implement-spec visibility</strong></td>
        <td>No step view; you read the HTML notes to infer status.</td>
        <td>Same 6-step <code>TaskCreate</code> board (step 6 = n/a for specs without releases).</td>
      </tr>
    </tbody>
  </table>
</div>

## Approaches considered

<div class="rich-doc" id="approaches">
  <details open>
    <summary>4 approaches compared — A chosen, 3 rejected <span class="count">tap to collapse</span></summary>
    <div class="details-body">
  <table>
    <thead><tr>
      <th style="width:22%;">Approach</th>
      <th class="col-pros" style="width:26%;">Pros</th>
      <th class="col-cons" style="width:26%;">Cons</th>
      <th style="width:26%;">Concession / verdict</th>
    </tr></thead>
    <tbody>
      <tr class="row-chosen">
        <td><strong>A. TaskCreate ladder + native persistence</strong><br><span style="font-size:12px; color:var(--text-3);">Shared 6-step abstraction, each command keeps its existing audit trail</span><br><span class="verdict-pill verdict-chosen">Chosen</span></td>
        <td>Two layers with clear roles. Cheapest implementation. No schema migration. Both commands keep their best parts.</td>
        <td>Two persistence mechanisms remain; future tooling that wants a unified view has to read both.</td>
        <td>Accepted — the cost of a unified schema is much higher than the cost of reading two surfaces, and the ladder is the abstraction that matters for the user.</td>
      </tr>
      <tr>
        <td><strong>B. TaskCreate ladder + unified persistence</strong><br><span style="font-size:12px; color:var(--text-3);">Migrate <code>/implement-spec</code> to write a structured sidecar mirroring <code>story_log</code></span><br><span class="verdict-pill verdict-rejected">Rejected</span></td>
        <td>Future tooling sees one shape across both commands. Cleaner long-term.</td>
        <td>Larger blast radius. Requires designing a JSON schema + migration path for the HTML notes. /implement-spec users would lose the human-readable HTML.</td>
        <td>Cost-benefit not there yet — no consumer of the unified shape exists.</td>
      </tr>
      <tr>
        <td><strong>C. Ladder for /p2e-work-on-next only</strong><br><span style="font-size:12px; color:var(--text-3);">Leave <code>/implement-spec</code> untouched</span><br><span class="verdict-pill verdict-rejected">Rejected</span></td>
        <td>Smallest possible change.</td>
        <td>Misses the visibility win for spec implementation; two commands stay structurally different despite solving the same shape of problem.</td>
        <td>Diverging without reason — both surfaces benefit from the same ladder.</td>
      </tr>
      <tr>
        <td><strong>D. TodoWrite instead of TaskCreate</strong><br><span style="font-size:12px; color:var(--text-3);">The original sketch in this thread</span><br><span class="verdict-pill verdict-rejected">Rejected</span></td>
        <td>Familiar from older Claude Code sessions.</td>
        <td><strong>Tool no longer present.</strong> Ephemeral — dies on session restart, would force <code>story_log</code> to mirror step transitions just to survive.</td>
        <td>Replaced by TaskCreate (the actual current primitive). Persistence comes free.</td>
      </tr>
    </tbody>
  </table>
    </div>
  </details>
</div>

## Recommended approach — three moving pieces

<div class="rich-doc" id="three-pieces">
  <div class="three-pieces">
    <div class="piece">
      <div class="badge">1</div>
      <h3>TaskCreate ladder</h3>
      <p class="path">workflows/p2e-work-on-next.md · ~/.claude/commands/implement-spec.md</p>
      <p>One <code>TaskCreate</code> per step per story, title prefixed <code>[#41] 3/6 Verify &amp; fix</code>. <code>TaskUpdate</code> advances each step. One additional <code>TaskCreate</code> for the batch-level release.</p>
    </div>
    <div class="piece">
      <div class="badge">2</div>
      <h3>Native persistence, unchanged</h3>
      <p class="path">mcp__p2e__story_log · implementation-notes.html</p>
      <p>Existing <code>story_log</code> kinds (AC_CHANGE, VERIFICATION, BLOCKER, DECISION, SCOPE_CHANGE, NOTE) cover everything we need — no new kinds. <code>/implement-spec</code>'s HTML notes file stays exactly as-is.</p>
    </div>
    <div class="piece">
      <div class="badge">3</div>
      <h3>Cross-platform fallback</h3>
      <p class="path">workflows/p2e-work-on-next.md (asymmetry section)</p>
      <p>Claude Code = TaskCreate. Codex = its equivalent task primitive. Cursor (no task primitive) = a NOTE story_log entry per step transition. Document, don't paper over.</p>
    </div>
  </div>
</div>

## Per-command views

The same ladder applies to both commands, but a few steps behave differently. Tap a tab to see each command's path.

<div class="rich-doc" id="views">
  <div class="tabs">
    <input type="radio" name="view-tab" id="tab-work" checked>
    <input type="radio" name="view-tab" id="tab-spec">
    <div class="tab-bar">
      <label for="tab-work">/p2e-work-on-next</label>
      <label for="tab-spec">/implement-spec</label>
    </div>
    <div class="tab-panel panel-work">
      <ol class="steps">
        <li><div class="step-num">1</div><div><p class="step-title">Brief &amp; confirm</p><p class="step-desc">First-turn briefing from MCP story; thick-gate refuses thin drafts.</p></div></li>
        <li><div class="step-num">2</div><div><p class="step-title">Implement</p><p class="step-desc">Architect picks track; implementer agent(s) spawn with the briefing.</p></div></li>
        <li><div class="step-num">3</div><div><p class="step-title">Verify &amp; fix</p><p class="step-desc"><code>VERIFICATION</code> story_log entry + status flip to <code>IN_REVIEW</code>. Two-strike rule applies.</p></div></li>
        <li><div class="step-num">4</div><div><p class="step-title">Commit + PR</p><p class="step-desc">Commit on the feature branch (named <code>feat/&lt;STORY-ID&gt;-&lt;topic&gt;</code>); <code>gh pr create</code>.</p></div></li>
        <li><div class="step-num">5</div><div><p class="step-title">/review-pr</p><p class="step-desc">pr-review-toolkit reviews the open PR; orchestrator addresses findings.</p></div></li>
        <li><div class="step-num">6</div><div><p class="step-title">/p2e-cut-release</p><p class="step-desc">Auto-infers <code>--story-id</code> from branch. On success: <code>IN_REVIEW → DONE</code> + <code>VERIFICATION</code> log + GH label flip + landed comment.</p></div></li>
      </ol>
    </div>
    <div class="tab-panel panel-spec">
      <ol class="steps">
        <li><div class="step-num">1</div><div><p class="step-title">Brief &amp; confirm</p><p class="step-desc">Read the spec file; initialize <code>implementation-notes.html</code> as a sibling.</p></div></li>
        <li><div class="step-num">2</div><div><p class="step-title">Implement</p><p class="step-desc">Notes-as-you-go: each design decision / deviation / tradeoff / open question logged immediately.</p></div></li>
        <li><div class="step-num">3</div><div><p class="step-title">Verify &amp; fix</p><p class="step-desc">Manual verification against acceptance criteria in the spec. No P2E status to flip.</p></div></li>
        <li><div class="step-num">4</div><div><p class="step-title">Commit + PR</p><p class="step-desc">Commit + <code>gh pr create</code>. Branch may have no story-id (specs are not necessarily P2E-backed).</p></div></li>
        <li><div class="step-num">5</div><div><p class="step-title">/review-pr</p><p class="step-desc">Same as /p2e-work-on-next: pr-review-toolkit reviews the open PR.</p></div></li>
        <li><div class="step-num">6</div><div><p class="step-title">/p2e-cut-release</p><p class="step-desc">No story-id resolves → Phase E silently no-ops. Release still ships normally (push + PR + CI + merge + bump + tag + release).</p></div></li>
      </ol>
    </div>
  </div>
</div>

## Pros / cons / concessions

<div class="rich-doc" id="pros">
  <div class="callout callout-good">
    <p class="kicker">Pros</p>
    <p><strong>Visibility:</strong> one legible "where are we" board across long multi-story runs. <strong>Resumability:</strong> a crashed session leaves stories at a known step. <strong>Codification:</strong> the implicit "commit + PR + review" handshake becomes explicit. <strong>Convergence:</strong> the two commands share a mental model without forcing one persistence mechanism on both.</p>
  </div>
</div>

<div class="rich-doc" id="cons">
  <div class="callout callout-warn">
    <p class="kicker">Cons / concessions</p>
    <p><strong>Two persistence layers remain</strong> (story_log + implementation-notes.html) — accepted because forcing convergence is more expensive than the cost of reading both. <strong>Cross-platform asymmetry</strong> — Cursor has no task primitive, so we document a markdown-comment fallback rather than build one. <strong>Step 5 ≠ /ultrareview</strong> — that's user-triggered + billed; the auto-chain uses <code>/review-pr</code>. <strong>Wave verbosity</strong> — 5 stories × 6 steps = 30 tasks in the list, mitigated by the <code>[#41]</code> prefix grouping. <strong>Branch-naming discipline required</strong> — step 6's zero-flag closeout only works when branches are named <code>feat/&lt;STORY-ID&gt;-&lt;topic&gt;</code>; mismatched branches force an explicit <code>--story-id=</code> flag or a fall-through to the <code>AskUserQuestion</code> story-picker in <code>/p2e-cut-release</code>.</p>
  </div>
</div>

<div class="rich-doc" id="risks">
  <div class="callout callout-warn">
    <p class="kicker">Risks to flag</p>
    <p><strong>Editing <code>~/.claude/commands/implement-spec.md</code></strong> ships only to your Claude Code, not to Codex/Cursor users of the plugin. Option: mirror <code>/implement-spec</code> into the plugin so it gets the same three-platform treatment (a follow-up story, not blocking this work). <strong>Step 1 ("Brief &amp; confirm")</strong> risks becoming a no-op for trivial thick stories — codify it as an auditable formality, not a re-litigation gate. <strong>Step 4 must open the PR before step 5 fires</strong> — <code>/review-pr</code> targets an open PR; if step 4 hasn't pushed yet, step 5 has nothing to review. Workflow contract must enforce the ordering rather than relying on implementer judgment. <strong>Branch rename mid-flight</strong> — if the implementer renames the branch via <code>/update-branch-name</code> between steps 1 and 4, the new name must still carry the story-id, otherwise step 6's inference falls through to the picker.</p>
  </div>
</div>

## Implementation plan

<div class="rich-doc" id="plan">
  <details>
    <summary>4 steps · ~0.03 token-days total · ~300 LoC <span class="count">tap to expand</span></summary>
    <div class="details-body">
  <ol class="steps">
    <li>
      <div class="step-num">1</div>
      <div>
        <p class="step-title">Codify the ladder in <code>workflows/p2e-work-on-next.md</code></p>
        <p class="step-desc">Add a "Per-story task ladder" section: TaskCreate per step, TaskUpdate transitions, cross-platform fallback. Make steps 4 and 5 explicit. Step 6 = invoke <code>/p2e-cut-release</code> (already shipped) — workflow just needs to document the handoff and the branch-name convention dependency.</p>
        <p class="step-cost">~200 LoC · ~16K output tokens · ~0.02 token-day</p>
      </div>
    </li>
    <li>
      <div class="step-num">2</div>
      <div>
        <p class="step-title">Add ladder to <code>~/.claude/commands/implement-spec.md</code></p>
        <p class="step-desc">Same 6-step TaskCreate ladder. Step 6 still invokes <code>/p2e-cut-release</code> — when no story-id resolves (specs have no P2E story backing), Phase E silently no-ops, the release still ships. Keep <code>implementation-notes.html</code> exactly as-is.</p>
        <p class="step-cost">~50 LoC · ~4K output tokens · ~0.005 token-day</p>
      </div>
    </li>
    <li>
      <div class="step-num">3</div>
      <div>
        <p class="step-title">Wire step 5 to <code>pr-review-toolkit</code>'s <code>/review-pr</code></p>
        <p class="step-desc">Document the invocation contract in the workflow; specify how findings flow back into the implementer's next turn. Ordering contract: step 4 must complete (PR open) before step 5 fires.</p>
        <p class="step-cost">~30 LoC · ~3K output tokens · ~0.003 token-day</p>
      </div>
    </li>
    <li>
      <div class="step-num">4</div>
      <div>
        <p class="step-title">CHANGELOG entry (v0.10.5 candidate)</p>
        <p class="step-desc">Note the ladder addition and the new Cursor asymmetry. (v0.10.4 already shipped <code>/p2e-cut-release</code> — this work goes into the next bump.)</p>
        <p class="step-cost">~15 LoC · ~1K output tokens · ~0.001 token-day</p>
      </div>
    </li>
  </ol>
  <div class="total-card">
    <span class="total-label">Total</span>
    <span>~<strong>0.03 token-days</strong> (~$10, ~24K output tokens, ~300 LoC equivalent). Small change, low risk — all heavy lifting for step 6 already shipped in v0.10.4. Dogfooded through the existing <code>/p2e-work-on-next</code>.</span>
  </div>
    </div>
  </details>
</div>

## Deferred / out of scope

<div class="rich-doc" id="deferred">
  <details>
    <summary>6 items not shipping in v1 <span class="count">tap to expand</span></summary>
    <div class="details-body">
  <ul class="deferred-list">
    <li><span><strong>Mirroring <code>/implement-spec</code> into the plugin.</strong> Cross-platform parity for spec implementation is a follow-up story, not in this v1.</span></li>
    <li><span><strong>Unified persistence schema.</strong> No consumer needs it yet — re-evaluate when a tool wants to render both surfaces uniformly.</span></li>
    <li><span><strong>New <code>story_log</code> kinds for PR_OPEN / REVIEW_RESOLVED.</strong> TaskCreate already carries that signal; adding kinds is schema churn without payoff. <code>/p2e-cut-release</code> already writes a <code>VERIFICATION</code> entry on closeout, which is the durable "released" signal.</span></li>
    <li><span><strong><code>/ultrareview</code> auto-invocation.</strong> User-triggered + billed; stays opt-in. May add a "high-risk story" prompt in a later iteration.</span></li>
    <li><span><strong>Auto-invoke step 6 vs. human-gate it.</strong> Current proposal: orchestrator marks step 6 ready, invokes <code>/p2e-cut-release</code> which has its own <code>AskUserQuestion</code> release-plan gate (workflow step 8). Open question: should the orchestrator additionally require a turn boundary before invoking, or trust the cut-release plan-gate as sufficient? Default to trusting; revisit if it becomes a stumbling block.</span></li>
    <li><span><strong>Multi-story batch releases.</strong> When you genuinely want one release covering several stories, use <code>/p2e-ship-batch</code> (already shipped). Out of scope for this ladder, which is per-story by design.</span></li>
  </ul>
    </div>
  </details>
</div>

<div class="rich-doc" id="demo-script" style="display:none;">
<script>
(function() {
  if (window.__taskLadderDemoInit) return;
  window.__taskLadderDemoInit = true;
  var run = function() {
    document.querySelectorAll('.rich-doc .demo').forEach(function(demo) {
      if (demo.dataset.bound === '1') return;
      demo.dataset.bound = '1';
      var chips = demo.querySelectorAll('.step-chip');
      var log = demo.querySelector('[data-role="log"]');
      var progress = demo.querySelector('[data-role="progress"]');
      var advanceBtn = demo.querySelector('[data-action="advance"]');
      var resetBtn = demo.querySelector('[data-action="reset"]');
      var steps = [
        { tag: 'create', msg: 'TaskCreate("[#41] 1/6 Brief &amp; confirm") — story DR-08-L8 thick-gate passed' },
        { tag: 'update', msg: 'TaskUpdate(1, completed) → TaskCreate("[#41] 2/6 Implement") — spawning implementer' },
        { tag: 'log',    msg: 'story_log: kind=VERIFICATION — "Verified: bun test passed (28 tests)"' },
        { tag: 'update', msg: 'TaskUpdate(3, completed) → status: IN_REVIEW. git push + gh pr create → PR #142' },
        { tag: 'update', msg: '/review-pr → 2 minor findings (naming, test coverage). Addressed in commit abc1234.' },
        { tag: 'log',    msg: '/p2e-cut-release: inferred --story-id=DR-08-L8 from branch. Phase E: IN_REVIEW → DONE.' }
      ];
      var idx = 0;
      function render() {
        chips.forEach(function(c, i) {
          c.classList.toggle('done', i < idx);
          c.classList.toggle('active', i === idx);
        });
        if (progress) progress.textContent = idx + '/6 steps complete';
        if (advanceBtn) advanceBtn.disabled = idx >= steps.length;
      }
      function clearEmpty() {
        var empty = log.querySelector('.empty-hint');
        if (empty) empty.remove();
      }
      function append(tag, msg) {
        var t = new Date().toLocaleTimeString();
        var e = document.createElement('div');
        e.className = 'log-entry';
        e.innerHTML = '<span class="ts">' + t + '</span><span class="tag ' + tag + '">' + tag.toUpperCase() + '</span>' + msg;
        log.appendChild(e);
        log.scrollTop = log.scrollHeight;
      }
      advanceBtn && advanceBtn.addEventListener('click', function() {
        if (idx >= steps.length) return;
        clearEmpty();
        var s = steps[idx];
        append(s.tag, s.msg);
        idx++;
        render();
        if (idx === steps.length) {
          setTimeout(function() { append('log', 'Story DR-08-L8 closed → DONE. Ladder complete. v0.10.5 shipped.'); }, 250);
        }
      });
      resetBtn && resetBtn.addEventListener('click', function() {
        idx = 0; render();
        log.innerHTML = '<div class="log-entry empty-hint">Click "Advance" to see TaskCreate / TaskUpdate / story_log calls fire.</div>';
      });
      render();
    });
  };
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', run);
  } else {
    run();
  }
})();
</script>
</div>
