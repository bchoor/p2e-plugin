# P2E First-Turn Briefing Template

The orchestrator materializes this block per story and hands it to the implementer as its first input message. Each section maps 1:1 to fields on the story JSON returned by `mcp__p2e__stories op=get`.

## Template

```markdown
# Story <storyId> — <title>

## Intent
<storyAs> wants <storyWant> so that <storySoThat>.
<background>

## Constraints
- <each entry from constraints[]>

## Acceptance Criteria
- [ ] <each entry from acceptanceCriteria[] where checked=false>
- [x] <each entry where checked=true>

## Capabilities
- <name> (<action><, breaking if isBreaking=true>): <description>
  ...

## Flow context
Flow: <flow name> — <"persona Flow" | "Foundation Flow: <slot>">
<one-line implication, e.g.:>
- persona Flow ⇒ user-facing behavior work in a journey phase.
- Foundation Flow / Security ⇒ touches auth, secrets, keys, IAM.
- Foundation Flow / Build-Deploy ⇒ touches CI, release pipeline, migrations.
- Foundation Flow / Observability ⇒ touches logging, metrics, tracing.
- Foundation Flow / Data ⇒ touches schema, storage, query patterns.
- Foundation Flow / Compute ⇒ touches runtime, scaling, execution environment.
- Foundation Flow / Distribution ⇒ touches packaging, CDN, delivery.
- Foundation Flow / Surfaces ⇒ touches shared UI primitives, design tokens.
- Foundation Flow / Cross-cutting ⇒ affects multiple slots (e.g., auth + infra).

## ADR context
<If the UXO's spec_file or any entry in contextDocs[] points at a docs/adrs/... path, follow it and summarize:>
- **Decision:** <one sentence>
- **Context:** <one sentence>
- **Consequences:** <one sentence>
<If no ADR is linked, render: "(no ADR linked — not applicable)">

## Files hint
- <each path from filesHint[]>

## Context docs
- <each path from contextDocs[]>

## Non-goals
- <each entry from nonGoals[]>

## Verification
Run: `<verificationCmd>`

## Gate notice
Before reporting completion, self-run the following checks:
1. Run `<verificationCmd>` (or the track-default if unset) and confirm it passes.
2. If you changed a Prisma model/enum, exported action signature, or API route shape: enumerate unchanged consumers (`grep -r` across `src/app/api/`, `src/components/`, `src/mcp/tools/`, `src/lib/`) and confirm each is updated or explicitly N/A. Document your sweep results in a `kind: DECISION` story-log entry.
3. Report completion only after both checks pass. The orchestrator's verify gate will rerun (1) and (2) — a self-check that fails the gate wastes a round-trip and consumes the adaptive fix loop budget.

## Deviation reporting
When implementation reveals that the spec is wrong, incomplete, or conflicts with reality and you decide to deviate, emit a story-log entry **before** making the change:
- `kind: SCOPE_CHANGE` — change to the spec itself (AC dropped/modified, capability adjusted, non-goal added, scope reduced or expanded).
- `kind: DECISION` — non-obvious judgment call that does NOT change the spec (chose library A over B, picked a wrapper over a fork, deferred X to a follow-up story, overrode the architect's recommendation).

MCP call shape (always `items:[{...}]` form per the policy):
`mcp__p2e__story_log op=append project_slug=<slug> items=[{ "story_id": "<id>", "kind": "SCOPE_CHANGE", "author": "implementer", "message": "<what changed and why>" }]`

The reviewing human reads these entries to understand what was negotiated mid-flight. Skipping them silently absorbs the change and breaks the batch audit trail.
```

## Field mapping

| Briefing section | Story JSON field |
| --- | --- |
| Intent paragraph | `storyAs` + `storyWant` + `storySoThat` + `background` |
| Constraints | `constraints[]` |
| Acceptance Criteria | `acceptanceCriteria[]` (text + checked) |
| Capabilities | `capabilities[]` (name, action, isBreaking, description) |
| Flow context | `story.uxo.phase.flow` (name + isFoundation boolean + foundationSlot) |
| ADR context | `story.uxo.specFile` and `story.contextDocs[]` — any `docs/adrs/...` path |
| Files hint | `filesHint[]` |
| Context docs | `contextDocs[]` |
| Non-goals | `nonGoals[]` |
| Verification | `verificationCmd` |
| Gate notice | (static contract — same text every briefing) |
| Deviation reporting | (static contract — same text every briefing) |

