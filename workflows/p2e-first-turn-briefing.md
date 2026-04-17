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
