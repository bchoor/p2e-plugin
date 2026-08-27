# P2E agent contracts

Reference for subagents. **Not a workflow; not invocable.** Salvaged from pre-v0.12 orchestration recipes (`v0.11.3`) for agents that still execute against these contracts.

Session posture (entity model, lifecycle, MCP, review pipeline) lives in `skills/p2e-mode/SKILL.md`.

---

## First-turn briefing

The supervisor materializes this block per story and hands it to the implementer as its first input message. Each section maps 1:1 to fields on the story JSON returned by `mcp__p2e__stories op=get`.

### Template

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
<one-line implication>

## ADR context
<If the UXO's spec_file or any entry in contextDocs[] points at a docs/adrs/... path, summarize Decision / Context / Consequences>
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
2. If you changed a Prisma model/enum, exported action signature, or API route shape: enumerate unchanged consumers and confirm each is updated or explicitly N/A. Document sweep results in a `kind: DECISION` story-log entry.
3. Report completion only after both checks pass.

## Deviation reporting
When implementation reveals that the spec is wrong, incomplete, or conflicts with reality and you decide to deviate, emit a story-log entry **before** making the change:
- `kind: SCOPE_CHANGE` — change to the spec itself.
- `kind: DECISION` — non-obvious judgment call that does NOT change the spec.

