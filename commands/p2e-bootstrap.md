---
name: p2e-bootstrap
description: Bootstrap a new P2E project's 2D story-map (phases × tiers × UXOs) from a PRD, storyboard, or high-level project description. Asks 1–4 clarifying questions, renders the full matrix for review, lets you dive deep into any cell via superpowers:brainstorming, then writes the full structure in one batch.
argument-hint: <doc-path or inline description> [project=<slug>] [--dry-run]
---

# /p2e-bootstrap

Turn a free-form product description into a fully-structured P2E story-map in one pass. Designed for the moment you're starting a new project and want the journey, phases, and UXOs drafted before your first story.

## Invocation

```
/p2e-bootstrap <path/to/prd.md>
/p2e-bootstrap "A task manager for solo founders who..."
/p2e-bootstrap <doc> project=my-slug
/p2e-bootstrap <doc> --dry-run
```

If invoked with no argument, ask ONCE via `AskUserQuestion` ("Paste or reference your product description") with a free-text "Other" option.

## Constraint

This command **does not create projects** — the P2E MCP surface has no `projects.create` tool yet. Create the project shell in the P2E UI first (or via SQL seed), then run this command to populate phases + UXOs.

## Pre-flight

1. Parse named arguments: `project=<slug>` (defaults to `p2e`), `--dry-run`.
2. Resolve the source:
   - If the first positional argument ends in `.md` / `.txt` / `.pdf` and exists, read it via `Read`.
   - Otherwise treat the full quoted argument as an inline description.
3. Verify the target project exists: call `mcp__p2e__projects` with `{ op: "get", project_slug: "<slug>" }`. If it 404s, stop and tell the user to create the project in the UI first — print a link to the hosted P2E instance.
4. Cache `ctx.phases` to detect whether the project already has a journey drafted; if it does, prefer **append** semantics (ask before overwriting) rather than a blank-slate bootstrap.

## Step 1. Parse the source

Extract the following signals from the text. Do not over-structure; capture what's actually stated, flag what's implied.

- **Product vision** — one-sentence elevator pitch.
- **Primary persona(s)** — who the product is for. Note secondary personas if the doc has them.
- **User journey** — the rough sequence of stages the primary persona moves through (e.g. "Discover → Sign up → Onboard → Use daily → Invite team → Export").
- **Outcomes per stage** — what the user wants to achieve at each step.
- **Quality ambitions** — any signals that the product needs to be "excellent at X" (differentiation → ADVANCED/STRETCH tier fodder).
- **Constraints** — compliance, performance, platform, timing.

## Step 2. Clarifying questions (1–4, via AskUserQuestion — only if genuinely ambiguous)

Only ask when you can't confidently infer. Never ask more than 4 questions total.

Common candidates (choose the ones that actually apply):

- **Primary persona** — if the doc lists multiple, which one should be the journey lens?
- **Tier ambition** — does this bootstrap populate CORE only (MVP map), or also ADVANCED / STRETCH (full map)?
- **Phase granularity** — "Looks like 4–6 phases. Prefer broader (4) or more granular (6–8)?"
- **Append vs fresh** — if the project already has a draft journey: "Merge into the existing map, or replace?"

Prefer defaults + a single combined question over a dialogue. If the doc is specific enough, skip questions entirely.

## Step 3. Draft the 2D matrix

Produce, in memory:

### Journey metadata
- `title` — short noun phrase summarizing the journey (e.g. "Ship a product").
- `persona` — the chosen primary persona.
- `description` — optional, the elevator pitch from the doc.

### Phases (columns)
For each phase:
- `title` — action verb + noun (e.g. "Discover", "Acquire", "Activate").
- `subtitle` — one-liner describing the user's goal in that step.
- `color` — cycle through `#4f46e5`, `#22c55e`, `#f59e0b`, `#ef4444`, `#06b6d4`, `#a855f7`, `#f97316`, `#10b981`.

### UXOs per (phase × tier) cell
For each cell, propose 0–3 UXOs. A cell can be empty — better than inventing filler.

- `uxoId` — next free letter(s) in the phase's group (e.g. Discover=D, Acquire=A; scan existing to avoid collisions). Format `<letter>-<n>`.
- `title` — concrete feature objective (≤ 40 chars). NOT a benefit. Think "Email signup flow" not "users can join easily".
- `description` — one-sentence clarifier; optional.
- `tier`:
  - `CORE` — without this, the phase doesn't work.
  - `ADVANCED` — raises quality once CORE ships.
  - `STRETCH` — aspirational / differentiating.

