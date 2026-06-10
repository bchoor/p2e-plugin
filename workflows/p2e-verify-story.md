# P2E Verify Story Workflow

This workflow verifies a P2E story's acceptance criteria by reproducing each one end-to-end against the running app, capturing visible-pixel evidence (or backend-only evidence for non-UI ACs), recording per-AC verdicts and evidence directly in the tracker, then optionally assembling a self-contained rich HTML report. The verdict for any UI-touching AC rests on a screenshot or visually-confirmable artifact — never on a synthetic `localStorage.getItem(...)` read or an `aria-checked` attribute alone.

The workflow serves two modes:

- **Standalone UAT** — invoked directly by the user or by `/p2e-ship-batch` Phase C. Presents a preview, requires explicit go-ahead, and produces a full HTML report.
- **Gate evidence engine** — invoked by the verify gate in `workflows/p2e-work-on-next.md` step 11a for UI-tagged stories. Skips the preview confirm (the gate has already committed to running), uploads screenshots via `mcp__p2e__story_assets op=upload criterion_id=<ac-cuid>`, records verdicts via `mcp__p2e__criteria op=verdict`, and produces an HTML report only when `--report` is passed.

The workflow combines the P2E plugin's MCP-first story sourcing with the cross-platform UAT pipeline (reproduce → capture → assemble → review → teardown). Primary output in gate-engine mode: tracker verdicts and scoped screenshot assets. Optional output: a single `.html` file plus per-AC evidence files, deposited under `docs/feat-<topic>/uat-results/` (preferred) or `.claude/uat-results/<story-id>/` (fallback).

## Hard rules

- Stay in verify-story mode. Do not silently switch into debugging or implementation just because an AC fails — failure is the deliverable, not a trigger to start patching. Recording a FAIL verdict in the tracker is the correct response.
- ALWAYS present the parsed story (title + RRR + ordered ACs + out-of-scope) back to the user and require an explicit go-ahead before driving any browser. Wrong-story-wrong-evidence is worse than no evidence.
- Visible pixels over JSON probes for any UI AC. State probes are useful to *reach* the visual state; the verdict comes from the picture.
- The report is **self-contained**: a single `.html` file with embedded CSS, relative-path image refs, no external CDN, no external `<script src=>`, no external `<link rel="stylesheet">`. A reviewer must be able to open it offline.
- Bind first. If `.p2e/project.json` is missing in a target repo, run `/p2e-bind` before any project-scoped MCP operation.
- If MCP auth or story lookup fails, stop and report the concrete blocker briefly. Do not switch into general debugging unless the user asks for debugging.
- Never trust "the server started" output alone. Verify the actually-bound port via `lsof` before driving the browser — a port-clash with another project's dev server routes requests to stale code.

## Purpose

- Reproduce each AC end-to-end and record a `PASS` / `FAIL` / `BLOCKED` verdict with concrete evidence (screenshot path or curl-output ref) directly in the tracker via `mcp__p2e__criteria op=verdict`.
- Upload per-AC screenshot evidence via `mcp__p2e__story_assets op=upload criterion_id=<ac-cuid>` so the detail panel and map badge reflect UAT state.
- Optionally assemble a human-digestible HTML report (`--report` flag or standalone mode).
- Use the same shape regardless of host platform — Claude Code, Codex, and Cursor all invoke the same workflow with the same outputs.
- Make the failure mode of "reading PASS from a synthetic probe alone" structurally impossible by requiring a screenshot or curl-output artifact for every verdict.

## Preconditions

- The target project must exist and be bound (`.p2e/project.json` present) for `story_id`-driven invocations. If unbound, run `/p2e-bind` first.
- For UI ACs, a browser-driver MCP must be available (`mcp__chrome-devtools__*` preferred — richer screenshot / snapshot ops — or `mcp__claude-in-chrome__*` as fallback). For backend-only ACs, curl is sufficient.
- The target repo must build and run locally. The workflow does not bootstrap a new dev environment; it assumes `package.json` (or equivalent) scripts exist for the dev server.

