# Changelog

## v0.12.2 — 2026-08-27

Removes bundled subagents from the plugin install surface. The Coder→Verifier→Auditor→Human review pipeline remains documented in `p2e-mode` as roles — hosts execute them inline, not via shipped agent definition files.

### Removed
- **`agents/`** — `p2e-story-lead`, `p2e-verifier`, `p2e-auditor`, `p2e-architect`, `p2e-staff-engineer`, and `CONTRACTS.md` moved to `docs/archive/agents/`.
- Subagent sections from README, `p2e-mode`, `p2e-policy.mdc`, AGENTS.md, and CLAUDE.md.

### Changed
- **`scripts/validate-plugin.py`** — asserts `agents/` is absent at repo root.
- Manifests bumped to **0.12.2**; `.cursor-plugin` drops `agents` key.

## v0.12.1 — 2026-08-27

Documentation reconciliation for the v0.12 p2e-mode-only architecture. No behavior changes to the skill or MCP surface.

### Added
- **`agents/CONTRACTS.md`** — reference-only orchestration contracts salvaged from pre-v0.12 workflows (briefing schema, skill matrix, review tiering, verify gate, checkpoint policy). Subagents point here instead of deleted `workflows/` paths.
- **`docs/archive/`** — pre-v0.12 historical feature docs moved from `docs/feat-*` and `docs/superpowers/`.
- **`scripts/validate-plugin.py`** — stale-reference guard: fails if `workflows/`, `commands/p2e-`, or active `/p2e-bind` references appear outside allowlisted historical/archive files.

### Changed
- **`README.md`** — rewritten for p2e-mode-only: install, bind, MCP table, Flow model, documentation map. Removed legacy command table and workflow descriptions.
- **`AGENTS.md`**, **`CLAUDE.md`** — aligned with single-skill architecture; contributor conventions updated.
- **`agents/p2e-story-lead.md`**, **`p2e-architect.md`**, **`p2e-staff-engineer.md`** — references updated to `agents/CONTRACTS.md`; trigger phrasing no longer cites removed slash commands.
- **`reference/`** — cross-platform pattern marked historical; cursor-skills-rules updated for p2e-mode-only layout.
- **`.cursor-plugin/plugin.json`** — bumped to 0.12.1, p2e-mode-only description, removed `commands` key.
- **`hooks/*.sh`** — binding repair messages no longer reference `/p2e-bind`.
- **`skills/p2e-mode/SKILL.md`** — added Foundation phase immutability invariant.

### Removed
- Stale Unreleased CHANGELOG entries describing pre-v0.12 install surfaces.

## v0.12.0 — 2026-08-27

**Breaking:** Consolidates all P2E guidance into a single **`p2e-mode`** skill. Legacy `/p2e-*` slash commands, granular workflow skills, and the entire `workflows/` tree are removed.

### Added
- **`skills/p2e-mode/SKILL.md`** and **`.cursor/skills/p2e-mode/SKILL.md`** — sole entry point: entity model, MCP surface, story lifecycle, Coder→Verifier→Auditor→Human review pipeline.
- **`agents/p2e-verifier.md`** — verifier subagent: tests, evidence, `criteria op=propose role=VERIFIER`.
- **`agents/p2e-auditor.md`** — auditor subagent: blind review, `criteria op=propose role=AUDITOR`.

### Removed
- All **`commands/p2e-*.md`** slash commands.
- All granular **`skills/p2e-*`**, **`skills/p2e/`**, and **`skills/writing-rich-docs/`**.
- Entire **`workflows/`** directory (policy, add-story, work-on-next, verify-story, etc.).

### Changed
- **`scripts/validate-plugin.py`** — validates p2e-mode-only layout; no wrapper/workflow contract checks.
- **`scripts/install-p2e-cursor-skills.sh`** — links `p2e-mode` + policy rule only; no `workflows/` symlink.
- **`.cursor/rules/p2e-policy.mdc`** — references p2e-mode as entry point; deprecates `/p2e-*` menu.
- Plugin manifests bumped to **0.12.0**.

Product repos should use in-repo **`p2e-mode`** (via `.cursor/sync-external-plugins.sh` or vendored copy) and read product docs (`docs/P2E-lifecycle.md`, `docs/P2E-handover.md`, `docs/feat-review-view/design.md`).

## v0.11.3 — 2026-08-27

Adds the **ac-evidence-proof/v1** contract — a generalizable, MCP-validated format for per-AC verification evidence (test runs, HTTP proofs, line references). Agents generate proof markdown via `mcp__p2e__evidence`, validate before upload, and attach via `story_assets`. Consumed by the P2E evidence digest viewer.

### Added
- **`workflows/p2e-ac-evidence-proof.md`** — canonical contract doc: required sections, agent flow, offline validation.
- **`specs/ac-evidence-proof.v1.yaml`** — machine-readable schema summary.
- **`templates/ac-proof.v1.md`** — starter template for `ac{N}-proof.md`.
- **`scripts/validate-ac-evidence-proof.ts`** — offline validator (`bun scripts/validate-ac-evidence-proof.ts ac1-proof.md`).

### Changed
- **`workflows/p2e-verify-story.md`** — Phase 3 step 6: upload structured proof markdown for backend/test ACs using the new contract (screenshot TOKEN-CARRY path unchanged).
- **`workflows/p2e-policy.md`** — verify gate references `mcp__p2e__evidence op=validate_proof` before story_assets upload.

Requires P2E MCP with the `evidence` tool (validate_proof + template ops).

## v0.11.2 — 2026-06-13

