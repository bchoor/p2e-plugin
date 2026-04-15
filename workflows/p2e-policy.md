# P2E Workflow Policy

This file defines the shared operating rules for every P2E wrapper. The wrappers may differ, but the workflow semantics stay the same.

## MCP access

- All P2E mutations and reads go through the `mcp__p2e__*` tools exposed by the plugin.
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

- Fast => haiku for the implementer, no architect, no staff engineer.
- Standard => sonnet for the implementer, architect yes, staff engineer only when batch size warrants it.
- Architectural => sonnet for the implementer, architect yes, staff engineer yes.

Wrappers should treat `opus` as reserved for specialist subagents only when the workflow explicitly calls for them.

## Canonical orchestrator naming

- `work-on-next` is the canonical orchestrator name.
- Adapter-specific entrypoints may exist, but they should point at the same shared behavior.
- Workflow docs should describe behavior, not wrapper syntax.

## Thin drafts

- A thin draft is a story with no acceptance criteria and no capabilities.
- Thin drafts are valid planning artifacts and should not be treated as broken data.
- The orchestrator should surface thin drafts to the user before classification so they can be fleshed out, proceeded with as-is, or skipped.

## Status lifecycle

- The shared lifecycle is `PLANNED` -> `PARTIAL` -> `BUILT`.
- On wave start, stories move to `PARTIAL`.
- On successful completion, stories move to `BUILT` and their acceptance criteria are toggled.
- Failed or deferred work stays `PARTIAL` with a human-readable comment.

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