MCP call shape:
`mcp__p2e__story_log op=append project_slug=<slug> items=[{ "story_id": "<id>", "kind": "SCOPE_CHANGE", "author": "implementer", "message": "<what changed and why>" }]`
```

### Briefing rules

- Empty arrays: render the section with `- (none)` rather than omitting.
- Missing `verificationCmd`: render `Run: (no verification command specified — ask the user)`.
- **Flow context:** Derive from `story.uxo.phase.flow`. Foundation slots: Surfaces, Security, Data, Compute, Build-Deploy, Distribution, Observability, Cross-cutting.
- **ADR context:** Scan `story.uxo.specFile` and `story.contextDocs[]` for `docs/adrs/...` paths.

---

## Adaptive router

When classifying a story or choosing an execution track:

1. Any capability with `isBreaking: true` => Architectural track.
2. Any capability with action `DEPRECATES` or `REMOVES` => Architectural track.
3. Any tag in `{ data-model, migration, infra }` => Architectural track.
4. Acceptance criteria count >= 8 => Architectural track.
5. Story's UXO in **Foundation Flow** AND slot in `{ Security, Data, Compute, Build-Deploy }` => at least Standard track.
6. Any tag in `{ ui, docs, copy }` and AC count <= 3 => Fast track.
7. Otherwise => Standard track.

Track mapping:

- **Fast** — lightweight implementer, no architect, no staff engineer.
- **Standard** — general implementer, architect opt-in, staff engineer when batch >= 2.
- **Architectural** — general implementer, architect opt-in, staff engineer yes.

**Shape-aware routing:** `p2e-architect` runs when `constraints` contains `approach-review` OR `--full-team` was passed. Otherwise the implementer self-plans inline from the first-turn briefing.

---

## Adaptive skill matrix

First matching row per category wins; rows are additive across categories.

| Signal | Skill to pull in | When it runs |
| --- | --- | --- |
| `constraints` contains `approach-review` OR `--full-team` | `p2e-architect` + `superpowers:writing-plans` | Before dispatch (supervisor-side) |
| Tag `ui` with code changes (not copy-only) | `frontend-design` | During implementation |
| Standard/Architectural story whose `filesHint` spans >= 3 top-level directories OR has >= 3 capabilities | `feature-dev` phased pattern | During implementation |
| Tag `bug` or `fix`, or story has a `FIXES` relation | `superpowers:systematic-debugging` | Before any fix is written |
| Any capability with `isBreaking: true` | `superpowers:test-driven-development` | Tests precede implementation |
| None of the above | Self-plan inline from the first-turn briefing | Default |

---

## Review tiering

Exactly one primary review tool per story — never two review tools on the same diff.

| Risk class | Review tool | Timing |
| --- | --- | --- |
| **Schema / Auth** | `pr-review-toolkit:review-pr` + `/security-review` | After commit + push + PR opened |
| **Standard backend / MCP** | `pr-review-toolkit:review-pr` | After commit + push + PR opened |
| **UI** | `/code-review` (or `review-pr` if PR open) + Turbopack dev-compile + `frontend-design` | Fast: pre-PR; Standard+Arch: post-PR |
| **S/XS** | `/code-review` | Pre-PR on working-tree diff |

**PR-creation timing:**

- Fast / S/XS: run `/code-review` BEFORE opening the PR; fix findings; then commit + PR.
- Standard / Architectural / Schema / Auth: commit + push + open PR first; then run `pr-review-toolkit:review-pr`.

`/security-review` fires additionally for Schema/Auth, security globset hits, Foundation Security slot, or `--security`. `--no-security` requires a `kind: DECISION` story-log entry.

---

## Verification matrix

When `story.verificationCmd` is null, fall back to track defaults:

| Track | Default verification |
| --- | --- |
| Fast | `bun run quickcheck` |
| Standard | `bun run preflight` |
| Architectural | `bun run preflight && bunx --bun prisma validate` |

When `story.verificationCmd` is non-null, that command runs instead of the track default.

---

## Consumer-impact sweep

Mandatory when any of the following change:

- A Prisma model or enum
- An exported server action signature in `src/lib/actions.ts` or `src/lib/actions/`
- An API route shape

**Procedure:** for each changed item, `grep -r` across `src/app/api/`, `src/components/`, `src/mcp/tools/`, and `src/lib/` for call sites. Every hit is either (a) confirmed updated in the current diff, or (b) explicitly marked N/A. A hit that is neither is a blocker.

---

## Verify gate

Runs once per story between implementer completion and PR creation.

### Adaptive fix loop

After verification fails, dispatch a fix batch to the **same implementer agent** (resume with context). Iterate while each round strictly reduces the open-problem count. Exit:

- **Pass:** open-problem count reaches zero.
- **BLOCKED:** stall (no reduction across 2 consecutive rounds), oscillation, or 6-round cap.

On BLOCKED, the story-lead writes one `kind: BLOCKER` entry (`"author": "implementer"`) and reports `outcome: "blocked"`.

### Gate steps (ordered)

1. Run `verificationCmd` (or track-default from Verification matrix).
2. If passes: run the consumer-impact sweep.
3. Run the risk-tiered review tool (see Review tiering). Adaptive fix loop applies to findings.
4. When gate exits pass, story-lead reports `outcome: "pass"`. Supervisor close-out (verdicts, DEVIATIONS entry, IN_REVIEW flip) is supervisor responsibility only.

For backend/test ACs, upload `ac{N}-proof.md` per `specs/ac-evidence-proof.v1.yaml` — validate with `mcp__p2e__evidence op=validate_proof` before `story_assets` upload.

---

## Model routing

| Role | Default model | Override conditions |
| --- | --- | --- |
| **Supervisor** | session model | Plans, dispatches, reviews; never implements |
| **`p2e-story-lead`** | `sonnet` | `opus` when Architectural track, `approach-review`, or `--full-team` |
| **Implementer workers** | `sonnet` for coding | `haiku` for mechanical; `opus` for debugging (include `opus-justified: <reason>`) |
| **`p2e-architect`** | `sonnet` | `opus` when `--full-team` |
| **`p2e-staff-engineer`** | `sonnet` | `opus` when `--full-team` |

Total agent depth <= 5.

---

## Story-lead report contract

The story-lead's final message is a single JSON block the supervisor parses:

```json
{
  "story_id": "X-00-L0",
  "outcome": "pass | blocked",
  "branch": "feat/X-00-L0-topic",
  "pr_url": "https://github.com/... | null",
  "verification": { "cmd": "...", "result": "pass | fail", "summary": "..." },
  "acceptance_criteria": [{ "ordinal": 1, "met": true, "evidence": "..." }],
  "review": { "tool": "code-review | review-pr", "findings_addressed": 0, "wont_fix": [{ "finding": "...", "rationale": "..." }], "security_review": "run | skipped" },
  "deviations": ["story_log entries already written by the lead"],
  "files_touched": ["..."],
  "blocked_reason": null
}
```

Branch name convention: `feat/<STORY-ID>-<topic-kebab>`.

---

## Story log checkpoint policy

### Supervisor-authored checkpoints (exactly 3)

**Checkpoint 1 — AC verdict:** `mcp__p2e__criteria op=verdict` with concrete evidence in `note`. Verdict values: `PASS` | `FAIL` | `BLOCKED` | `NOT_TESTED`.

**Checkpoint 2 — Verification pass:**
```json
{ "kind": "VERIFICATION", "author": "orchestrator", "message": "Verified: <verificationCmd> — <summary>" }
```

**Checkpoint 3 — BLOCKED:** story-lead writes fix-loop BLOCKER (`"author": "implementer"`); supervisor writes strike-2 BLOCKER on architect-assisted retry failure.

### Self-reporting kinds (story-lead or human)

- `DECISION` — judgment call that does NOT change the spec.
- `SCOPE_CHANGE` — mid-flight change to the story spec itself.
- `NOTE` — free-form observation.

All writes use `items:[{...}]` form:
```
mcp__p2e__story_log op=append project_slug=<slug> items=[{ "story_id": "<id>", "kind": "...", "author": "implementer", "message": "..." }]
```

### Orchestrator DEVIATIONS checkpoint

After gate passes and before IN_REVIEW flip, write a DEVIATIONS entry summarizing all SCOPE_CHANGE/DECISION entries, or `"DEVIATIONS: none"`.

---

## Staff-engineer output contract

```json
{
  "waves": [["<story_id>", "<story_id>"], ["<story_id>"]],
  "files_touched": { "<story_id>": ["relative/path1"] },
  "collisions": [{ "wave": 1, "stories": ["X-01-L1","X-02-L1"], "file": "src/shared/util.ts" }]
}
```

If dependency cycle found, emit `{"error":"cycle","cycle":[...]}` and stop. Always emit `collisions: []` when none detected.
