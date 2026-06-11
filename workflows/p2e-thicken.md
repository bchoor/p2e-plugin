# P2E Thicken Recipe

This file is the single source of truth for the thick-drafting recipe used by both `workflows/p2e-add-story.md` (thick mode) and `workflows/p2e-update-story.md` (Thicken path). Domain logic lives here; both workflows reference it by pointer.

## Context gathering

Before drafting thick-spec fields, gather story-graph context to surface what has already been built or is in-flight nearby.

### Primary path: `stories op=context`

Call `mcp__p2e__stories op=context` with:

- `project_slug` — from `.p2e/project.json`
- `story_id` OR `uxo_id` — the anchor for the current operation (pass exactly one):
  - **update-story (existing story):** `story_id` of the story being thickened
  - **add-story (new UXO story):** `uxo_id` of the target UXO
- `depth` — `1` (default) or `2` for wider traversal; use depth 2 only when the story has few siblings or weak relations
- `context_limit` — per-section row cap; default `20`; raise only when you have evidence the default is leaving important context out. Note: `context_limit` is distinct from `limit`, which remains the `op=list` pagination parameter.
- `include_cancelled` — default `false`; CANCELLED stories are excluded unless explicitly requested

**Response shape differs by anchor type:**

When anchored by `story_id`, the response contains:
- `anchor` — slim story row for the anchored story itself
- `relations[]` — stories in a DEPENDS_ON / BUILDS_ON / etc. relation; relation type and direction are encoded in each row's `roles[]` array (see Row shape below)
- `siblings[]` — other stories under the same UXO
- `phase_peers[]` — stories in other UXOs within the same phase

When anchored by `uxo_id`, the response contains:
- `anchor: null` (no single story anchor)
- `relations: []` (empty — no story to traverse from)
- `siblings[]` — existing stories already under this UXO
- `phase_peers[]` — stories in other UXOs within the same phase
- `uxo_chain[]` — all UXOs in the phase with their stories (for placement context)

**Row shape (both anchor types):** every story row is compact — `storyId`, `title`, `status`, `release`, `roles[]` (e.g. `"relations:DEPENDS_ON:outbound"`), and `capabilities[]` with `action`, `name`, `isBreaking`. No RRR prose. A story that appears in multiple sections is deduplicated into one row with a combined `roles[]` array.

**Using the returned context:**

1. Identify capabilities already DONE (INTRODUCES/MODIFIES in a DONE story) so you don't re-propose them.
2. Surface IN_PROGRESS work that the new story must not collide with.
3. Inform `filesHint` and `constraints` fields (sibling stories that touch similar files are a strong signal).
4. Cite as `derived-from-source: context:op=context anchor=<anchor>` in provenance annotations on any field that was filled using the returned context.

### Fallback when `op=context` is unavailable

If the connected backend does not support `stories op=context` (older backend), fall back to:

1. `mcp__p2e__stories op=get story_id=<anchor_story_id> include=["relations", "siblings"]` — for update-story flows where the story already exists.
2. `mcp__p2e__relations op=stack project_slug=<slug> story_id=<anchor_story_id>` — fetches the transitive relation stack.

**Cost warning:** the fallback issues two additional MCP round trips and returns less structured context than `op=context`. Surface this in the flow log if the fallback activates: `"Context gathered via fallback (op=get+relations/stack); op=context unavailable on this backend."` Continue to thick-spec drafting with whatever context was obtained.

## Thick-spec field population

Populate the six thick-spec fields from these sources **in priority order**:

1. **Story's own title + populated fields** — the strongest signal; always read first.
2. **The `source` argument** (a PRD path, GitHub issue URL, or spec YAML under `specs/<projectSlug>/`) — when provided, read it in full before any inference.
3. **Graph context / sibling stories** — use the neighbors returned by `## Context gathering` above; cite the source story id in the annotation.

Rules for each field:

