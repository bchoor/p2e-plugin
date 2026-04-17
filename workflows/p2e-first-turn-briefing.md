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

## Files hint
- <each path from filesHint[]>

## Context docs
- <each path from contextDocs[]>

## Non-goals
- <each entry from nonGoals[]>

## Verification
Run: `<verificationCmd>`
```

## Field mapping

| Briefing section | Story JSON field |
| --- | --- |
| Intent paragraph | `storyAs` + `storyWant` + `storySoThat` + `background` |
| Constraints | `constraints[]` |
| Acceptance Criteria | `acceptanceCriteria[]` (text + checked) |
| Capabilities | `capabilities[]` (name, action, isBreaking, description) |
| Files hint | `filesHint[]` |
| Context docs | `contextDocs[]` |
| Non-goals | `nonGoals[]` |
| Verification | `verificationCmd` |

## Rules

- Empty arrays: render the section with a single line `- (none)` rather than omitting — the implementer needs to see the intent was checked.
- Missing `verificationCmd`: render `Run: (no verification command specified — ask the user)` so the implementer surfaces the gap.
- On two-strike re-brief the orchestrator appends a `## Previous failure` section below `Verification` with the failure output; keep the template above unchanged.
- This template is loaded by every wrapper that routes a story into implementation. Do not inline it elsewhere.

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