## Workflow

### Phase 1 — Gather the story

Sources, in this strict precedence:

1. **P2E MCP (default)** — if the input matches a P2E story id pattern (`DR-08-L8`, `P-01-L3`, `A-04-L7`), call `mcp__p2e__stories op=get project_slug=<from .p2e/project.json> story_id=<id>` to retrieve the canonical record. The response supplies:
   - `story.title` — report header
   - `story.storyAs` / `story.storyWant` / `story.storySoThat` — RRR (Role / Request / Rationale, in that exact order)
   - `story.acceptanceCriteria[]` — `{ id, text, checked, order }` array; use `order` for the report index
   - `story.background` — optional Background paragraph
   - `story.constraints[]`, `story.nonGoals[]` — drive the "What was NOT verified" section
   - `story.filesHint[]`, `story.specFile` — scope context for the report header and the "What was verified" framing
2. **Spec file** — if the user gives a path under `docs/feat-<topic>/spec.md`, read the YAML frontmatter (`title`) and parse `## Background`, `## User story` (the `As ..., I want ..., so that ...` sentence), and `## Acceptance criteria` (numbered or bulleted list — accept both).
3. **GitHub issue** — `gh issue view <num> --repo <owner>/<repo> --json title,body,number` and parse the body using the same shape as the spec.
4. **User-supplied free-form text** — ask for title, RRR, and the ACs as a numbered list, then echo the parsed structure back.

Always present a brief preview before the browser starts (canonical preview format in `skills/p2e-verify-story/references/gathering-acs.md`). On Claude Code, use the host's prompt primitive (`AskUserQuestion`) to confirm; on Codex / Cursor use the host's native prompt and parse the reply inline.

If the input doesn't match a P2E story id pattern AND the user gave no spec / issue / text, default to Source 4 and ask for the story details.

### Phase 2 — Bring the app up reliably

The harness reaps background tasks across turn boundaries; ports collide between projects. Both failures look identical to a reviewer (a broken UAT report) but the root causes differ. Use the `scripts/start-dev-detached.sh` helper bundled at `skills/p2e-verify-story/scripts/start-dev-detached.sh`:

- Reads `package.json` to discover dev-server invocation (walks **down** up to 3 directory levels for monorepo layouts like `apps/web/` or `packages/foo/`). If multiple candidates exist (a polyrepo / multi-workspace tree), the script refuses with the candidate list and asks for `--workspace-dir <path>` rather than silently picking one.
- Launches via `nohup ... & disown` so the process survives turn boundaries (the harness no longer tracks it).
- Writes PID files to `.claude/verify-story-pids/` for clean teardown.
- Polls `lsof -iTCP:<port> -sTCP:LISTEN` to confirm the listener.
- Echoes the actually-bound app URL (which is what the browser must hit).

For pre-staged state (a docs root, an opened file, a user identity), prefer POSTing to an internal `/api/set-*` endpoint, or seed `localStorage` via `evaluate_script` before page load. The browser's file-picker and other user-gesture-only APIs cannot be driven from MCP — document those as `What was NOT verified` if they can't be pre-staged. Full patterns in `skills/p2e-verify-story/references/dev-server-setup.md` (including the port-clash mitigation pattern that prevents the `feedback_uat_verify_running_code` failure mode).

### Phase 3 — Reproduce each AC

For each acceptance criterion in `order`:

1. **Set up state** — get the app into the precondition (file open, mode selected, user logged in).
2. **Perform the action** — click, type, hover, reload — via the browser-driver MCP.
3. **Capture visible evidence** — `take_screenshot` for any UI-visible AC. For backend-only ACs, capture curl output into a `.txt` file.
4. **Probe state for completeness** — `evaluate_script` to read store / localStorage / network logs as *supporting* evidence (not the verdict).
5. **Record verdict in the tracker** — call `mcp__p2e__criteria op=verdict` with `id=<ac-cuid>`, `verdict=PASS|FAIL|BLOCKED`, and `note=<screenshot path or curl output ref>`. In gate-engine mode this is mandatory per AC; in standalone mode it is performed unless `--no-tracker` is passed. `CAVEAT` is not a tracker verdict — map it to `PASS` with a note (caveat is informational, shipping acceptable) or `BLOCKED` (caveat gates shipping).

