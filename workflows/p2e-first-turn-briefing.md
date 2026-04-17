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
2. **Tag-mapped project invariants** — for each tag on the story, the orchestrator appends the matching invariant lines from the project's `CLAUDE.md` (or the workflow-level invariant catalog when no `CLAUDE.md` mapping exists). Default tag→invariant map for the `p2e` project:

| Tag | Invariant lines to inline |
| --- | --- |
| Schema | Prisma schema changes require a migration that backfills cleanly; AuditLog every field change. |
| MCP | Every MCP mutation must round-trip through the same code path the UI uses (MCP↔UI parity). |
| UI | Multi-project scoping: every component reads `projectSlug` from context, never hardcodes `p2e`. |
| Server | Server actions enforce the same gates as MCP tools (no bypass paths). |
| Plugin | Wrappers stay thin pointers; behavior lives in `workflows/*.md`, not in the wrapper file. |
| Infra | Reversible migrations only; CI must pass on the PR before merge. |
| Docs | Documentation updates land in the same PR as the behavior change. |

Wrappers may extend this map per project. The orchestrator selects only the invariants whose tag appears on the current story.