Density guidance:
- CORE rows: 1–3 UXOs per phase (the baseline must-haves).
- ADVANCED rows: 0–2 UXOs per phase (quality improvements).
- STRETCH rows: 0–1 UXOs per phase (differentiators); leave most empty unless the doc has clear stretch signals.

## Step 4. Render the synthesized view

```
╭─ Bootstrap preview — project=<slug> ─────────────────────────────────────
│
│ Journey:   <title>
│ Persona:   <persona>
│ Pitch:     <description>
│
│ Matrix (phase × tier → UXOs):
│
│   Phase        | CORE                       | ADVANCED                   | STRETCH
│   -------------|----------------------------|----------------------------|------------
│   Discover     | D-01 Landing page          | D-02 SEO content           | —
│   Acquire      | A-01 Email signup          | A-02 OAuth providers       | A-03 SSO
│   Activate     | C-01 Onboarding flow       | C-02 Guided tour           | —
│   ...          | ...                        | ...                        | ...
│
│ Totals: <N_phases> phases, <N_uxos> UXOs (<core_count> CORE / <advanced_count> ADVANCED / <stretch_count> STRETCH)
│
│ This is a starting skeleton — stories/capabilities come later via /p2e-add-story.
╰──────────────────────────────────────────────────────────────────────────
```

## Step 5. Feedback loop (AskUserQuestion)

```
What next?
  1. Accept and write (Recommended)
  2. Adjust a phase (title / subtitle / position)
  3. Adjust a cell (add / rename / remove a UXO)
  4. Dive deeper on a phase or UXO
  5. Regenerate from a different angle
  6. Abort
```

- **Adjust a phase** — prompt for which phase, then free-text new title/subtitle. Re-render.
- **Adjust a cell** — prompt for phase + tier, then free-text the new UXO list (one per line, format `<id>? <title>` — auto-assign id if omitted).
- **Dive deeper** — this is the force-multiplier. Prompt for the target (phase X or UXO Y), then sub-options:
  - **Brainstorming** — invoke `superpowers:brainstorming` with the focus narrowed to that slice, passing the parsed source doc + the current matrix draft as context. When brainstorming returns, fold its recommendations into the draft (phase refinement, new UXOs, removed UXOs).
  - **Open-ended exploration** — invoke `gstack-office-hours` in builder mode for more open-ended exploration.
  - **Draft stories for this UXO** — see "Per-UXO story drafting" section below. Proposes 0–N title-only PLANNED stories under the chosen UXO.
  Re-render the matrix after the sub-option returns.
- **Regenerate** — prompt "What angle? (shift persona / reframe journey / prioritize different axis)" and redo Steps 1–4 with that framing. The original parse is retained so you don't re-read the source.

Loop until user picks Accept or Abort.

Under `--dry-run`, render the preview + the exact `mcp__p2e__phases` and `mcp__p2e__uxos` batch payloads that would be written, then exit. No AskUserQuestion, no writes.

## Step 6. Write (single batch)

On Accept:

1. **Append or replace check.** If `ctx.phases` was non-empty and the user didn't explicitly choose "replace", treat every phase whose title matches an existing phase as `skip` (don't recreate). For UXOs targeting an existing phase, check for existing uxoIds under that phase and skip duplicates. Report skips in the final summary.

2. **Create phases.** Call `mcp__p2e__phases` with `{ op: "create", project_slug, items: [{ title, subtitle, color }, ...] }`. Capture the returned `phase_id` per title.

3. **Create UXOs.** Call `mcp__p2e__uxos` with `{ op: "create", project_slug, items: [{ phase_title, uxo_id, title, tier, description }, ...] }`. Use `phase_title` (not `phase_id`) so the server resolves the phase by title within the project — lets us batch across phases in one call.

4. **Fail-fast behavior.** If Step 2 partially succeeds and Step 3 fails, surface which UXOs weren't written. User can retry just Step 3 with the same args. Don't auto-rollback created phases.

## Per-UXO story drafting

Invoked from Step 5's "Dive deeper" sub-menu when the user picks "Draft stories for this UXO". Drafts are **title-only** — no RRR, no AC, no capabilities, no GitHub issue. Density is PRD-driven: propose only what the source actually motivates. A UXO can legitimately get 0 drafts if the source is thin on that cell.