### Removed
- **`hooks/pre-agent-spawn-story-status.sh`** + its `PreToolUse` / `Agent` registration in `hooks/hooks.json` — the implementer status-gate hook is **removed**. It had two defects that cannot be fixed inside a hook: (1) its only P2E-detection was a regex matching any `[A-Z]{1,2}-[0-9]+` token, so it false-blocked unrelated agents (e.g. a data label `EB-2`) in any repo; (2) it verified status with an unauthenticated `curl` to the OAuth-gated MCP, which always failed → fail-closed → blocked every spawn. No hook-readable MCP credential exists, so the gate could not function from a hook subprocess. Status discipline is now self-enforced by `/p2e-work-on-next` Phase 2a (the `OPEN → IN_PROGRESS` flip before story-lead spawn) on every platform — the same self-enforced model Codex and Cursor already relied on. The now-vestigial `~/.cache/p2e/<slug>/<story_id>.json` cache-refresh step (only the hook read it) is dropped from `/p2e-update-story`. References updated across README, CLAUDE.md, `reference/`, and the affected workflows/skills.

## v0.11.1 — 2026-06-11

### Added
- **`workflows/p2e-thicken.md`** — new single-source thicken recipe (A-03-L6). Consolidates context-gathering (`stories op=context` primary + `op=get include=[relations,siblings]` + `relations op=stack` fallback), thick-spec field-population source-priority order, sizing inference (five-input block, `effortHint` mapping), signal-annotation rules for execution-time routing, and the brainstorming trigger pointer. Referenced by both `p2e-add-story.md` and `p2e-update-story.md`; removes duplicated thicken prose from both.
- **`## Draft-time skill-consult table`** in `workflows/p2e-policy.md` — pre-draft consult table cross-referenced with the execution-time `## Adaptive skill matrix`: `ui` signal → `frontend-design` lens shapes AC/constraints; ambiguity (≥ 2 unfillable thick fields) → `superpowers:brainstorming`; ≥ 3 capabilities or multi-directory `filesHint` → `feature-dev` explore pass. Consult mode only — no full skill runs at draft time.

### Changed
- **`workflows/p2e-add-story.md`** — **thick is now the default drafting mode; `--thin` opts out** to fast placeholder capture. Inline thick-spec drafting rules and sizing-inference prose replaced with pointers to `workflows/p2e-thicken.md`. Bootstrap batch flows stay thin (explicit `--thin`).
- **`workflows/p2e-update-story.md`** — `## Thicken rules` body replaced with pointer to `workflows/p2e-thicken.md`; `### Sizing inference` sub-section replaced with pointer. Section headings preserved so existing cross-references stay valid.
- **`workflows/p2e-bootstrap.md`** — explicit note that batch drafting is thin by design and that bootstrap flows pass `--thin` when invoking add-story.
- **All add-story + update-story wrappers** (`commands/p2e-add-story.md`, `commands/p2e-update-story.md`, `skills/p2e-add-story/SKILL.md`, `skills/p2e-update-story/SKILL.md`, `.cursor/skills/p2e-add-story/SKILL.md`, `.cursor/skills/p2e-update-story/SKILL.md`) updated: thick-default + `--thin` wording for add-story; `workflows/p2e-thicken.md` added to read lists; context-gathering note for update-story.
- **`skills/p2e/SKILL.md`** and **`.cursor/skills/p2e/SKILL.md`** router lines for add-story updated to reflect thick default.
- **README.md** — add-story command-table row updated to show `--thin` opt-out and thick-default description.

## v0.11.0 — 2026-06-11

