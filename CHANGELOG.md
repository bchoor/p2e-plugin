# Changelog

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
