# Changelog

## v0.6.0 — 2026-04-17

Completes the v0.6 autonomy cluster by shipping `/p2e-update-story` (B-05-L11) and the `/p2e-bootstrap --mode={new,onboarding}` reshape (B-05-L12). With L13 already in place as v0.5.0, the L11 + L12 pair closes the loop: bootstrap drafts DRAFT stories for both greenfield and onboarding paths, update-story thickens them, and work-on-next gates on the thickness predicate at pickup.

### Added
- **`/p2e-update-story`** — new Codex-compatible triple (`commands/p2e-update-story.md`, `workflows/p2e-update-story.md`, `skills/p2e-update-story/SKILL.md`). Single command to thicken empty fields or steer populated ones on any existing story with the same preview/confirm UX as `/p2e-add-story`. Supports all Story fields including the P-07-L1 thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`). Rejects DRAFT→OPEN transitions when `isThick=false` and surfaces the concrete `failingClauses` so the user can decide whether to stay at DRAFT or thicken further. On promotion to OPEN, creates the GitHub issue with the `ready` label (or patches the existing issue body). Batched fail-fast MCP writes. `--dry-run` prints payloads without writing.
- **`--mode=onboarding`** in `workflows/p2e-bootstrap.md` — reads an existing repo via a shared brainstorming-style interview (2–4 batched questions in one turn) and parses `README` + `/docs` + route tree + test titles + recent commit history + open GitHub issues to propose phases and UXOs. Same accept/adjust preview matrix as `--mode=new`. Empty cells preferred over filler.
- **`--mode=new`** is now explicit and documented; it remains the default when `--mode` is omitted, preserving the current PRD-driven behavior verbatim.
- **`--backfill-built`** (onboarding only) — optional post-accept sub-step that scans merged PRs and proposes `DONE` layer stories with `INTRODUCES` capabilities inferred from PR titles + diff summaries. User accepts per-PR or skips the whole step.
- **`--all`** — fans per-UXO story drafting across every UXO in the matrix in one pass and renders ONE combined multi-select accept. All drafts are written as `DRAFT` status (post-P-07-L1); no GitHub issues created at draft time.
- **Validator coverage** in `scripts/validate-plugin.py` for the new update-story triple: checks its guardrails, preview/confirm/thicken/steer/thick-gate/GH reconciliation sections, and the `--fill` deprecation pointer in the add-story surfaces.

### Changed
- **`/p2e-add-story --fill`** is deprecated and now delegates to `/p2e-update-story` for one release. The legacy fill-mode shim does not implement its own preview or write path; it is a pointer only. Removal targeted for the follow-up release. `commands/p2e-add-story.md` and `workflows/p2e-add-story.md` document the shim; the router skill (`skills/p2e/SKILL.md`) points thickening / steering / renaming / re-parenting / retagging requests at `/p2e-update-story` directly.
- **Bootstrap behavior** now emits stories as `DRAFT` status regardless of mode; thickening and GitHub-issue creation are deferred to `/p2e-update-story`.
- **`.codex-plugin/plugin.json`** `defaultPrompt` gained an onboarding prompt ("Onboard this existing repo into P2E") and a thickening prompt ("Thicken this draft story").

### Notes
- Marketplace tagging now proceeds since the v0.6 cluster is complete (L11 + L12 + L13 + P-07-L1 all landed).
- `gh` auth against the onboarding repo is required if the interview requests GitHub-issue context in `--mode=onboarding`.

## v0.5.0 — 2026-04-16

Reshapes `/p2e-work-on-next` for autonomous Opus 4.7 execution by consuming lifecycle v2 (P-07-L1) and adding the thick-gate, first-turn briefing, two-strike escalation, shape-aware routing, and self-plan-inline path.

### Added
- **Thick-gate** in `workflows/p2e-policy.md`: orchestrator refuses any batch where `isThick=false` or `status!=OPEN` and directs the user to `/p2e-update-story`.
- **First-turn briefing template** at `workflows/p2e-first-turn-briefing.md`: structured Markdown block (Intent / Constraints / AC / Capabilities / Files hint / Context docs / Non-goals / Verification) materialized as the implementer's turn-1 input, mapped 1:1 to thick-spec fields from `mcp__p2e__stories op=get`. Pulls tag-mapped project invariants from `CLAUDE.md` into the Constraints section.
- **Two-strike escalation**: second verification failure flips story `status=BLOCKED` via MCP and routes to `p2e-architect` (Claude Code caller) or `codex:rescue` (Codex caller). No third retry. Escalation comments end with `— bchoor-claude`.
- **Shape-aware routing** in `workflows/p2e-policy.md`: `p2e-architect` and `superpowers:writing-plans` become opt-in on Standard/Architectural stories — triggered by `constraints: ['approach-review']` or the `--full-team` CLI flag. Staff engineer + wave-gate rules preserved verbatim.
- **Self-plan inline**: single-story thick runs with architect skipped have the implementer self-plan from the briefing, no external `writing-plans` call. TDD preserved when any capability has `isBreaking=true`.
- **Per-track verification matrix** in `workflows/p2e-policy.md`: Fast = typecheck + lint, Standard = `bun run preflight`, Architectural = preflight + `prisma validate`. Per-story `verificationCmd` overrides; tag-additive checks layer on top.
- **Persona-routing table** in `skills/p2e/SKILL.md` with a `Skip when` column documenting the shape-aware skips.

### Changed
- **Status lifecycle** rewritten across `workflows/p2e-policy.md` and `workflows/p2e-work-on-next.md` to v2 (`DRAFT → OPEN → IN_PROGRESS → IN_REVIEW → DONE` plus `BLOCKED`). The legacy `PLANNED → PARTIAL → BUILT` shim is removed.
- **`agents/p2e-architect.md`** description updated to reflect the opt-in trigger; body adds a `When the architect is skipped` note pointing at the self-plan-inline path. Inputs section adds the first-turn briefing as turn-1 input.
- **`agents/p2e-staff-engineer.md`** Inputs section adds the per-story first-turn briefing as turn-1 input (concatenated for the batch). Behavior unchanged — wave planning + file-collision detection still required for batch size ≥ 2.
- **Wrappers** (`skills/p2e-work-on-next/SKILL.md`, `skills/p2e/SKILL.md`, `commands/p2e-work-on-next.md`) load `workflows/p2e-first-turn-briefing.md`. `commands/p2e-work-on-next.md` documents the `--full-team` flag in the body.
- **README.md** lifecycle wording updated (PLANNED → DRAFT) for the add-story column.

### Notes
- Story-cluster context: this release ships the L13 piece of the v0.6 autonomy cluster. L11 (`/p2e-update-story`) and L12 (`/p2e-bootstrap --mode={new,onboarding}`) ship in subsequent releases. Marketplace tagging waits until the cluster is complete.

## v0.4.3 — 2026-04-16

Restores the explicit preview-and-confirm contract for `p2e-add-story`.

### Fixed
- **Codex add-story instructions** now explicitly stay in story-creation mode instead of drifting into troubleshooting behavior when a request describes a bug or regression.
- **Preview-before-write contract** restored: the user must see the inferred phase, tier, UXO, title, RRR, acceptance criteria, and capabilities before any story or GitHub issue is created.
- **Confirm gate** restored: add-story now requires explicit accept / adjust / abort behavior in the shared workflow contract.

### Changed
- **Plugin validator** now checks the add-story guardrails so this preview/review behavior cannot silently regress again.

## v0.4.2 — 2026-04-15

Fixes Codex OAuth discovery for the bundled P2E MCP server configuration.

### Fixed
- **Concrete default MCP URL** in `.mcp.json` for the bundled `p2e` server. This avoids Codex login/auth discovery failures caused by shell-style `${P2E_MCP_URL:-...}` URL syntax not being expanded in the MCP auth flow.
- **README wording** updated to describe `https://p2e-mocha.vercel.app/api/mcp` as the hosted production endpoint and to note the concrete-URL requirement for Codex MCP overrides.