Minor release: /p2e-work-on-next v2 supervisor architecture (P-07-L15, #39).

### Changed
- **`/p2e-work-on-next` v2 — supervisor architecture.** Replaces the 6-step TaskCreate ladder (v0.10.5) with: parallel `p2e-story-lead` subagent waves (nested workers, depth ≤ 5), dynamic-Workflow batch mode at N ≥ 4 (`--workflow`), one TaskCreate per story, adaptive skill matrix (`frontend-design` / `feature-dev` / `systematic-debugging` / TDD by story signals), track-tiered single-primary reviews (Fast / S/XS → `/code-review` pre-PR; Standard/Architectural/Schema/Auth → `pr-review-toolkit:review-pr` post-PR; conditional `/security-review` for Schema/Auth), and **no in-loop release** — stories end at `IN_REVIEW`, `/p2e-cut-release` is user-triggered. New `limit=N` arg. New agent `agents/p2e-story-lead.md`. Policy gains `## Adaptive skill matrix`; v2 model roles merged into existing `## Model routing` (the `## Model ladder` section introduced in this story is retired — all role definitions, including supervisor, story-lead, and implementer workers, now live in `## Model routing`); `## Review tiering` rewritten to define the tool mapping for the verify gate rather than a parallel review system. Codex/Cursor run a documented sequential fallback. Story-lead runs the full verify gate (verificationCmd + consumer-impact sweep + adaptive fix loop per P-07-L9 policy) inside its lifecycle; supervisor records `op=verdict` + DEVIATIONS + IN_REVIEW flip in Phase 3.

## v0.10.8 — 2026-06-11

Patch release: mandates TOKEN-CARRY DISCIPLINE for Vercel Blob uploads (HMAC-signed `client_token` must never be inlined in a shell command — write JSON to temp file, run `upload-asset.sh`). Ships the bundled helper `skills/p2e-verify-story/scripts/upload-asset.sh` that reads token/url/pathname from the ticket file and executes the verified 5-header PUT. Supersedes the P-07-L13 recipe; docs-only otherwise.

### Changed
- **Token-carry discipline (P-07-L14, #38)** — `## Screenshot evidence upload` in `workflows/p2e-policy.md` gains the `TOKEN-CARRY DISCIPLINE` sub-block: write `op=upload_url` JSON verbatim to temp file; run `upload-asset.sh` to PUT (token never in a shell string). Trailing-slash warning added (`/?pathname=…` required). Base64 `op=upload` marked NOT supported for new uploads (B-01-L15 removes it server-side). New helper script `skills/p2e-verify-story/scripts/upload-asset.sh`.

## v0.10.7 — 2026-06-11

Patch release: the `p2e-verify-story` evidence engine and the `work-on-next` / `ship-batch` gates now upload UAT screenshots via the signed-URL path (`story_assets op=upload_url`) instead of base64 `op=upload`. Base64 truncates files >~25KB through the model — the exact failure B-01-L14 fixed app-side — corrupting 100KB–900KB screenshots into black/grey blobs. Docs-only; no new workflow surface.

### Changed
- **Signed-URL evidence upload (P-07-L13, #37)** — single-sourced the `op=upload_url` recipe in `workflows/p2e-policy.md` (`## Screenshot evidence upload`): mint a token, then the browser/evidence subagent PUTs bytes directly to Vercel Blob so file bytes never enter the orchestrator/model context (cross-ref P-07-L12). All 5 reference sites (`p2e-verify-story.md`, `p2e-work-on-next.md`, `p2e-ship-batch.md`, and both `p2e-verify-story/SKILL.md` mirrors) now point at it, and the README MCP-surface `story_assets` row lists `upload_url` + `link`. Base64 `op=upload` retained as a documented <~25KB legacy fallback.

## v0.10.6 — 2026-06-10

Patch release packaging three changes that landed on `main` after `v0.10.5`: the converged verify gate, single-source recipe consolidation, and the `github_pr_url` doc note. No new workflow surface; refinements to existing verify/review behavior and docs.

### Added
- **Converged verify gate (P-07-L9, #34)** — risk-tiered review (Schema/Auth/Standard/UI/S-XS classes), per-AC UAT verdicts via `mcp__p2e__criteria op=verdict`, `verify-story` as the evidence engine, the consumer-impact sweep, the adaptive in-gate fix loop, and the model-routing table — all codified in `workflows/p2e-policy.md`.

### Changed
- **Recipe consolidation (P-07-L10, #35)** — duplicated recipe text across workflows folded into single-source sections referenced by pointer, removing drift between copies.
- **`github_pr_url` documentation (B-02-L5, #36)** — README/MCP-surface note documenting `github_pr_url` on `stories op=update`.

## v0.10.5 — 2026-05-24

Adds a shared 6-step task ladder (TaskCreate-backed) to `workflows/p2e-work-on-next.md`, providing live per-story progress tracking across multi-story implementation waves. Codifies two previously-implicit gaps in the workflow (step 4: `git commit` + `gh pr create`; step 5: `pr-review-toolkit /review-pr` invocation) and wires step 6 to the already-shipped `/p2e-cut-release` (v0.10.4). Also documents the same ladder structure for the global `/implement-spec` command (not shipped via this plugin) as a documented asymmetry.

### Added
- **6-step TaskCreate ladder in `workflows/p2e-work-on-next.md`** — steps: (1) Brief & confirm, (2) Implement, (3) Verify & fix, (4) Commit + PR (`git commit` + `gh pr create` on `feat/<STORY-ID>-<topic>`), (5) `/review-pr` (`pr-review-toolkit:review-pr`, NOT `/ultrareview`), (6) `/p2e-cut-release` — branch name auto-infers `--story-id` via the `[A-Z]+-[0-9]+-L[0-9]+` regex, same as v0.10.4's story-closeout logic. Each step maps to a TaskCreate task; statuses move `pending → in_progress → completed` (or `blocked`) in real time (refs: bchoor/p2e#294).
- **Codification of steps 4–5** — `git commit` + PR creation and `pr-review-toolkit /review-pr` invocation were previously implicit (done but untracked); they now have explicit TaskCreate entries and an ordering contract (step 4 must complete before step 5 fires), closing the gap where multi-story waves lost visibility between Verify and Release.
- **Cross-platform fallback** — Cursor (no task primitive) uses per-step `kind: NOTE` story-log entries as the progress surface; documented in the workflow body and added to the "Known platform asymmetries" table in project `CLAUDE.md`.
- **`/implement-spec` ladder** (documented asymmetry, not plugin-shipped) — the global `~/.claude/commands/implement-spec.md` gains the same 6-step ladder structure locally; behavior is identical but the command is outside the plugin's install surface and therefore not cross-platform compliant.

### Changed
- **`workflows/p2e-work-on-next.md`** — ladder section added after the existing Phase B implementation block; no existing behavior removed.

## v0.10.4 — 2026-05-23

Adds `/p2e-cut-release` — replaces the previous global `~/.claude/commands/cut-release.md`. Two distinct things are different from the old command, neither cosmetic.

**1. Authoritative version detection.** The old command read the current version from `package.json` in the worktree and computed "last tag" via `git describe --tags --abbrev=0`. Both sources are local-worktree-relative: a branch made off an older tag produces a stale read of both, and the proposed bump clashes with an already-released tag. Reproduced against this repo: `git describe --tags --abbrev=0 v0.10.1` returns `v0.10.1` even though `v0.10.3` is the actual head of the tag chain — patch-bump from that returns `v0.10.2`, which would fail at `git tag` or silently overwrite history. The new Phase 0 replaces both reads: `git fetch --tags --prune --prune-tags origin` first, then `git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -1` (tag-namespace authoritative, not HEAD-bounded), then a manifest cross-check against a source-of-truth list (`.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `marketplace.json`, `package.json`, `Cargo.toml`, `pyproject.toml`, `__version__.py`, `VERSION`) — the manifest *informs* but does not *drive* the bump. A `git rev-parse --verify "refs/tags/v<next>"` sanity check after computing `<next>` aborts on tag-existence conflicts before any push.

**2. Optional story closeout.** When `--story-id=<id>` is passed or unambiguously inferred from the current branch (regex `[A-Z]+-[0-9]+-L[0-9]+`, e.g. `feat/DR-08-L8-folder-walk-progress` → `DR-08-L8`), the workflow closes the story out on successful release: status `IN_REVIEW → DONE`, a `kind: VERIFICATION` story-log entry, a landed-on-main comment on the linked GitHub issue, and a `review → done` label flip. The status flip is a deliberate policy carve-out — see the new `## Status lifecycle → Cut-release carve-out` section in `workflows/p2e-policy.md`. The pre-flight `AskUserQuestion` plan-approval gate IS the human-authorization equivalent, so the spirit of the "IN_REVIEW → DONE is a human action" rule is preserved. Gating is strict: if the story isn't at `IN_REVIEW` at closeout time, no status write happens; the workflow surfaces the skip via a `kind: NOTE` story-log entry and the release still ships. Branch-name inference falls back to `AskUserQuestion` (a picker over the project's `IN_REVIEW` stories) rather than silently guessing.

The global `/cut-release` is removed; `~/.claude/CLAUDE.md`'s "Cut a release" rule now points at `/p2e-cut-release`. The new command is installed via the marketplace alongside the rest of the plugin.

### Added
- **`/p2e-cut-release`** (`commands/p2e-cut-release.md` + `skills/p2e-cut-release/SKILL.md` + `.cursor/skills/p2e-cut-release/SKILL.md` + shared `workflows/p2e-cut-release.md`) — six-phase release flow: Phase 0 pre-flight with the authoritative version detection above + `AskUserQuestion` plan approval; Phase A push + PR + CI + squash-merge; Phase B sync main + bump every matching manifest + commit + tag + push + `gh release create --generate-notes`; Phase C FE-touching AC screenshots via the browser-driver MCP (chrome-devtools preferred, claude-in-chrome fallback) — skipped with `--no-screenshots`; Phase D release URL + summary report; Phase E story closeout when a story-id resolved; Phase F worktree + branch teardown. `--no-pr` (emergency hotfix), `--no-screenshots`, `--draft` flags.
- **Policy carve-out** in `workflows/p2e-policy.md → ## Status lifecycle → Cut-release carve-out` — names the three conditions under which `/p2e-cut-release` may transition `IN_REVIEW → DONE`. No other workflow is permitted to flip `DONE`.
- Router entries in `skills/p2e/SKILL.md` and `.cursor/skills/p2e/SKILL.md` for plain-language "cut a release" / "ship a release" / "tag and release" / "publish v0.X.Y" requests.
- New defaultPrompt entry in `.codex-plugin/plugin.json` so Codex's install UI surfaces the workflow.

### Changed
- **`README.md`** — new "Cut release" row in the commands-and-skills table, between "Verify story" and "Sync labels".
- **`.claude-plugin/plugin.json` + `.codex-plugin/plugin.json` + `.claude-plugin/marketplace.json`** — bumped to `0.10.4` (patch — load-bearing bug fix in the previous release flow's version-detection; the new command is treated as a patch-class delivery because the headline change is the bug fix, not the surface addition). Both manifest descriptions updated to list cut-release.

### Removed
- **`~/.claude/commands/cut-release.md`** (out-of-repo, in the user's global Claude config) — replaced by `/p2e-cut-release`. Personal `~/.claude/CLAUDE.md` updated accordingly. Non-P2E repos that relied on the global command should install the plugin (the new command works on any repo; story closeout is a no-op without `.p2e/project.json`).

## v0.10.3 — 2026-05-22

Adds `/p2e-ship-batch` — the heavyweight cousin of `/p2e-work-on-next`. Designed for release-cut scenarios where multiple OPEN stories need to ship with a full quality-gate layer: per-story 360° verification via `/p2e-verify-story` (now a shipped dependency as of v0.10.2), per-story PR + review, conditional security review (auto-detected from diff paths), and a rich-Markdown roll-up doc. Phase B delegates to `/p2e-work-on-next` without forking its logic — the same briefing, status discipline, two-strike rule, AC toggle, and label sync. Phases C–F add what work-on-next doesn't cover for hands-off batch operation.

Also tightens the shared first-turn briefing with an explicit **implementer deviation-reporting contract**: when implementation reveals the spec is wrong, incomplete, or conflicts with reality, the implementer must emit a `SCOPE_CHANGE` or `DECISION` story-log entry **before** making the deviating change. The two kinds are no longer human-authored only: `SCOPE_CHANGE` may now be authored by `"implementer"` or `"user"`, and `DECISION` may now be authored by `"implementer"`, `"orchestrator"`, or `"user"` (the orchestrator path covers cases like a `--no-security` override emitted by `/p2e-ship-batch` itself). `/p2e-ship-batch` enforces the contract via a scope-change audit at the end of Phase B (diff the as-implemented story against the briefed spec; surface unreported deltas before continuing to verify). `/p2e-work-on-next` relies on the implementer honoring the contract.

Adds per-story task tracking: ship-batch creates one TaskCreate task per story at Phase A, then updates its status as the story moves through Phases B–E. Gives the user a live view of every workstream in the batch without scraping logs or polling MCP.

### Added
- **`/p2e-ship-batch`** (`commands/p2e-ship-batch.md` + `skills/p2e-ship-batch/SKILL.md` + `.cursor/skills/p2e-ship-batch/SKILL.md` + shared `workflows/p2e-ship-batch.md`) — heavyweight batch-ship orchestrator. Reuses `/p2e-work-on-next` for Phase B (implementation + verification + label sync) without forking, then layers Phase C (360° verify via `/p2e-verify-story`, the v0.10.2-shipped UAT-report workflow), Phase D (one PR per story + `/pr-review-toolkit:review-pr` + conditional `/security-review` auto-triggered on auth/secrets/oauth/permission/PII/migration diff paths or Foundation `Security` slot membership), Phase E (rich-Markdown roll-up at `docs/feat-ship-batch-<date>/index.md`), and Phase F (optional `--cut-release` handoff, Claude Code only). Failure isolation defaults to skip-and-continue with per-phase BLOCKED / needs-attention markers; `--stop-on-fail` halts the whole batch.
- Per-story TaskCreate / TaskUpdate tracking — Phase A creates one task per selected story; phases B–E update task status (`in_progress` on Phase B start, `completed` on Phase E roll-up, `pending` again if a phase failure sends the story back). Provides a live ops view of the batch on hosts that support task tooling (Claude Code natively; Codex / Cursor degrade to chat-prose progress updates).
- New story-log VERIFICATION checkpoints (4 + 5) capturing the 360° verify pass and the PR-review pass per story; failures fall through to the existing BLOCKER pattern.
- Diff-driven security gate — globset matches `**/auth*`, `**/session*`, `**/crypto*`, `**/secret*`, `**/token*`, `**/oauth*`, `**/permission*`, `**/password*`, `**/identity*`, `**/login*`, `**/jwt*`, `**/saml*`, `**/iam*`, paths with `pii`/`gdpr`/`hipaa`/`pci`/`phi`, migrations adding sensitive columns, capabilities with `DEPRECATES`/`REMOVES` against auth identifiers, or Foundation `Security` slot membership. `--security` forces on; `--no-security` forces off and logs a `kind: DECISION` override.
- `defaultPrompt` adds a "Ship the v0.X release batch with full gates" example to surface the new command in Codex's install UI.

### Changed
- **`workflows/p2e-first-turn-briefing.md`** — new `## Deviation reporting` section in the briefing template + matching field-mapping row + rule. The implementer is contracted to emit `SCOPE_CHANGE` / `DECISION` entries before making mid-flight spec deviations. Inherited by both `/p2e-work-on-next` and `/p2e-ship-batch`.
- **`workflows/p2e-work-on-next.md`** — the `### Human-authored kinds` section in the story-log policy is renamed `### Self-reporting kinds (implementer or human)`. `SCOPE_CHANGE` may now be authored by `"implementer"` or `"user"`; `DECISION` may now be authored by `"implementer"`, `"orchestrator"`, or `"user"`. The three orchestrator checkpoints (AC toggle, verification pass, verification failure) in the existing policy are unchanged.
- **`skills/p2e/SKILL.md` + `.cursor/skills/p2e/SKILL.md`** — both routers gain a routing line for `workflows/p2e-ship-batch.md` (the heavyweight cousin of work-on-next). Descriptions updated to list `ship-batch` in the workflow set.
- **`README.md`** — new "Ship batch" row in the commands-and-skills table, after the "Work next" row.

## v0.10.2 — 2026-05-22

### Added — `/p2e-verify-story` (cross-platform UAT report)
- **`workflows/p2e-verify-story.md`** (new) — shared workflow for verifying a P2E story's acceptance criteria end-to-end. Six phases: gather story (P2E MCP as Source 1 default, with spec / GH-issue / free-form fallbacks), bring the dev server up reliably (detached `nohup` launch + `lsof` port verification to prevent the `feedback_uat_verify_running_code` port-clash failure), reproduce each AC via a browser-driver MCP, assemble a self-contained rich-HTML report (single `.html` + per-AC PNG / curl evidence, scoped under `.rich-doc` theme tokens — same vocabulary as the `writing-rich-docs` skill), open for human review, teardown. Visible pixels over JSON probes for every UI AC. Output is information only — does not move the story's lifecycle.
- **Cross-platform compliance** — `commands/p2e-verify-story.md` (Claude), `skills/p2e-verify-story/SKILL.md` (Codex), `.cursor/skills/p2e-verify-story/SKILL.md` (Cursor). Plus router entries in `skills/p2e/SKILL.md` and `.cursor/skills/p2e/SKILL.md`. Plus README row.
- **Bundled resources** under `skills/p2e-verify-story/`:
  - `references/gathering-acs.md` — Phase 1 sourcing with P2E MCP as the canonical default
  - `references/dev-server-setup.md` — Phase 2 detached launch + port-clash mitigation + pre-staging
  - `references/browser-driver-recipes.md` — Phase 3 MCP-driving patterns (hover, React inputs, toast pinning, snapshots, screenshots, scrolling, reload, native-dialog avoidance) covering both `mcp__chrome-devtools__*` (preferred) and `mcp__claude-in-chrome__*` (fallback)
  - `references/report-template.md` — Phase 4 component patterns + theme tokens + validation checklist
  - `scripts/start-dev-detached.sh`, `scripts/stop-dev.sh` — detached dev-server lifecycle (PID files in `.claude/verify-story-pids/`)
  - `assets/template.html` — single-file rich-doc skeleton (summary grid, per-AC sections, overall assessment, embedded `.rich-doc` styles, light / dark theme)
- **Validator** — `scripts/validate-plugin.py` updated: `p2e-verify-story` added to `expected_commands`, `expected_workflows`, `expected_skill_paths`, `expected_cursor_skill_paths`, `workflow_map`, and the router required-workflows list.

## v0.10.1 — 2026-05-12

Rebalances the doc-rendering surface: **rich human-review docs default to Markdown with embedded HTML blocks**, not pure single-file HTML. Markdown carries the structural ~50% (front-matter, headings, prose, simple lists/tables, code fences — fast and token-cheap); HTML blocks carry the high-fidelity rest (decision cards, color-coded comparison matrices, anatomy/three-pieces grids, callouts, premise ladders, step+cost lists, and all diagrams via inline SVG). Pure HTML moves to being the `/p2e-html` escape hatch; `/p2e-md` forces plain Markdown with no blocks. doc-reviewer now renders mixed Markdown + HTML and anchors comments to both — the blend carries no review penalty.

### Changed
- **`skills/writing-rich-html-docs/` → `skills/writing-rich-docs/`** (renamed; Cursor mirror `.cursor/skills/writing-rich-docs/` too). New default behavior: produce `.md` with embedded HTML blocks. `SKILL.md` rewritten around the MD+HTML-block model.
- **`workflows/p2e-rich-html-docs.md` → `workflows/p2e-rich-docs.md`** — rewritten: the MD-carries-structure / HTML-blocks-carry-fidelity model, output format by trigger (`/p2e-html` → pure HTML, `/p2e-md` → plain MD, default → rich MD), the rich-Markdown production steps (front-matter → `<style>` preamble → Markdown body → promote regions to `<div class="rich-doc">` HTML blocks), the unchanged MD→HTML conversion mapping, and the doc-reviewer compatibility table (now noting mixed-content support).
- **`skills/writing-rich-docs/references/template.md`** (new) — the canonical rich-Markdown skeleton: YAML front-matter, the `<style>` preamble (theme tokens + every component's CSS, scoped under `.rich-doc` so it doesn't fight doc-reviewer's Markdown styling), and a section scaffold with `<!-- promote-if … -->` hints. `references/template.html` is kept as-is for the `/p2e-html` pure-HTML path (same component classes).
- **`skills/writing-rich-docs/references/components.md`** — each component now paired with its **MD-native alternative** and a **"promote when"** trigger, so the agent defaults to Markdown and only promotes when a visual structure carries the content better.
- **`skills/writing-rich-docs/references/strategies.md`** — replaced the pure-pedagogy menu with a **promote-or-not** decision table (which content stays Markdown vs. gets an HTML block) plus the section-shape templates and cognitive-amortization rules.
- **`/p2e-html`, `/p2e-md`, `/p2e-md-to-html`** — descriptions + bodies updated: they now override the *default rich-Markdown output* (rather than an "audience auto-classifier"); `/p2e-html` = pure single-file HTML, `/p2e-md` = plain Markdown with no `<style>` preamble or HTML blocks, `/p2e-md-to-html` = convert a Markdown doc (plain or rich) to pure HTML.
- **`scripts/validate-plugin.py`** — `writing-rich-html-docs` → `writing-rich-docs`, `p2e-rich-html-docs.md` → `p2e-rich-docs.md` across the workflow set, Codex/Cursor skill sets, and `workflow_map`.
- **`.cursor/rules/p2e-policy.mdc`, `README.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CLAUDE.md`** — references to the renamed skill + the new default behavior. The Claude-Code-only asymmetry of the three override commands is unchanged.
- **`~/.claude/CLAUDE.md`** (personal, not in this repo) — the "Doc Output Conventions" section reworked: human-review docs default to **rich Markdown** (`.md` with embedded HTML blocks via the `writing-rich-docs` skill); `/p2e-html` is the pure-HTML override; aggressively promote regions to HTML blocks for high-fidelity content rather than writing whole docs in HTML.

## v0.10.0 — 2026-05-11

Two workstreams: (1) aligns the plugin with the P2E **Patton v3 Flow/Foundation model** (the backend's new ontology — Products, persona/Foundation Flows, `Story.priority`, ADRs); (2) makes the plugin **cross-platform compliant** across Claude Code, Codex, **and Cursor**, on a shared-workflow + thin-wrapper pattern, and adds a new `/p2e-fix` workflow.

### Added — cross-platform layer
- **`.cursor/` surface** — `.cursor/rules/p2e-policy.mdc` (always-applied Cursor rule mirroring `workflows/p2e-policy.md`), `.cursor/skills/<name>/SKILL.md` thin wrappers for every workflow (`p2e`, `p2e-add-story`, `p2e-archaeology`, `p2e-bind`, `p2e-bootstrap`, `p2e-fix`, `p2e-manage-uxo`, `p2e-sync`, `p2e-sync-labels`, `p2e-update-story`, `p2e-work-on-next`, `writing-rich-html-docs`), and `.cursor/mcp.json` pointing at the P2E MCP endpoint.
- **`CLAUDE.md`** (project-level) and **`AGENTS.md`** — orientation + the cross-platform compliance rule (every workflow ships four files: shared `workflows/<name>.md` + Claude command + Codex skill + Cursor skill).
- **`reference/`** — distilled platform schema docs (`claude-code-plugins.md`, `codex-plugins.md`, `cursor-skills-rules.md`), the canonical `cross-platform-pattern.md` (four-file pattern, wrapper templates, platform-asymmetry table), and a `README.md` index.
- **`/p2e-fix`** (`commands/p2e-fix.md` + `skills/p2e-fix/SKILL.md` + `.cursor/skills/p2e-fix/SKILL.md` + shared `workflows/p2e-fix.md`) — fix one or more bugs by uprooting and re-implementing rather than layering patches. Per-bug fix-shape gate (Deleted / Replaced / Preserved / Band-aid rejected), root-cause Iron Law, verify-both-directions before completion, optional P2E story-log discipline entry, `--dry-run` and `--allow-band-aid="<bug-id>=<reason>"` flags. Routed from the `p2e` router on Codex and Cursor.
- **`.cursor/skills/writing-rich-html-docs/SKILL.md`** — Cursor mirror of the doc-rendering skill (the `/p2e-html` / `/p2e-md` / `/p2e-md-to-html` override commands remain Claude-Code-specific by design).
- **Validator coverage** in `scripts/validate-plugin.py` — `p2e-fix` added to the command / workflow / Codex-skill sets and the `workflow_map`; new assertions for the full `.cursor/skills/` set, `.cursor/rules/p2e-policy.mdc`, the `reference/` files, and `CLAUDE.md` / `AGENTS.md`; the router-reference check now runs against both the Codex router (`skills/p2e/SKILL.md`) and the Cursor router (`.cursor/skills/p2e/SKILL.md`) and requires `workflows/p2e-fix.md`.

### Changed — Patton v3 Flow/Foundation alignment
- **`workflows/p2e-bootstrap.md`** & **`workflows/p2e-archaeology.md`** — add the Flow axis above phases: discover the seeded persona + Foundation Flows via `mcp__p2e__flows op=list` (step 0 of the write sequence), route user-journey phases/UXOs to the persona Flow and platform/infra UXOs to the matching Foundation slot (Surfaces / Security / Data / Compute / Build-Deploy / Distribution / Observability / Cross-cutting), never create new Foundation phases, and link tech-stack ADRs (`docs/adrs/`, MADR) from Foundation UXOs via `spec_file`.
- **`workflows/p2e-add-story.md`** & **`workflows/p2e-update-story.md`** — surface `Story.priority` (`P0`…`P3` or `null`) in the inferred-fields list, the required preview, the confirm options, and the `op=create` / `op=update` payloads; default `null`, map plain-language urgency to `P0`/`P1`; re-prioritizing alone skips the thick-gate re-check. `workflows/p2e-sizing-rubric.md` gains a `Sizing ≠ Priority` callout.
- **`workflows/p2e-work-on-next.md`** — the OPEN candidate queue is now canonically ordered: `priority` ascending (`P0` < `P1` < `P2` < `P3` < `null`) then `createdAt` ascending; one global queue across all Flows (no pre-filtering by Flow); the `release` / `phase` / `tag` / `story_id` filters narrow on top.
- **`workflows/p2e-first-turn-briefing.md`** — adds a Flow-context section (persona vs Foundation + which of the 8 slots, and what that implies for the work) and an ADR-context section (follow `uxo.specFile` / `contextDocs[]` `docs/adrs/...` links and summarize the decision).
- **`workflows/p2e-policy.md`** — adds a Product/Project naming note (`mcp__p2e__products` / `product_slug` canonical; `mcp__p2e__projects` / `project_slug` deprecated for one window; all other tools unchanged) and an adaptive-router rule routing Foundation-Flow stories (Security / Data / Compute / Build-Deploy) to at least the Standard track.
- **`workflows/p2e-uxo-recipe.md`** & **`workflows/p2e-manage-uxo.md`** — a UXO now lives in a Phase-in-a-Flow; the manage-uxo preview shows the Flow + phase; `tier`/`tier_name` still accepted but documented as deprecated; Foundation UXOs may link an ADR via `spec_file`.
- **`workflows/p2e-bind.md`** & **`workflows/p2e-sync.md`** — prefer `mcp__p2e__products op=list` / `op=get` with a one-line legacy fallback to `mcp__p2e__projects`; the `.p2e/project.json` shape is unchanged.
- **`skills/p2e/SKILL.md`** (Codex router) — adds routing lines for `/p2e-archaeology` and `/p2e-fix`.
- **README.md** — title and intro updated for Cursor + the Flow/Foundation model; the commands-and-skills table gains a Cursor column and rows for `/p2e-fix`, `/p2e-sync`, `/p2e-manage-uxo`, `/p2e-archaeology`, and the `writing-rich-html-docs` skill; the MCP-tool-surface table adds `flows` and `products`, marks `projects` deprecated, notes `priority` on `stories` and tier deprecation on `uxos`; new "Install in Cursor" and "Flow / Foundation model" sections.
- **`.claude-plugin/plugin.json`**, **`.claude-plugin/marketplace.json`**, **`.codex-plugin/plugin.json`** — versions bumped to `0.10.0`; descriptions updated to list the full command set, Cursor support, and Patton v3 alignment; the Codex `defaultPrompt` gains a "fix these bugs the right way" entry; marketplace keywords add `codex` and `cursor`.

### Notes
- **No breaking changes.** Existing wrappers continue to work; the Patton v3 changes are additive (the plugin still operates against pre-Patton-v3 MCP builds via the legacy `projects` tool, just without Flow discovery). The `/p2e-html` / `/p2e-md` / `/p2e-md-to-html` doc-output override commands remain Claude-Code-specific — that asymmetry is now documented in `reference/cross-platform-pattern.md` and `CLAUDE.md` rather than treated as a parity gap. (This supersedes the v0.9.0 "Codex parity incomplete / v0.9.1 follow-up" and "Cursor adapters deferred" known-limitation notes.)

## v0.9.0 — 2026-05-10

Adds the `writing-rich-html-docs` skill — an opinionated single-file HTML template + design system + pedagogical-strategy menu for human-review docs (spec.html, design.html, adr-*.html, retro.html, postmortem.html). Plus three new override/conversion commands and a shared workflow file.

### Added
- **`skills/writing-rich-html-docs/`** — new skill carrying `SKILL.md`, `references/template.html` (canonical single-file HTML skeleton with `{{TITLE}}/{{TYPE}}/{{STATUS}}/{{DATE}}/{{OWNER}}/{{HASH}}` placeholders and the full hand-written CSS design system), `references/components.md` (copy-paste blocks for TL;DR card, decision cards open + RESOLVED, callouts, premise list, comparison table, three-pieces grid, anatomy grid, steps list, code block, deferred bullets), and `references/strategies.md` (pedagogical-strategy menu mapping cognitive tasks to visual patterns plus section-shape templates).
- **`/p2e-html`** — force the next doc-producing skill in the same turn to write rich HTML output (overrides the audience auto-classifier).
- **`/p2e-md`** — force MD output instead (use for trivial config-only ADRs).
- **`/p2e-md-to-html <file.md>`** — convert an existing legacy MD spec/design/ADR to a rich HTML doc using the canonical template. Source `.md` is preserved.
- **`workflows/p2e-rich-html-docs.md`** — shared workflow contract pointed to by the skill and all three commands. Covers audience classification, HTML production rules, MD→HTML conversion mapping, doc-reviewer compatibility constraints (no `<script>`, no `<details>`, no anchor nav, no sticky), and the skill quality bar.

### Changed
- **`.claude-plugin/plugin.json`**, **`.claude-plugin/marketplace.json`**, **`.codex-plugin/plugin.json`** versions bumped to `0.9.0`. Marketplace description updated to list the three new commands and mention the new skill.

### Known limitations
- **Codex parity incomplete in v0.9.0.** The `writing-rich-html-docs` skill itself loads in Codex (it lives under `skills/` which `.codex-plugin/plugin.json` exposes), but the three override commands (`/p2e-html`, `/p2e-md`, `/p2e-md-to-html`) are Claude Code only — no `skills/p2e-html/SKILL.md` / `skills/p2e-md/SKILL.md` / `skills/p2e-md-to-html/SKILL.md` Codex aliases ship in this release. Codex parity for the override commands will ship in a follow-up release (v0.9.1).
- **Cursor / Opencode adapters not included.** Deferred by design — see `docs/feat-rich-html-docs/design.html` "Deferred / out of scope".

## v0.8.0 — 2026-04-20

Adds a canonical recipe for writing UXO `description` and `objectives[]` fields (`workflows/p2e-uxo-recipe.md`), a new preview/confirm command `/p2e-manage-uxo (--edit | --add)` that operationalizes the recipe, and cross-references from the existing bootstrap / update-story / router surfaces. Pairs with [bchoor/p2e#250](https://github.com/bchoor/p2e/issues/250) (P2E story B-05-L21).

### Added
- **`workflows/p2e-uxo-recipe.md`** (B-05-L21, [bchoor/p2e#250](https://github.com/bchoor/p2e/issues/250)) — reference recipe for UXO `description` + `objectives[]`: **objectives[] first → MECE-audit within the UXO → description as succinct articulation**. Ships with a grammar template, a 10-verb capability palette (Establish / Broker / Enforce / Govern / Issue / Provide / Enable / Expose / Deliver / Detect), 3 quality gates (substitution / narrative-smell / sibling-MECE), a gap-flagging protocol, and 5 worked examples drawn from the P2E Authenticate phase (AU-01..AU-05) that were hand-calibrated on 2026-04-20. Anti-patterns table explicitly rules out narrative/storyboard, implementation catalogs, aspirational metrics, feature-list grab bags, sibling-overlapping scope, and tautological descriptions.
- **`/p2e-manage-uxo (--edit | --add)`** (B-05-L21, [bchoor/p2e#250](https://github.com/bchoor/p2e/issues/250)) — user-invoked command that applies the recipe with an annotated preview + confirm gate, mirroring the `/p2e-update-story` UX pattern. `--edit <uxo_id>` (default) fetches the target UXO plus its story stack and runs a MECE audit with a story-landing coverage table (orphan + multi-landed stories flagged). `--add <uxo_id> --phase=<title> --tier=<name>` scaffolds a blank UXO and runs the same preview/confirm flow. Confirm step supports Accept / Thicken objectives[] / Steer `<field>` / **Flag gap** (writes a thin-DRAFT story under this UXO per the recipe's gap-flagging protocol) / Abort. `--dry-run` renders preview + exact MCP payload without writing. Both modes use the `items:[{...}]` MCP call form to round-trip `objectives` as a native array.
- **`workflows/p2e-manage-uxo.md`** — shared behavior spec covering preview contents, confirm actions, thicken/steer rules, brainstorming escalation (invoked when staged `objectives[]` has fewer than 3 bullets and evidence is thin), write ordering, dry-run behavior, and error handling. Mirrors `workflows/p2e-update-story.md` structure.
- **`commands/p2e-manage-uxo.md`** — thin Claude command wrapper with `argument-hint: <uxo_id> [--edit | --add] [--phase=<title>] [--tier=<name>] [--dry-run]`.
- **`skills/p2e-manage-uxo/SKILL.md`** — thin Codex skill wrapper with the same hard rules and brainstorming escalation contract.
- **Validator coverage** in `scripts/validate-plugin.py` — `p2e-manage-uxo.md` added to `expected_commands`, `expected_workflows`, and `expected_skill_paths`; `commands/p2e-manage-uxo.md` and `skills/p2e-manage-uxo/SKILL.md` added to `workflow_map`; router check tuple extended with `workflows/p2e-manage-uxo.md` and `workflows/p2e-uxo-recipe.md`.

### Changed
- **`workflows/p2e-bootstrap.md`** — "Drafting rules" references `workflows/p2e-uxo-recipe.md` for UXO `description` + `objectives[]` shape so bootstrap-generated UXOs follow the same discipline as `/p2e-manage-uxo`-authored ones.
- **`workflows/p2e-update-story.md`** — "UXO placement re-evaluation" surfaces the recipe when a target UXO's scope articulation is too thin to reliably match against; the wrapper now directs the user to `/p2e-manage-uxo --edit <uxo_id>` instead of silently guessing placement.
- **`skills/p2e/SKILL.md`** (router) — two new routing rules: one for UXO writing/refining/auditing requests (points at the recipe), and one for explicit edit/add requests (points at `workflows/p2e-manage-uxo.md`).
- **`.claude-plugin/plugin.json`**, **`.claude-plugin/marketplace.json`**, **`.codex-plugin/plugin.json`** versions bumped to `0.8.0`.

### Notes
- No breaking changes. Existing wrappers (`/p2e-bootstrap`, `/p2e-add-story`, `/p2e-update-story`, `/p2e-work-on-next`, `/p2e-sync`, `/p2e-sync-labels`) continue to work unchanged; the recipe is additive guidance they now reference, and `/p2e-manage-uxo` is a net-new command.
- `python3 scripts/validate-plugin.py` passes.
- Companion P2E stories filed during drafting: [bchoor/p2e#250](https://github.com/bchoor/p2e/issues/250) (B-05-L21, this release), plus two thick DRAFT stories for gaps the recipe surfaced in the Authenticate phase (AU-01-L7 account deletion, AU-05-L2 PAT expiry), and two new UXOs (AU-06 MFA, AU-07 multi-device session management) ready for their own L1 layers.

## v0.7.3 — 2026-04-19

Test release — no functional changes. Validates that Claude Desktop correctly detects plugin updates now that `.claude-plugin/plugin.json` carries a `version` field (added in v0.7.2). Bumps all three version markers to `0.7.3`.

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