### Flow

1. **Scope source context.** Re-read the section(s) of the source doc relevant to the chosen UXO. Anchor on the UXO's `title` and its phase. If no source doc was provided to bootstrap (inline-description mode), use what the user originally pasted.

2. **Propose 0–N story titles.** For each proposed title, capture a one-line **justification** citing the source passage that motivated it. If the source doesn't motivate any titles, propose 0 — do NOT pad. Surface "no draft stories proposed for `<uxoId>` — source is thin on this cell" and return to the bootstrap loop.

3. **Render the proposal.**

   ```
   ╭─ Draft stories for B-04 — REST API ──────────────────────
   │
   │  ☐ 1. Public read endpoints (stories, projects, UXOs)
   │       Justification: PRD §3.2 mentions read-only public access
   │       for embedded dashboards.
   │
   │  ☐ 2. Webhook subscriptions for story state changes
   │       Justification: PRD §4.1 calls out integration with
   │       customer Slack workflows.
   │
   │  Justifications cite source passages so you can verify before accepting.
   ╰──────────────────────────────────────────────────────────
   ```

4. **Per-story accept/reject** via `AskUserQuestion` with `multiSelect: true`. User picks which titles to keep.

5. **Write accepted titles** as PLANNED stories under the UXO. Call `mcp__p2e__stories` with `{ op: "create", project_slug, items: [{ story_id: "<uxoId>", uxo_id: "<resolvedUxoId>", title, status: "PLANNED", release }] }` for each accepted title (the server auto-appends `-L<n+1>`). Inherited fields:
   - `status`: `PLANNED`
   - `release`: inherited from the bootstrap run's release default (or the project's most-recent PLANNED release)
   - All other fields empty: no `story_as`, no `story_want`, no `story_so_that`, no tags
   - **No GH issue** is created at this step. Drafts stay off the tracker until they're fleshed via `/p2e-add-story --fill`.

6. **Return to the bootstrap feedback loop.** User can dive into another UXO or accept the matrix.

### Invariants

- **Title-only.** Never invent AC or capabilities at draft time. That's where hallucination risk lives.
- **No force-fit.** Density is PRD-driven; 0 is a valid count.
- **No GH issues** for drafts. Issue creation is deferred to `/p2e-add-story --fill`.
- **One-shot per invocation.** The user can re-invoke per UXO; this command does not maintain "what was proposed last time" state across invocations.

## Step 7. Final summary

```
✓ Bootstrap complete — project=<slug>
───────────────────────────────────────────────────
Journey:   <title>
Created:   <N_phases> phases, <N_uxos> UXOs
Skipped:   <M_phases> already existed, <M_uxos> already existed
URL:       <P2E_UI_URL>/<slug>

Next steps:
  → /p2e-add-story for each story you want to ship under a UXO
  → /p2e-work-on-next-story when you have a PLANNED queue worth working through
```

## Deep-dive integration (what the "dive deeper" option orchestrates)

When the user asks to dive deeper on a phase or UXO, Claude loads the appropriate companion skill with focused context. The intent is to make bootstrap the *gateway* to deeper design work, not a dead-end skeleton.

- `superpowers:brainstorming` — best when the user wants to explore requirements, personas, edge cases, or the design space of a specific cell. Pass the parsed PRD + matrix draft + focus-slice as context.
- `gstack-office-hours` (builder mode) — best when the user wants open-ended product exploration ("is this even the right wedge?"). Good for pre-coding concept work.
- `superpowers:writing-plans` — best when a specific UXO is already concrete enough to warrant a plan-level breakdown (e.g. "Email signup flow" needs auth provider decisions).

After any deep-dive returns, always return to Step 4 (render synthesized view) with the folded-in results. Never exit from within a sub-skill — the bootstrap flow owns the top-level loop.

## Scope notes

- **What this command does NOT do:** create stories, AC, or capabilities. Those are per-UXO work for `/p2e-add-story`. Keep bootstrap at the *structural* level — phases and UXOs only.
- **What this command does NOT touch:** existing BUILT or PARTIAL stories under existing UXOs. Only creates new phases and new UXOs. Destructive ops (delete / rename) are out of scope for v1.
- **Deliberately forgiving:** empty cells are fine. Better to ship a sparse honest map than fill every cell with filler.
