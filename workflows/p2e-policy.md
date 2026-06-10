# P2E Workflow Policy

This file defines the shared operating rules for every P2E wrapper. The wrappers may differ, but the workflow semantics stay the same.

## MCP access

- All P2E mutations and reads go through the P2E MCP surface and its operations exposed by the adapter.
- The MCP server handles authentication and audit logging. Wrappers must not invent their own auth or audit paths.
- The server URL may be configured by environment, but the workflow contract stays unchanged across environments.

## Product / Project naming

The canonical project entity is now **Product**, exposed via `mcp__p2e__products` (parameter: `product_slug`). The legacy `mcp__p2e__projects` tool (parameter: `project_slug`) remains available for one deprecation window and continues to work; prefer `mcp__p2e__products` for new workflow code. All **other** MCP tools — `mcp__p2e__stories`, `mcp__p2e__uxos`, `mcp__p2e__phases`, `mcp__p2e__criteria`, `mcp__p2e__story_log`, etc. — are **unchanged** and still accept `project_slug`; do not rename or alias those parameters.

## Adaptive router

When a workflow needs to classify a story or choose an execution track, use this order:

1. Any capability with `isBreaking: true` => Architectural track.
2. Any capability with action `DEPRECATES` or `REMOVES` => Architectural track.
3. Any tag in `{ data-model, migration, infra }` => Architectural track.
4. Acceptance criteria count >= 8 => Architectural track.
5. Story's UXO sits in the **Foundation Flow** AND the slot is one of `{ Security, Data, Compute, Build-Deploy }` => at least Standard track (escalate to Architectural if rules 1–4 also fire). Foundation/platform work is never Fast-tracked unless it is a trivial copy or doc-only change (no code, no schema, no config).
6. Any tag in `{ ui, docs, copy }` and acceptance criteria count <= 3 => Fast track.
7. Otherwise => Standard track.

Track mapping:

- Fast => lightweight implementer track, no architect, no staff engineer.
- Standard => general implementer track, architect opt-in (see shape-aware rule below), staff engineer only when batch size warrants it.
- Architectural => general implementer track, architect opt-in (see shape-aware rule below), staff engineer yes.

**Shape-aware routing:** The `p2e-architect` agent AND any external `superpowers:writing-plans` call are **opt-in** on Standard/Architectural stories. They run when EITHER the story's `constraints` array contains the literal string `approach-review`, OR the command was invoked with `--full-team`. Otherwise the implementer self-plans inline from the first-turn briefing (see `## First-turn briefing`).

Staff engineer (`p2e-staff-engineer`) + wave-gate rules are unchanged: staff engineer fires whenever batch size >= 2 regardless of track.

Fast-track stays lightweight: no architect, no staff engineer.

Wrappers should reserve higher-capacity specialist roles for architect and staff-engineer work only when the workflow explicitly calls for them.

## Canonical orchestrator naming

- `work-on-next` is the canonical orchestrator name.
- Adapter-specific entrypoints may exist, but they should point at the same shared behavior.
- Workflow docs should describe behavior, not wrapper syntax.

## Thin drafts

- A thin draft is a story with no acceptance criteria and no capabilities.
- Thin drafts are valid planning artifacts and should not be treated as broken data.
- The orchestrator should surface thin drafts to the user before classification so they can be fleshed out, proceeded with as-is, or skipped.

## Status lifecycle

- The canonical lifecycle is `DRAFT → OPEN → IN_PROGRESS → IN_REVIEW → DONE`. A `BLOCKED` status sits outside this linear path and marks stories waiting on unfinished `DEPENDS_ON` relations OR escalated per the two-strike rule.
- DRAFT → OPEN is gated server-side by the `isThick` predicate (enforced by the P2E MCP); the plugin does not perform this transition itself.
- On wave-start the orchestrator moves selected stories to `IN_PROGRESS`.
- On successful verification the orchestrator runs the verify gate (`## Verify gate`), records per-AC verdicts via `mcp__p2e__criteria op=verdict` with concrete evidence, writes the DEVIATIONS story-log entry, then moves the story to `IN_REVIEW`.
- On two consecutive verification failures the orchestrator moves the story to `BLOCKED` and stops retrying (see `## Two-strike escalation`).
- Final acceptance (IN_REVIEW → DONE) is a human action outside the orchestrator's scope, with one explicit carve-out for `/p2e-cut-release` (see below).

### Cut-release carve-out

`/p2e-cut-release` (`workflows/p2e-cut-release.md`) may transition `IN_REVIEW → DONE` when **all three** of the following hold during the same run:

1. The user explicitly answered "Proceed" to the workflow's pre-flight `AskUserQuestion` plan-approval gate (step 8). That gate is the human-authorization equivalent — it pre-authorizes every irreversible action in the run, including the status flip.
2. The story resolves via `--story-id=<id>` (explicit) or unambiguous branch-name regex inference (one match for `[A-Z]+-[0-9]+-L[0-9]+` in the current branch).
3. The story is at `IN_REVIEW` at the moment of the closeout. Any other status (`OPEN`, `IN_PROGRESS`, `BLOCKED`, already `DONE`) → no status write; surface the skip via a `kind: NOTE` story-log entry and let the user advance the story manually.

When the carve-out applies, the workflow also appends a `kind: VERIFICATION` story-log entry, posts a landed-on-main comment on the linked GitHub issue, and flips the issue's `review → done` label. No other workflow in this plugin is permitted to flip `DONE`.

## Thick-gate

- Before routing any selected story into implementation, the orchestrator fetches `mcp__p2e__stories op=get` and checks `isThick === true` AND `status === "OPEN"`.
- If either check fails for any story in the batch, the orchestrator stops and directs the user to `/p2e-update-story <story_id>` to thicken the spec (or to accept the thin draft per the `## Thin drafts` policy).
- The thick-gate is enforced for every track (Fast / Standard / Architectural). It replaces ad-hoc readiness heuristics.

## First-turn briefing

- For each story the orchestrator dispatches into, it materializes a per-story briefing as the implementer's **turn 1** input message.
- The exact template, section ordering, and field-mapping live in `workflows/p2e-first-turn-briefing.md`.
- The briefing maps 1:1 to the thick-spec fields returned by `mcp__p2e__stories op=get` so it is mechanically fillable.

## Two-strike escalation

- After each implementer pass the orchestrator runs the story's verification (the `verificationCmd` from the thick-spec, or the batch-level verification command).
- First failure: the orchestrator re-briefs the implementer with the failure output and allows one more pass.
- Second failure: the orchestrator stops. It sets the story's `status` to `BLOCKED` via `mcp__p2e__stories op=update`, posts the failure summary back to the linked issue, and routes the story to either the `p2e-architect` agent for a fresh approach OR the `codex:rescue` skill for a deeper diagnosis — the choice depends on the caller (Claude Code → architect; Codex → `codex:rescue`).
- Every escalation comment posted to the linked GitHub issue ends with the `— bchoor-claude` signature line, matching the project-wide convention.
- There is no third retry.

## Self-plan inline

- For **single-story thick runs** where the shape-aware router skipped the architect (no `approach-review` constraint and no `--full-team`), the implementer self-plans inline from the first-turn briefing.
- No external `superpowers:writing-plans` call is made in this path.
- For batch size >= 2, the staff-engineer wave plan runs regardless.
- TDD discipline is preserved on the self-plan-inline path whenever the story has any capability with `isBreaking: true`. The implementer writes tests before implementation regardless of whether `superpowers:writing-plans` was invoked.

## Verification matrix

For stories without a `verificationCmd` set on the thick-spec, the orchestrator falls back to a per-track default:

| Track | Default verification |
| --- | --- |
| Fast | `bun run quickcheck` (= `bunx --bun prisma generate && bunx tsc --noEmit`) |
| Standard | `bun run preflight` (= `quickcheck` + `bunx vitest run`) |
| Architectural | `bun run preflight && bunx --bun prisma validate` |

Tag-additive checks layer on top of the track default:

- Tag `ui`: append a browser-QA step (placeholder until the QA harness lands in a follow-up story).

Per-story override: when `story.verificationCmd` is non-null, that command runs INSTEAD of the track default. Tag-additive checks still apply.

## Batch behavior

- Batch writes are fail-fast.
- Earlier successful writes remain persisted if a later batch item fails.
- Workflows must report the failing phase and item index clearly so partial results can be reconciled.

## Tag hygiene

- Normalize tags before writing them: lowercase, trim, and replace whitespace with `-`.
- The router consumes normalized tags only.

## Destructive actions

- Workflows must not delete capabilities or criteria as part of ordinary story drafting or orchestration.
- Deprecation is represented by capability actions, not by destructive cleanup.

## End-of-run sync

- The orchestrator should reconcile issue labels at the end of a batch when it has enough issue and merge context to do so safely.
- If that context is missing or incomplete, the workflow must fall back to the explicit label-sync workflow instead of guessing.
- Stories completing the run successfully land at `IN_REVIEW`; the sync should reflect that lifecycle state in the corresponding GitHub issue labels.