After recording the verdict, if a screenshot was saved: call `mcp__p2e__story_assets op=upload` with `story_id=<story-id>`, `filename=<NN-ac-slug.png>`, `content_type=image/png`, `data_base64=<base64>`, `caption=<one-line description>`, and `criterion_id=<ac-cuid>` to scope the asset to the criterion. Use `items:[{...}]` form per policy.

Store screenshots at `<artifacts-dir>/<NN>-<ac-slug>.png`. The two-digit prefix preserves order; the slug helps a reviewer scan filenames.

Common gotchas — full recipes in `skills/p2e-verify-story/references/browser-driver-recipes.md`:

- **CSS `:hover` submenus** — JS `.dispatchEvent(new MouseEvent("mouseenter"))` does NOT trigger `:hover`. Use the MCP's real `hover` tool with a UID from `take_snapshot`.
- **React-controlled inputs** — `input.value = "x"` does not fire React's onChange. Use `Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set.call(input, "x")` + `dispatchEvent(new Event("input", {bubbles: true}))`.
- **Auto-dismissing toasts** — inject a CSS pin (`opacity: 1 !important; transform: none !important; transition: none !important; animation: none !important;`) BEFORE the action that triggers the toast, so the toast div stays painted long enough for `take_screenshot`. The four properties together cover fade-out, slide-out, transition timers, and keyframe animations — partial pins fail when the dismiss animates via a property the pin doesn't override.
- **Large snapshots** — `take_snapshot` returns the a11y tree; for large apps it overflows the response. Pass `filePath` then `grep` for UIDs.

### Phase 4 — Assemble the report

Use the bundled template at `skills/p2e-verify-story/assets/template.html` as the skeleton. It is a single-file rich doc scoped under `.rich-doc` with theme tokens (green = PASS, red = FAIL, amber = BLOCKED, gray = NOT_TESTED), a summary grid at the top (one card per AC with a PASS / FAIL / BLOCKED / NOT_TESTED pill), per-AC sections (header with verdict pill, **Expected** vs **Observed** two-column block, evidence figure with optional 2-up before / after grid), and an overall assessment section. **Note:** the bundled `template.html` still uses legacy `CAVEAT` styling — when regenerating the template, replace `yellow = caveat` with `amber = BLOCKED` and remove the `caveat callout` component; the live verdict enum is `PASS | FAIL | BLOCKED | NOT_TESTED` (no CAVEAT).

Permitted interactivity (per `feedback_html_doc_interactivity_scope`): `<details>` / `<summary>` for collapsible sections (pre-flight notes, raw curl), `<a href="#section-id">` anchor nav, CSS-only tabs via `<input type="radio">` + sibling selector, inline `<script>` (no external `src`) for richer interactivity. Default to single linear scroll; reach for tabs only when comparing 2–4 variants that share shape (before / after, alternative implementations).

Forbidden in the report (would break offline viewing or iframe-embedded rendering): `position: sticky` / `position: fixed`, external CDNs, external `<script src=>`, external `<link rel="stylesheet">`, references to files outside the artifacts dir, in-doc TOC duplicating the renderer's outline.

Save to `<artifacts-dir>/results.html`. Then take a full-page rendering via the browser-driver MCP (`take_screenshot fullPage=true`) and save as `00-report-preview.png` — useful as an at-a-glance image when the HTML cannot be rendered (e.g. pasted into a GH issue body). Full component patterns + theme tokens in `skills/p2e-verify-story/references/report-template.md`.

### Phase 5 — Open for human review

