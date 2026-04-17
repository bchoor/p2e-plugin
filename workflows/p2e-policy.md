# P2E Workflow Policy

This file defines the shared operating rules for every P2E wrapper. The wrappers may differ, but the workflow semantics stay the same.

## MCP access

- All P2E mutations and reads go through the P2E MCP surface and its operations exposed by the adapter.
- The MCP server handles authentication and audit logging. Wrappers must not invent their own auth or audit paths.
- The server URL may be configured by environment, but the workflow contract stays unchanged across environments.

## Adaptive router

When a workflow needs to classify a story or choose an execution track, use this order:

1. Any capability with `isBreaking: true` => Architectural track.
2. Any capability with action `DEPRECATES` or `REMOVES` => Architectural track.
3. Any tag in `{ data-model, migration, infra }` => Architectural track.
4. Acceptance criteria count >= 8 => Architectural track.
5. Any tag in `{ ui, docs, copy }` and acceptance criteria count <= 3 => Fast track.
6. Otherwise => Standard track.

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
- On successful verification + PR merge the orchestrator moves the story to `IN_REVIEW` and toggles its acceptance criteria.
- On two consecutive verification failures the orchestrator moves the story to `BLOCKED` and stops retrying (see `## Two-strike escalation`).
- Final acceptance (IN_REVIEW → DONE) is a human action outside the orchestrator's scope.

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
| Fast | typecheck + lint (`bun run typecheck && bun run lint`) |
| Standard | `bun run preflight` |
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