## Verify gate

The verify gate runs once per story, between implementer completion and PR creation. It is NOT the two-strike loop — the adaptive fix loop operates inside the gate; two-strike applies only to gate-level failures that escape the loop.

### Risk classes and review tiers

Classify the story using the same inputs as the adaptive router (tags, sizing, `isBreaking`):

| Risk class | Trigger conditions | Review tier |
| --- | --- | --- |
| **Schema** | Tag `schema` or `migration`, or any `isBreaking: true` capability, or capability action `DEPRECATES`/`REMOVES` | Multi-dimension: correctness reviewer + security pass |
| **Auth** | Foundation Flow `Security` slot, or any changed file matching `**/auth*`, `**/session*`, `**/jwt*`, `**/oauth*`, `**/permission*`, `**/secret*`, `**/token*` | Multi-dimension: correctness reviewer + security pass |
| **Standard backend / MCP** | Tag `server`, `mcp`, `data`, `infra`, or `api`; no schema/auth trigger | One consolidated reviewer: correctness + parity + input-validation in a single pass |
| **UI** | Tag `ui`; no schema/auth trigger | One consolidated reviewer + Turbopack dev-compile check + frontend-design pass |
| **S/XS** | Sizing `S` or `XS`; no schema/auth trigger | Orchestrator inline diff review only |

A story may fall into multiple tiers; apply the highest matching tier (Schema > Auth > Standard > UI > S/XS).

### Consumer-impact sweep

The consumer-impact sweep is **mandatory** when any of the following change:

- A Prisma model or enum (any field add/remove/rename, any enum value change)
- An exported server action signature in `src/lib/actions.ts` or `src/lib/actions/`
- An API route shape (request body, response shape, path params, query params)

**Procedure:** for each changed item, `grep -r` across `src/app/api/`, `src/components/`, `src/mcp/tools/`, and `src/lib/` for import statements and call sites. Every hit is either (a) confirmed updated in the current diff, or (b) explicitly marked N/A with a one-line reason. A hit that is neither is a blocker.

**Worked example (P-13-L1 LINK-asset 502 miss):** The `linkStoryAsset` action signature changed in the implementation but the `story_assets` MCP tool at `src/mcp/tools/story-assets.ts` (an unchanged consumer) was not swept. The route returned 502 in production because the tool still passed the old parameter shape. The sweep would have caught this — the grep for `linkStoryAsset` would have surfaced the MCP tool as a hit, and the reviewer would have confirmed the tool was updated or marked it as still-compatible. Any PR that touches an exported action must enumerate and clear every consumer before the gate passes.

### Adaptive fix loop (inside the gate)

After verification fails, the orchestrator dispatches a fix batch to the **same implementer agent** (resume with context — not a fresh spawn). The loop iterates while each round strictly reduces the open-problem count (failing tests + confirmed findings). The loop exits:

- **Pass:** open-problem count reaches zero.
- **BLOCKED:** stall (no reduction across 2 consecutive rounds), oscillation (a previously-fixed failure reappears), or runaway cap (6 rounds reached without passing).

Each round logs the open-problem count so the trend is auditable. On BLOCKED, escalate per the two-strike path in `## Two-strike escalation`.

### Gate steps (ordered)

1. Run `verificationCmd` (or the track-default fallback from `## Verification matrix`).
2. If `verificationCmd` passes: run the consumer-impact sweep.
3. If sweep is clean: run the risk-tiered review.
4. If review finds problems: dispatch fix batch to the same implementer agent; re-run from step 1.
5. If gate passes: record per-AC verdicts via `mcp__p2e__criteria op=verdict` (see `## Story log checkpoint policy` Checkpoint 1 in `workflows/p2e-work-on-next.md`) and write the DEVIATIONS story-log entry (see `## Orchestrator DEVIATIONS checkpoint`).

## Orchestrator DEVIATIONS checkpoint

After the gate passes and before the `IN_REVIEW` flip, the orchestrator **must** write a `DEVIATIONS` story-log entry. This is not optional — it is a required gate step, not a convention.

If the implementer wrote `SCOPE_CHANGE` or `DECISION` entries during implementation, the DEVIATIONS entry summarizes them in one paragraph:

```
mcp__p2e__story_log op=append project_slug=<slug> items=[{"story_id":"<id>","kind":"DECISION","author":"orchestrator","message":"DEVIATIONS: <one-paragraph summary of all scope changes and decisions made during this run, or 'none' if the implementer reported no deviations>"}]
```