Open `results.html` in a new browser tab via the browser-driver MCP (`new_page` with `file://` URL) so the user can review immediately. Surface the file path + per-AC verdict counts in the final message.

If any AC failed, the verdict pill in the summary card AND in the per-AC section both show `FAIL`. The overall assessment block must explicitly call out the failure(s) and recommend next steps (file the regression, revert the implementation, etc.).

In **gate-engine mode** the workflow writes verdicts and uploads assets before the HTML report is assembled — the tracker is the primary output. In **standalone mode** the workflow writes verdicts and assets too (unless `--no-tracker` was passed) — the HTML report is the secondary output for human review. The workflow does NOT update `story.status` or move the story along the lifecycle; that is the gate's responsibility (step 11d in `workflows/p2e-work-on-next.md`).

### Phase 6 — Teardown

When the user accepts the result (or closes out), run the bundled teardown script `skills/p2e-verify-story/scripts/stop-dev.sh` to kill the detached dev processes via the PID file. Leave the artifacts dir on disk — it's the deliverable.

## Output location

Default precedence for the artifacts dir:

1. **`--artifacts-dir <path>`** — explicit override from the user. Always wins.
2. **`docs/feat-<topic>/uat-results/`** — if a `docs/feat-*/` folder already exists for the story (look up via `story.specFile` from the MCP response, or match by story-id slug). Ships with the code and is reachable by humans browsing the repo — preferable when the project commits its specs.
3. **`.claude/uat-results/<story-id>/`** — repo-neutral fallback when no feature folder exists. Stays out of the way; check the project's `.gitignore` before assuming it won't be committed.

Structure under whichever dir is chosen:

```
<artifacts-dir>/
├── 00-report-preview.png       # full-page screenshot of results.html
├── 01-<ac-slug>.png
├── 02-<ac-slug>.png
├── ...
├── NN-curl-evidence.txt        # for any backend-only ACs
└── results.html                # the report
```

When using option 3, surface the path in the final message so the user knows where to find the artifacts.

## Required preview contents

Before any browser action, the preview must show at least:

- **Story id** + **title** + **source** (`P2E MCP` | spec file path | GH issue # | user-supplied)
- **User story (RRR)** — `As <role>, I want <request>, so that <rationale>.`
- **Background** paragraph (if supplied by the story)
- **ACs to verify** — numbered list, verbatim text from `acceptanceCriteria[i].text` in `order`
- **Out-of-scope** — bullet list from `nonGoals[]` and `constraints[]` (will appear in the report's "What was NOT verified" section)
- **Artifacts dir** — the path that will be created
- **Browser-driver MCP** — `chrome-devtools` or `claude-in-chrome` (the one that will be used)
- **Dev-server command** — the resolved `package.json` script (so the user can override if the wrong workspace was detected; the launcher script accepts `--workspace-dir <path>` to pin the workspace explicitly)

## Required confirm step

The confirm step must support, via the host's native prompt primitive:

- **Proceed with verification** — runs Phases 2–6 unchanged
- **Adjust ACs** — edit the parsed AC list before running (e.g. drop an AC that's out of scope for this run, fix an obvious typo in the parsed text)
- **Change artifacts dir** — override the auto-detected path
- **Abort** — exit with no changes

Only `Proceed` advances into the browser flow. `Abort` exits without bringing the app up.

## Flags

| Flag | Applies to | Effect |
| --- | --- | --- |
| `--gate-engine` | Gate orchestrator | Skip preview confirm; verdicts + assets mandatory; HTML report skipped unless `--report` also passed |
| `--report` | Both modes | Force HTML report assembly (Phases 4–5). Always-on in standalone mode; opt-in in gate-engine mode |
| `--no-tracker` | Standalone mode only | Skip `criteria op=verdict` and `story_assets op=upload` writes. For dry-run / read-only UAT audits that must not mutate the tracker |
| `--artifacts-dir <path>` | Both modes | Override the auto-detected artifacts directory |
| `--workspace-dir <path>` | Both modes | Pin the monorepo workspace dir for the dev-server launcher |

## Gate-engine invocation

When invoked by the verify gate (`workflows/p2e-work-on-next.md` step 11a), the workflow is called programmatically with `--gate-engine` flag (or equivalent signal from the gate orchestrator). In this mode:

- Skip the Phase 1 preview-and-confirm step (the gate orchestrator has already committed).
- Run Phases 2–3 as normal.
- Upload screenshots per Phase 3 step 5 above.
- Record verdicts per Phase 3 step 5 above.
- Skip Phase 4 (report assembly) unless `--report` is also passed.
- Skip Phase 5 (open for human review) unless `--report` is also passed.
- Run Phase 6 (teardown) as normal.
- Return verdict summary to the gate orchestrator so it can decide pass/fail.

The `CAVEAT` result code is retired in gate-engine mode. Map old CAVEAT results: acceptable-to-ship → `PASS` with note; blocking → `BLOCKED`.

## Triggering examples (concrete)

Invoke when the user says one of:

- `verify P-01-L3` — fetch from P2E MCP, reproduce all ACs
- `verify the story in docs/feat-foo/spec.md` — parse the spec, reproduce its ACs
- `run UAT on issue #91` — fetch from GH, parse the issue body
- `produce a UAT report for the feature I just shipped` — ask for the story details, then proceed
- `do a visual UAT of A-04-L7` — same as `verify`, with stronger emphasis on screenshot evidence

Do NOT invoke for:

- `run the tests` → use `bun test` / `npm test`
- `check if my code compiles` → use `tsc --noEmit`
- `review my PR` → use the pr-review-toolkit
- Pure backend correctness checks where the AC reads "GET /api/foo returns 200" and no UI is involved — invocation is fine, but the workflow will capture curl output instead of screenshots; if there's no need for the rich HTML report, the user may be better served by a one-shot curl.

## Companion workflows + skills

- **`/p2e-bind`** — required precondition for `story_id` invocations. Writes `.p2e/project.json` so MCP knows which project to query.
- **`/p2e-update-story`** — when verification surfaces a missing AC or RRR drift, route the user to update the story before re-running this workflow.
- **`writing-rich-docs`** — companion skill. The verify-story report template uses the same `.rich-doc`-scoped style tokens; if the project commits its specs, the report visually matches the surrounding feature folder.

## Platform asymmetries

- **Hooks** (Claude Code only) — none required for this workflow; the bundled scripts handle detachment and teardown, so no `PreToolUse` gate is needed.
- **Prompt primitive** — Claude Code uses `AskUserQuestion`; Codex uses its native prompt; Cursor batches the question into a chat message. The preview-and-confirm gate is mandatory on all three.
- **Browser-driver MCP availability** — `chrome-devtools` is preferred (richer ops, stable UID model). If only `claude-in-chrome` is connected, fall back to it; the recipes in `references/browser-driver-recipes.md` cover both. If neither is connected, stop with a concrete blocker message — do not attempt to verify UI ACs blind.

## Pointers

- `workflows/p2e-policy.md` — shared MCP / status / escalation rules
- `skills/p2e-verify-story/references/gathering-acs.md` — Phase 1 sourcing + preview format
- `skills/p2e-verify-story/references/dev-server-setup.md` — Phase 2 detached launch + port-clash mitigation + pre-staging
- `skills/p2e-verify-story/references/browser-driver-recipes.md` — Phase 3 MCP-driving patterns (hover, React inputs, toast pinning, snapshots, screenshots, scrolling, reload)
- `skills/p2e-verify-story/references/report-template.md` — Phase 4 component patterns + theme tokens + validation checklist
- `skills/p2e-verify-story/scripts/start-dev-detached.sh` — detached dev-server launcher
- `skills/p2e-verify-story/scripts/stop-dev.sh` — teardown by PID file
- `skills/p2e-verify-story/assets/template.html` — single-file rich-doc skeleton