## Rules

- Empty arrays: render the section with a single line `- (none)` rather than omitting — the implementer needs to see the intent was checked.
- **Model routing:** use `sonnet` for the implementer spawn. Use `haiku` for mechanical steps (status flips, MCP plumbing, label sync, verdict recording). Use `opus` only when `approach-review` is in `story.constraints[]` or `--full-team` was passed. See `## Model routing` in `workflows/p2e-policy.md`.
- Missing `verificationCmd`: render `Run: (no verification command specified — ask the user)` so the implementer surfaces the gap.
- On two-strike re-brief the orchestrator appends a `## Previous failure` section below `Verification` with the failure output; keep the template above unchanged.
- This template is loaded by every wrapper that routes a story into implementation. Do not inline it elsewhere.
- **Deviation reporting:** the Deviation reporting section is static (same text every briefing) and is required — the implementer is contracted to follow it on every story. `/p2e-ship-batch` enforces this via a scope-change audit after implementation; `/p2e-work-on-next` relies on the implementer honoring the contract.
- **Flow context:** Derive the Flow by following `story.uxo.phase.flow`. If the flow is the Foundation Flow, also include the slot name (one of: Surfaces, Security, Data, Compute, Build-Deploy, Distribution, Observability, Cross-cutting). If the data is unavailable, render `Flow: (unable to resolve — check story.uxo.phase.flow)`.
- **ADR context:** Scan `story.uxo.specFile` and every entry in `story.contextDocs[]` for a path matching `docs/adrs/...`. If found, read the ADR file and emit the three-line summary (Decision / Context / Consequences). If multiple ADRs are linked, emit one summary block per ADR. If none are linked, render `(no ADR linked — not applicable)`.

## Constraints sourcing

The Constraints section in the briefing pulls from TWO sources:

1. **Story-level constraints** — every entry in `story.constraints[]` is inlined verbatim.
2. **Always-inline project invariants** — every briefing for the `p2e` project includes these invariants regardless of tags, because they apply to every code path:
   - Multi-project scoping: every query and MCP tool scopes by `projectSlug`. Never hardcode a project slug.
   - AuditLog everywhere: every mutation on `Project`, `Phase`, `Uxo`, `Story`, `StoryRelation`, `StoryCapability`, `AcceptanceCriterion`, or `Feature` writes via `src/lib/audit.ts`.
3. **Tag-mapped project invariants** — for each tag on the story, the orchestrator appends the matching invariant lines from the project's `CLAUDE.md`. Default tag→invariant map for the `p2e` project, sourced from `bchoor/p2e:CLAUDE.md` core invariants:

| Tag | Invariant lines to inline |
| --- | --- |
| Schema | Migrations must backfill cleanly; never reintroduce `prisma/seed.ts` or a `db:seed` script (removed after the 2026-04-14 destructive-upsert incident). |
| MCP | MCP↔UI parity: every mutation lives in `src/lib/actions.ts` and is called by both the MCP route (`src/app/api/mcp/route.ts`) and the UI server actions. No bypass paths. |
| Server | Server actions enforce the same gates as MCP tools; UXO health (`storyCount`, `builtCount`, `conflictCount`, `driftDetected`) is computed on read via `GROUP BY uxoId`, not cached. |
| UI | Server/client boundary explicit: `MapGrid` and `UxoCell` stay server components; `StoryCard`, `DetailPanel`, drag-and-drop layers, and forms are `'use client'`. Bloomberg-terminal aesthetic, dark-first, compact padding (`py-1`, `space-y-0.5`). |
| Plugin | Wrappers stay thin pointers; behavior lives in `workflows/*.md`, not in the wrapper file. Plugin and Codex manifests must keep version in sync (validated by `scripts/validate-plugin.py`). |
| Infra | `DATABASE_URL` / `DATABASE_URL_UNPOOLED` in local, CI, and preview must use a non-production DB or branch — never run `prisma db push` against production. Repair migration drift with `prisma migrate resolve`, not by editing shipped migrations. |
| Docs | The canonical lifecycle doc is `docs/P2E-lifecycle.md`; supersedes any "iteration" wording elsewhere. Documentation updates land in the same PR as the behavior change. |

Wrappers may extend this map per project. The orchestrator selects only the invariants whose tag appears on the current story (in addition to the always-inline ones above).