- **`filesHint`** — list files or directories the story is likely to touch; infer from the title, capabilities, sibling `filesHint` values, and graph-context capability names. Each entry is a relative path or glob.
- **`constraints`** — hard requirements or anti-requirements (backwards-compat, platform, security, timezone, etc.). Only populate from concrete evidence; do not invent.
- **`nonGoals`** — explicit out-of-scope items that prevent scope creep. Derive from the title, source, or sibling stories that share the UXO.
- **`contextDocs`** — relative paths of reference docs the executor should read (ADRs, specs, related workflow docs). Derive from linked spec files, `docs/adrs/`, or sibling `contextDocs`.
- **`effortHint`** — `medium | high | xhigh | max`; infer from the sizing tier (see `## Sizing inference`). Use `high` for L, `xhigh` for XL, `max` for XXL, `medium` for M and below.
- **`verificationCmd`** — the shell command that confirms the story is done. Derive from the track-default in `workflows/p2e-policy.md → ## Verification matrix`, the sibling stories' `verificationCmd` values, or source docs. Leave empty if no concrete command is evident.

**Empty cells are preferred over filler.** If no source supports a field, leave it empty — do not invent values. Each populated field must carry a provenance annotation (`derived-from-source: <source>` or `derived-from-brainstorming`).

## Sizing inference

Sizing is inferred at draft time using the staged post-draft projection (title + capabilities + AC count + tags + `filesHint` length), not the pre-draft state. The inference runs five inputs:

1. **Title** — scanned for the bump-triggers `rewrite`, `migrate`, `redesign`, `refactor`, `extract`.
2. **Capabilities** — count of capabilities and whether any has `isBreaking: true`.
3. **Acceptance criteria count** — `≤ 3` and `≥ 8` thresholds per the rubric.
4. **Tags** — normalized (lowercased, trimmed, whitespace → `-`), matched against the weighting table.
5. **`filesHint` length** — `≥ 7` and `≥ 12` thresholds per the rubric.

The canonical tier definitions (XS → XXL), the weighting rules, and worked examples live in `workflows/p2e-sizing-rubric.md`. Do not re-invent them here — always reference the rubric.

The annotation cites the specific inputs that forced the tier. Examples:

> `derived-from-source: 3 capabilities + 6 AC + Schema tag → L`
> `derived-from-source: 2 capabilities + 2 AC + Docs tag + 1 filesHint → S`
> `derived-from-source: isBreaking capability + UI tag + 9 AC → XL`

The inferred tier is a proposal; the user can override it in the confirm step.

**`effortHint` mapping from inferred tier:**

| Inferred sizing | effortHint |
|---|---|
| XS, S | medium |
| M | medium |
| L | high |
| XL | xhigh |
| XXL | max |

## Signal annotation for execution-time routing

After populating thick-spec fields, ensure the story carries the signals the execution-time adaptive skill matrix in `workflows/p2e-policy.md → ## Adaptive skill matrix` will read at work-on-next dispatch time. There is no separate annotation channel — the fields themselves are the signals:

- **Tags** — add or confirm `ui` if the story has a clearly UI-facing request (AC or capability names a visible surface, component, or layout). Add `bug`/`fix` if the story repairs broken behavior. Do not invent tags beyond what the source supports.
- **Capabilities** — mark `isBreaking: true` on any capability that changes a public API, an exported action signature, a schema, or a behavior contract that existing callers depend on.
- **`filesHint`** — populated per the field-population rules above; the matrix reads whether it spans ≥ 3 top-level directories to decide whether to invoke the `feature-dev` phased pattern.

These fields are part of the normal thick-spec output; no additional step is needed beyond filling them correctly.

## Brainstorming trigger

If, after the first thick-spec draft pass, ≥ 2 of the six thick-spec fields (`filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`) are still empty AND neither the source argument nor sibling stories under the same UXO supply evidence to fill them, escalate exactly once to the host brainstorming primitive. See `## Brainstorming escalation` in `workflows/p2e-policy.md` for the canonical trigger conditions, question shape, and fold-back rules.

Do NOT escalate for thin mode. Do NOT escalate more than once per flow. Empty cells are preferred over filler if the brainstorming answers still leave gaps.
