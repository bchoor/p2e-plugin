# Changelog

## v0.7.2 — 2026-04-19

### Fixed
- **`.claude-plugin/plugin.json`** now declares `version`, so Claude Code / Claude Desktop can detect newer plugin releases and surface update notifications. Previously only `marketplace.json` carried the version, which the host doesn't read for installed-plugin version comparison.

## v0.7.1 — 2026-04-19

Rolls up four plugin-side changes that land on top of v0.7.0: a new `/p2e-sync` drift-reconciliation command, smarter UXO placement in the drafter, a story-log checkpoint policy doc, and an MCP tool surface section in the README. Plugin-side only; all paired backend work ships in `bchoor/p2e`.

### Added
- **`/p2e-sync <story_id>`** (#18, B-05-L4) — user-invoked on-demand drift reconciliation between a P2E story and its linked GitHub issue body. Renders a field-level diff (title, RRR, background, AC text, capabilities, release) and reconciles one direction via `AskUserQuestion`: `Update GH from story` / `Update story from GH` / `Cherry-pick per-field` (Claude host only) / `Abort`. `--dry-run` renders the diff without writing. Template parser asserts the `<!-- p2e-sync:start v1 -->` fence and aborts with a diagnostic on pre-fence bodies. Ships `workflows/p2e-sync.md`, `commands/p2e-sync.md`, `skills/p2e-sync/SKILL.md`, `scripts/parse-gh-issue-body.sh`, router update in `skills/p2e/SKILL.md`, and `validate_sync_contract()` in the validator.
- **UXO placement matching via `objectives[]`** (#19, A-03-L4) — `/p2e-add-story` scores UXO placement on `title + objective + objectives[]` (falls back to `title + objective` when `objectives[]` is empty, preserving pre-A-03-L4 behavior). Preview renders a `UXO match reason:` line when the phase+tier cell has multiple UXOs. `/p2e-update-story` re-evaluates placement on Move UXO or thicken with the same signal, annotated in the preview.
- **Story log checkpoint policy** (#17, P-07-L7) — `workflows/p2e-work-on-next.md` documents the four defined checkpoints (wave-start, AC toggle, verification failure + BLOCKED, IN_REVIEW transition), the exact entry shapes written via `mcp__p2e__story_log op=append`, the `items:[{...}]` call form, and the append-only contract. Pairs with `bchoor/p2e#209`.
- **MCP tool surface section in README** (#20, B-01-L10) — enumerates every MCP tool the plugin exposes with a one-line summary per op, plus an inline multi-value `stories.list` example showing `statuses`, `releases` (with `null`), `tags` + `tag_mode`.

### Changed
- **`.claude-plugin/marketplace.json`** + **`.codex-plugin/plugin.json`** versions bumped to `0.7.1`.

### Notes
- No breaking changes; no schema or MCP surface changes plugin-side.
- `/p2e-sync` end-to-end requires the widened `formatIssueBody` template to have landed in `bchoor/p2e` (B-05-L4 parent PR). Pre-fence bodies abort cleanly with a diagnostic pointing at `/p2e-update-story`.
- UXO `objectives[]` matching requires `bchoor/p2e#238` (ships the `Uxo.objectives String[]` column + MCP + UxoForm editor).

### Prior unreleased — B-05-L4 (rolled into v0.7.1)

Adds `/p2e-sync <story_id>` — on-demand drift reconciliation between a P2E story and its linked GitHub issue body. Widens `formatIssueBody` (src/lib/github.ts) to include background, capabilities, and release sections with a `<!-- p2e-sync:start v1 -->` fence so the body is machine-parseable in both directions.

#### Added
- **`/p2e-sync <story_id>`** — user-invoked command (no polling, no webhook, no git-hook) that fetches both the P2E story via MCP `stories.get` and the linked GH issue body via `gh api`, computes a field-level diff (title, RRR, background, AC text, capabilities, release), and presents one confirm step: `Update GH from story` / `Update story from GH` / `Cherry-pick per-field` / `Abort`. Cherry-pick mode is Claude-host-only. Writes AuditLog rows via MCP on every mutation; posts a GH comment summarizing direction + fields after each reconcile. `--dry-run` renders the diff without writing.
- **`workflows/p2e-sync.md`** — canonical workflow describing fetch-both, diff render, four direction paths, AC and capability reconciliation semantics, template-mismatch abort diagnostic, and dry-run behavior.
- **`commands/p2e-sync.md`** — thin Claude command wrapper with `argument-hint: <story_id>`.
- **`skills/p2e-sync/SKILL.md`** — thin Codex skill wrapper; Codex exposes only A/B/D (no cherry-pick).
- **`scripts/parse-gh-issue-body.sh`** — shell wrapper that fetches a GH issue body via `gh api` and pipes it through the TypeScript `parseIssueBody` parser via bun. Passes `bash -n` syntax check.
- **Widened `formatIssueBody`** (`src/lib/github.ts`) — adds `## Background`, `## Capabilities` (one line per capability: `- <name> (<action>[, breaking]): <description>`), and `## Release` sections, plus `<!-- p2e-sync:start v1 -->` / `<!-- p2e-sync:end v1 -->` fence. Signature extended with optional `background?`, `capabilities?`, `release?` fields — all callers remain backward-compatible (optional fields default to absent).
- **`parseIssueBody`** (`src/lib/github.ts`) — new pure function that is the exact inverse of `formatIssueBody`. Throws with a precise diagnostic if the sync fence is missing (pre-B-05-L4 bodies or hand-edited bodies that dropped the fence). Exported as `ParsedIssueBody` + `IssueBodyCapability` types.
- **`createGithubIssueForStory`** (`src/lib/actions/github.ts`) — updated to include `capabilities` in the Prisma query and pass them mapped to `IssueBodyCapability` into the widened `formatIssueBody`.
- **Validator coverage** in `scripts/validate-plugin.py` — added `p2e-sync.md` to all expected sets (commands, workflows, skills), added `commands/p2e-sync.md` and `skills/p2e-sync/SKILL.md` to `workflow_map`, added `workflows/p2e-sync.md` to the router check, and added `validate_sync_contract()` asserting the four directions, `gh issue edit`, AuditLog, user-invoked, fence reference, `AskUserQuestion`, and Codex cherry-pick limitation.
- **Round-trip test** (`tests/lib/github-body.test.ts`) — 10 vitest unit tests covering `formatIssueBody` → `parseIssueBody` for all fields, backward-compat minimal story, and fence-missing diagnostics. All pass.

#### Changed
- **`skills/p2e/SKILL.md`** (router) — added routing rule for drift reconciliation requests → `workflows/p2e-sync.md`.

#### Notes
- No version bump — lands under the post-v0.7.0 unreleased block. The user has an explicit memory "Never cut a release without explicit approval."
- `python3 scripts/validate-plugin.py` passes. `bash -n scripts/parse-gh-issue-body.sh` passes. `bunx tsc --noEmit` passes. `bunx vitest run tests/lib/github-body.test.ts` — 10/10 pass.

## v0.7.0 — 2026-04-18

Adds opt-in `--thick` mode to `/p2e-add-story` and wires a bounded brainstorming escalation into both `/p2e-add-story --thick` and `/p2e-update-story` thicken. Additive; the default `/p2e-add-story` invocation and every existing `/p2e-update-story` path are unchanged.

### Added
- **`/p2e-add-story --thick`** — new opt-in flag that populates ALL thick-spec fields at add time (the same six fields `/p2e-update-story` thicken populates: `filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`), runs the sizing inference heuristic against the staged projection per `workflows/p2e-sizing-rubric.md`, and renders the annotated preview with provenance labels on every field. Thin mode (the default) is unchanged.
- **Sizing inference at add time (thick mode only)** — the drafter runs the rubric's inference inputs (title + capabilities + AC count + tags + `files_hint` length) and annotates the proposed tier `derived-from-source: <evidence>` instead of the thin-mode `defaulted-M`. The user may still override the inferred tier in the confirm step's **Adjust sizing** action.
- **Brainstorming escalation** in both `/p2e-add-story --thick` and `/p2e-update-story` thicken — when the source signal is insufficient to credibly fill ≥ 2 thick-spec fields, the wrapper invokes the host brainstorming primitive (`superpowers:brainstorming` on Claude; Codex's native equivalent) to batch 2–4 concrete questions in a single turn. Answers fold back into the staged draft before preview re-render, annotated `derived-from-brainstorming`. Single round per flow; never bypasses the preview/confirm gate. Empty cells are still preferred over filler when answers leave gaps.
- **`--thick`-mode confirm step extensions in `workflows/p2e-add-story.md`** — the confirm step now supports adjusting any of the six thick-spec fields inline, with the override annotated `steered-by-user` in the re-rendered preview.
- **New `Draft a thick P2E story from this feature idea` entry** in the Codex `defaultPrompt` list (`.codex-plugin/plugin.json`).
- **Validator coverage** in `scripts/validate-plugin.py` (`validate_thick_mode_contract`) asserting the new `--thick`, `## Modes`, `## Brainstorming escalation`, and `derived-from-brainstorming` phrases exist on the expected surfaces (both workflows, both commands, both skills).

### Changed
- **`workflows/p2e-add-story.md`** — adds `## Modes`, augments the `## Workflow` steps to branch on thick vs thin, extends `## Required preview contents` and `## Required confirm step` for the six thick-spec fields and the `derived-from-brainstorming` provenance label, rewrites `## Sizing rules` to cover both modes, and adds `## Brainstorming escalation` with explicit escalation-trigger + fold-back rules.
- **`workflows/p2e-update-story.md`** — adds `## Brainstorming escalation` with the same shared contract, and extends the sizing-row provenance set with `derived-from-brainstorming`.
- **`commands/p2e-add-story.md`** — argument hint adds `[--thick]`; body describes thin vs thick mode + the brainstorming escalation.
- **`commands/p2e-update-story.md`** — body adds a `Brainstorming escalation` paragraph pointing at the workflow contract.
- **`skills/p2e-add-story/SKILL.md`** + **`skills/p2e-update-story/SKILL.md`** — hard-rule blocks cover the thick-mode inference path and the bounded brainstorming escalation.
- **`.claude-plugin/marketplace.json`** + **`.codex-plugin/plugin.json`** versions bumped to `0.7.0`.

### Notes
- No breaking changes. The default `/p2e-add-story <description>` invocation stays thin; `--thick` is purely opt-in.
- Brainstorming escalation is bounded to one round per flow and only fires when ≥ 2 thick-spec fields would otherwise land empty. It never bypasses the preview/confirm gate. The Claude wrapper resolves the reference against `superpowers:brainstorming`; the Codex wrapper resolves it against its native brainstorming primitive (the same pattern already used by `workflows/p2e-bootstrap.md --mode=onboarding`).
- `python3 scripts/validate-plugin.py` passes.

## v0.6.4 — 2026-04-17

Implements B-05-L17 — the plugin-side layer of the sizing enum shipped by P-07-L6. Adds a canonical 6-tier agent-centric sizing rubric and surfaces sizing in the `/p2e-add-story` + `/p2e-update-story` preview/confirm flows. Doc + prompt work only; no schema or MCP changes.

### Added
- **`workflows/p2e-sizing-rubric.md`** — canonical 6-tier rubric (XS → XXL) with agent-centric complexity + review-cost criteria, weighting rules (FE/redesign bumped higher, backend with `verificationCmd` bumped lower), inference inputs for the thicken path, and a concrete example per tier. M is the default.
- **Sizing row in `/p2e-add-story` preview** — every new story renders with `sizing: M` annotated `defaulted`; the confirm step's new **Adjust sizing** action overrides to any of `XS | S | M | L | XL | XXL` before the `mcp__p2e__stories op=create` write.
- **Sizing inference on `/p2e-update-story` thicken path** — re-infers a proposed tier from the staged title + capabilities + AC count + tags + `files_hint` length per the rubric, annotated `derived-from-source: <evidence>` with the inputs cited inline. The write body includes `sizing` when the staged value differs from the current value.
- **Steer override for sizing** — the confirm step's **Adjust sizing** (equivalent to steering the `sizing` field) overrides the inferred or populated value unconditionally, annotated `steered-by-user` in the re-rendered preview.
- **Sizing contract check in `scripts/validate-plugin.py`** — asserts the rubric tiers + weighting rules exist, and that every surface (both workflows, both commands, both skills) references `workflows/p2e-sizing-rubric.md` rather than inlining the rubric.

### Changed
- **`workflows/p2e-add-story.md`** — `Required preview contents`, `Required confirm step`, and new `Sizing rules` section added.
- **`workflows/p2e-update-story.md`** — `Required preview contents`, `Required confirm step`, new `Sizing inference` subsection under `Thicken rules`, sizing-specific paragraph under `Steer rules`, `Write behavior` phase 1 includes `sizing`, and the `Dry-run behavior` section explicitly covers the sizing row's provenance rendering.
- **`commands/p2e-add-story.md`** + **`commands/p2e-update-story.md`** — each surfaces a `Preview rendering (sizing)` section pointing at the rubric.
- **`skills/p2e-add-story/SKILL.md`** + **`skills/p2e-update-story/SKILL.md`** — read-list extended with `workflows/p2e-sizing-rubric.md`; hard rules clarify the default-M-at-add / infer-on-thicken / user-override semantics.
- **`.claude-plugin/marketplace.json`** + **`.codex-plugin/plugin.json`** versions bumped to `0.6.4` (patch release on top of v0.6.3 — the prior `0.7.0` manifest value was never tagged or released, so the realigned release line continues from v0.6.3).

### Notes
- Implements B-05-L17. Refs bchoor/p2e#184.
- Consumes the `Story.sizing` enum shipped by P-07-L6 (DONE); DEPENDS_ON relation already exists in the graph.
- No breaking changes; fully additive to the existing `/p2e-add-story` and `/p2e-update-story` contracts.
- `python3 scripts/validate-plugin.py` passes.

## v0.6.3 — 2026-04-17

Rewrites the user-facing `description:` frontmatter on every `/p2e-*` slash command so the Claude Code command menu surfaces what each command does and hints at its most relevant flag(s). Wrappers stay thin — only the human-facing `description:` fields change; no workflow, routing, or MCP behavior is touched. `argument-hint:` remains authoritative for full argument shape.

### Changed
- `commands/p2e-add-story.md` — description rewritten to cover draft creation with preview/confirm gate.
- `commands/p2e-bootstrap.md` — description covers both `--mode=new` and `--mode=onboarding`.
- `commands/p2e-sync-labels.md` — description covers the explicit reconcile path.
- `commands/p2e-update-story.md` — description covers thicken/steer/rename/move/retag/release/AC+cap + lifecycle label sync.
- `commands/p2e-work-on-next.md` — description covers queue selection + router + wave plan + `--full-team`.

### Notes
- Implements B-05-L16. Refs bchoor/p2e#181. Closes bchoor/p2e-plugin#12.
- `python3 scripts/validate-plugin.py` passes.

## v0.6.2 — 2026-04-17

Patch release on top of v0.6.0. Implements B-05-L15: lifecycle-aware `/p2e-update-story` label reconciliation and the `PreToolUse` implementer status gate. No breaking changes; fully additive behavior.

### Added
- **Lifecycle label reconciliation in `/p2e-update-story`** (`workflows/p2e-update-story.md`): every lifecycle-boundary status transition (OPEN→IN_PROGRESS, IN_PROGRESS→IN_REVIEW, IN_REVIEW→DONE, any→BLOCKED) now runs a 3-phase fail-fast write: (1) MCP `stories.update`, (2) `scripts/sync-github-label.sh` to flip the GitHub label, (3) local cache refresh at `~/.cache/p2e/<slug>/<story_id>.json`. Non-lifecycle updates (thicken/steer/rename/move/retag/release/AC/capabilities diff) are unchanged.
- **`scripts/sync-github-label.sh`** — POSIX bash helper that calls `gh issue edit --add-label / --remove-label` using the 5-entry label map (OPEN=ready, IN_PROGRESS=in-progress, IN_REVIEW=review, DONE=done, BLOCKED=blocked). Idempotent; "label not found on repo" exits 0 with a stderr warning rather than failing the overall update.
- **`hooks/pre-agent-spawn-story-status.sh`** — Claude Code `PreToolUse` hook that fires on every `Agent` tool call. Extracts P2E story id from the agent prompt via the regex `[A-Z]{1,2}-[0-9]+(-L[0-9]+)?`, checks status via 30-second TTL local cache or MCP HTTP (2-second timeout), blocks (exit 1) if status ∉ {IN_PROGRESS, IN_REVIEW}. Fails closed when MCP is unreachable. Short-circuits on `P2E_SKIP_STATUS_GATE=1` and on `subagent_type` ∈ {p2e-architect, p2e-staff-engineer, rescue}.
- **`hooks/hooks.json`** — Claude Code hook registration for the `PreToolUse` / `Agent` event, pointing at `pre-agent-spawn-story-status.sh` with a 5-second timeout.

### Changed
- **`workflows/p2e-work-on-next.md` step 9** split into 9a (move to IN_PROGRESS via `/p2e-update-story`), 9b (materialize briefing), 9c (spawn implementer). Added a note that the PreToolUse hook enforces step 9a independently.
- **`.codex-plugin/plugin.json`** version bumped to `0.6.3`.
- **`.claude-plugin/marketplace.json`** version bumped to `0.6.3` (after consolidating v0.6.1 docs + v0.6.2 feature + v0.6.3 docs-rewrite entries).

### Notes
- The hook is Claude Code-only. Codex does not implement `PreToolUse` hooks; the `.codex-plugin/plugin.json` is unchanged and the asymmetry is documented in README.
- The `bun run preflight` `verificationCmd` applies to downstream consumer repos, not this markdown+shell plugin repo. Plugin-level verification: `python3 scripts/validate-plugin.py` + `bash -n` syntax checks on the new scripts.

## v0.6.1 — 2026-04-17

Ships `docs/architecture-explorer.html` — a self-contained, single-file interactive 3D playground that visualizes every command / skill / workflow / hook / agent / script / MCP tool / external service in the plugin, plus the edges between them.

### Added
- **`docs/architecture-explorer.html`** — hand-rolled SVG projection (no external deps). Six use-case presets (add-story, thicken, work-on-next, bootstrap, sync-labels, PreToolUse hook flow) plus a cross-workflow "draft-to-shipped lifecycle" view that exposes the workflow-to-workflow handoff edges. Controls: drag to orbit, shift+drag to pan, wheel / + / - to scale, click a node to focus end-to-end, H to toggle zen mode.

### Notes
- Docs-only. No code or workflow changes. Derived from an audit of the workflow markdown so the edge set (MCP calls, handoffs, external `superpowers:*` skill invocations) reflects the shipped behavior rather than guessed relationships.

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