## v0.4.1 — 2026-04-15

Adds lightweight CI for plugin invariants and packaging consistency.

### Added
- **GitHub Actions CI** via `.github/workflows/ci.yml`.
- **Repository validator** in `scripts/validate-plugin.py` that checks:
  - JSON manifest validity
  - required command, skill, and workflow file sets
  - Codex/Claude version consistency
  - wrapper-to-workflow references

### Notes
- CI is intentionally invariant-based rather than host-runtime-heavy. It validates plugin structure and packaging without trying to simulate Claude or Codex execution environments.

## v0.4.0 — 2026-04-15

Adds native Codex plugin support while aligning the Claude and Codex surfaces through shared workflow definitions.

### Added
- **Codex plugin packaging** via `.codex-plugin/plugin.json`.
- **Codex skills** for `p2e`, `p2e-bootstrap`, `p2e-add-story`, `p2e-work-on-next`, and `p2e-sync-labels`.
- **Shared workflow core** in `workflows/` so Claude and Codex wrappers point at the same behavior contract.

### Changed
- **Claude command surface renamed** from `/p2e-work-on-next-story` to `/p2e-work-on-next`.
- **Claude commands slimmed to wrappers** over the shared workflow core instead of carrying the only behavioral definition.
- **Shared orchestration prompts updated** so `p2e-architect` and `p2e-staff-engineer` can be invoked from either Claude command orchestration or Codex subagent orchestration.
- **README rewritten** for the dual Claude/Codex plugin surface and the new sync semantics.

### Notes
- `work-on-next` now owns the normal end-of-run label sync path when it has enough context to do so safely.
- `sync-labels` remains available as the explicit repair/reconcile workflow.

## v0.3.0 — 2026-04-14

Adds per-UXO story drafting from a PRD source, plus the downstream pieces (`--fill` mode on `/p2e-add-story`, thin-draft detection in `/p2e-work-on-next-story`).