If no deviations were reported by the implementer, the entry still fires with `"message":"DEVIATIONS: none"`. This makes the absence of deviations explicit and auditable.

## Model routing

Every agent-dispatching workflow uses this routing table. Default to the cheapest adequate model; escalate only when the work genuinely requires it.

| Role | Default model | Override conditions |
| --- | --- | --- |
| **Implementer** | `sonnet` | `opus` only when `approach-review` constraint present or `--full-team` passed |
| **Reviewer** (any risk tier) | `sonnet` | No override — reviewers do not need opus |
| **Mechanical steps** | `haiku` | Mechanical = label sync, status flips, MCP plumbing, AC/verdict recording, story-log writes, PR URL capture |
| **Architect** | `sonnet` | `opus` only when `--full-team` |
| **Staff engineer** | `sonnet` | `opus` only when `--full-team` |

**Mechanical steps** are any steps where the agent is filling in known values with no reasoning required: toggling a status, writing a known story-log entry, syncing labels, recording a pre-computed verdict. Use `haiku` for these — they are high-frequency and token cost adds up.

**First-turn briefing and work-on-next** reference this table instead of leaving model choice to the session. The model router operates independently of the adaptive router (track selection) — they share inputs but produce orthogonal outputs.

## Priority rules

`Story.priority` is a work-queue ordering field — distinct from `sizing` (which is an effort estimate). Priority controls the order in which `/p2e-work-on-next` surfaces OPEN stories: `P0 → P1 → P2 → P3 → null`, then by `createdAt` within each band.

- Default is `null` (unprioritized). Most stories should be created with `null`.
- Set `P0` or `P1` only when the user explicitly signals urgency: the words "urgent", "blocker", "P0", "critical", "must ship now" → map to `P0`; "high priority", "P1", "important", "needs to go next" → map to `P1`.
- Plain requests without urgency language → leave `null`. Do not infer urgency from the story topic.
- `P2` (normal) and `P3` (lowest) are available for explicit queue-ordering but are rarely needed at add time; set them only if the user explicitly asks.
- Priority is NOT part of the thick-spec predicate — leaving it `null` never blocks `DRAFT → OPEN`.
- The `priority` field is included in the `mcp__p2e__stories op=create` and `op=update` payloads; it accepts `"P0" | "P1" | "P2" | "P3" | null`.

## Brainstorming escalation

When the thicken path (or thick-mode add-story path) runs and the staged draft still leaves ≥ 2 of the six thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`) empty AND the provided source does not support filling them, the wrapper invokes a shared brainstorming primitive **exactly once per flow** to batch clarifying questions in a single turn. The Claude wrapper resolves the reference against the `superpowers:brainstorming` skill; the Codex wrapper resolves it against its native brainstorming primitive (the same pattern used by `workflows/p2e-bootstrap.md --mode=onboarding`).

### When to escalate

Escalate **only** when ALL of the following are true after the first draft/thicken pass:

1. Two or more of the six thick-spec fields are still empty.
2. The provided source (the `source` argument, if any) does not contain evidence to fill them, and no sibling story under the same UXO supplies matching capabilities or AC patterns.
3. The user's original invocation did not explicitly opt out (for example via a `--no-brainstorm` flag on the wrapper, if implemented).

Do NOT escalate for thin mode. Do NOT escalate when the gap is a single optional field. Do NOT escalate more than once per flow — if answers still leave major gaps, leave the cells empty and continue to the preview. Empty cells are preferred over filler.

### Question shape

The wrapper batches 2–4 concrete questions in a single turn. Prefer multiple-choice or closed-form questions over open-ended prose. Typical questions:

- Which files or modules does this story touch? (pick from detected candidates, or free-form)
- What are the non-negotiable constraints? (timezone / currency / backwards-compat / visible-screen / etc.)
- What is explicitly out of scope?
- Which existing document or sibling story most closely describes the shape of this work?
- What command would verify this story is done? (defaults to the track's `verificationCmd`)

### Fold-back rules

- Answers fold back into the staged draft as if they had been in the original source. Any field populated from the interview is annotated `derived-from-brainstorming` in the re-rendered preview.
- The brainstorming interview does not bypass the preview/confirm gate — the wrapper must still render the preview and return to the confirm prompt.
- If the user aborts the interview (or declines to answer), continue to the preview with the fields left empty. Do not force-answer on the user's behalf.

## AuditLog

Every mutation on `Story`, `AcceptanceCriterion`, or `StoryCapability` writes an `AuditLog` row server-side via `src/lib/audit.ts` in the P2E main repo. The plugin never calls audit helpers directly — it relies on the MCP layer to record history.