### Added
- **`/p2e-bootstrap` "Draft stories for this UXO"** sub-option in the dive-deeper menu. Proposes 0–N title-only PLANNED stories per UXO, with a one-line justification per proposal citing the source passage. PRD-driven density (no force-fit), no GitHub issues at draft time.
- **`/p2e-add-story --fill <storyId>`** mode. Targets an existing PLANNED story and fills in RRR + AC + capabilities. Skips phase/tier/UXO inference (already known). Creates the GitHub issue at fill time.
- **Thin-draft detection in `/p2e-work-on-next-story`.** Before classifying a candidate, checks `acceptanceCriteria.length === 0 && capabilities.length === 0`. If true, prompts the user to flesh now / proceed as-is / skip.
- **Skill: "Thin drafts" section** in `skills/p2e/SKILL.md` documenting the heuristic and behavior.

### Changed
- `/p2e-add-story` Step 4 write path branches on create vs fill mode.

### Notes
- Open questions deferred for v1: source-passage citation fidelity, no-PRD case, bulk fill of multiple drafts at once.


## v0.2.2 — 2026-04-14

Skill hygiene pass — `skills/p2e/SKILL.md` no longer leaks internal project-roadmap references.

### Changed
- Dropped "Pending until P-07-L1 is BUILT" language from status transitions — reads as plain description now.
- Dropped the "Product → Projects (forward-looking)" subsection; referenced an unshipped internal story.
- Dropped references to `docs/P2E-lifecycle.md` and `docs/P2E-handover.md` (not present in the public plugin repo).
- Dropped "main P2E repo's CLAUDE.md core invariant #2" citation from the audit-trail section.
- Renamed "Planning recipe for external agents" → "Planning recipe" (the original framing assumed the reader was outside the project).


## v0.2.1 — 2026-04-14

Adds `/p2e-bootstrap` — turn a PRD, storyboard, or project description into a populated 2D story map (phases × tiers × UXOs) in one pass.

### Added
- **`/p2e-bootstrap`** command. Parses a source doc, asks 1–4 high-level clarifying questions via `AskUserQuestion`, drafts a full matrix, renders a grid for review, supports per-cell deep dives via `superpowers:brainstorming` or `gstack-office-hours`, writes all phases + UXOs in one batch. Does not create stories — that's `/p2e-add-story`'s job.

### Known limitations
- The P2E MCP surface has no `projects.create` op yet. `/p2e-bootstrap` requires the project shell to exist (create via P2E UI first).
- Only creates new phases/UXOs. Does not delete or rename existing ones (safe-by-default).


## v0.2.0 — 2026-04-14

Architectural cleanup. Commands and agents now call `mcp__p2e__*` tools directly via Claude Code's MCP client instead of shelling out to a bundled CLI. OAuth is handled automatically by Claude Code — no more `P2E_DEV_BEARER` setup.

### Changed
- **Dropped bearer token requirement.** `P2E_DEV_BEARER` is no longer needed. MCP auth uses Claude Code's OAuth flow.
- **Dropped bun dependency.** The plugin no longer ships TS code; `bun` is not required to run the commands.
- **Commands rewritten** to call `mcp__p2e__*` tools directly:
  - `/p2e-add-story` — uses `mcp__p2e__projects`, `mcp__p2e__stories`, `mcp__p2e__uxos`, `mcp__p2e__criteria`, `mcp__p2e__capabilities`.
  - `/p2e-work-on-next-story` — same, plus `mcp__p2e__relations` for dependency resolution.
- **Agents rewritten** (`p2e-architect`, `p2e-staff-engineer`) to fetch story detail via `mcp__p2e__stories`.
- **Skill slimmed.** Dropped the `Pre-flight: dev server check` section (irrelevant when hitting remote MCP). Router rules inlined into commands; SKILL.md keeps them as reference.
- **Classifier logic inlined.** The `classify()` router logic now lives inline in `/p2e-work-on-next-story` rather than as a TS helper.

### Removed
- `lib/` directory (7 files: `mcp.ts`, `mcp.test.ts`, `router.ts`, `router.test.ts`, `types.ts`, `cli/mcp-call.ts`, `cli/classify.ts`).
- `P2E_DEV_BEARER` env var requirement.
- Dev-server pre-flight check (`lsof -iTCP:3000` etc).

### Migration
If you upgrade from 0.1.x:
- Unset `P2E_DEV_BEARER` if you had it exported — no longer consulted.
- First `mcp__p2e__*` call triggers the Claude Code OAuth flow once; subsequent calls reuse the session.

## v0.1.4 — 2026-04-14

Bumped the marketplace entry version to 0.1.4 so `/plugin update` detects change vs cached 0.1.0. Includes all fixes from 0.1.1, 0.1.2, 0.1.3.

## v0.1.3 — 2026-04-14

Moved `skills/SKILL.md` into `skills/p2e/SKILL.md` for Claude Code's default skill discovery.

## v0.1.2 — 2026-04-14

Wrapped `.mcp.json` server definitions in `mcpServers` key (required by plugin loader).

## v0.1.1 — 2026-04-14

Added `.claude-plugin/marketplace.json` — plugins install through a marketplace catalog, not directly from repos.

## v0.1.0 — 2026-04-14

Initial public release. Extracted from bchoor/p2e monorepo (B-05-L1).
