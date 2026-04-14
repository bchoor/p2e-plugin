---
name: p2e
description: P2E plugin policies + persona router. Loaded whenever /p2e-* commands run. Describes the adaptive persona router that classifies stories, MCP tool usage policy, and cross-cutting plugin rules.
---

# p2e plugin — operating policies

## MCP access

All p2e work goes through the `mcp__p2e__*` tools registered by this plugin's `.mcp.json`. Auth is handled by Claude Code's MCP OAuth flow — no bearer tokens to manage manually.

The MCP server URL defaults to `https://p2e-mocha.vercel.app/api/mcp` (the hosted demo). Point at your own instance with `P2E_MCP_URL`:

```
export P2E_MCP_URL="https://<your-p2e-instance>/api/mcp"
```

### Audit trail (server-side)

Every MCP mutation writes an `AuditLog` row via the server actions (per the main P2E repo's CLAUDE.md core invariant #2). The plugin NEVER calls audit helpers directly — the server handles this.

## Adaptive persona router

When executing stories, classify each using these rules (in order):

1. Any capability with `isBreaking: true` → **Architectural** / sonnet
2. Any capability with action `DEPRECATES` or `REMOVES` → **Architectural** / sonnet
3. Any tag in `{ data-model, migration, infra }` → **Architectural** / sonnet
4. AC count ≥ 8 → **Architectural** / sonnet
5. Any tag in `{ ui, docs, copy }` AND AC count ≤ 3 → **Fast** / haiku
6. Else → **Standard** / sonnet

| Track | Model (implementer) | Architect (`p2e-architect`) | Staff Engineer (`p2e-staff-engineer`) | Plan skill | TDD |
|---|:-:|:-:|:-:|:-:|:-:|
| Fast | haiku | no | no | inline short plan | loose |
| Standard | sonnet | yes | no (unless N≥2 batch) | `superpowers:writing-plans` | required |
| Architectural | sonnet | yes | yes | `superpowers:writing-plans` | required |

> **Model footnote:** Opus is reserved for `p2e-architect` and `p2e-staff-engineer` agents (pinned via `model: opus` in their frontmatter). Implementer subagents always run at the track-mapped model. Override requires explicit `opus-justified:` in the spawn brief.

`--full-team` on `/p2e-work-on-next-story` forces Architectural for every selected story.

## Status transitions (v1)

Interim shim until P-07-L1 replaces it with OPEN / IN_PROGRESS / DONE + health:

- On wave start (per story): `mcp__p2e__stories` update status → `PARTIAL`.
- On wave-gate pass: `mcp__p2e__stories` update status → `BUILT` + `mcp__p2e__criteria` toggle all AC.
- On wave-gate fail (user picks "mark PARTIAL"): leave as `PARTIAL`; comment on the GH issue with findings.

## GH issue contract

- `/p2e-add-story` auto-creates a GH issue with label `ready` after every successful MCP write. No opt-out.
- `/p2e-work-on-next-story` moves labels `ready` → `review` on wave-gate pass.
- Every issue comment + PR body authored by this plugin ends with `— bchoor-claude`.

## Batch write fail-fast

`/p2e-add-story` writes stories, criteria, capabilities in separate `items:[...]` calls. If call N fails, the earlier calls are already persisted — there is NO automatic rollback. Surface the failure clearly: which phase failed (stories / criteria / capabilities), which item index within the failing batch, and tell the user the successful rows they'll need to reconcile manually (e.g., re-run the failed phase only, or clean up partial data via the P2E UI).

## Tag hygiene

Before passing tags to MCP, normalize: lowercase, trim, replace whitespace with `-`. The router consumes these (`ui`, `data-model`, `migration`, `infra`, `docs`, `copy`).

## No destructive mutations without confirmation

Never delete capabilities or criteria in response to a skill-level workflow. Deprecation uses `action: "DEPRECATES"` on a new layer. `/p2e-add-story` only creates; `/p2e-work-on-next-story` only updates.

## Concepts

External agents: read this section before proposing map changes. You do NOT need to open `docs/P2E-lifecycle.md` or `docs/P2E-handover.md` to plan work — everything you need to classify, locate, and shape a layer is here.

### Journey — phase column

A **Journey** is the left-to-right sequence of **Phases** on the story map. Each phase is one step the user moves through (e.g. Discover → Acquire → Build → Evolve). A phase is a column; it has no tier.

### UXO — phase × tier objective

A **UXO (User Experience Objective)** is a concrete feature objective that lives in one **(phase, tier)** cell. It is NOT an abstract benefit — think "Technical charting", not "helps users understand their data". A UXO has:

- `uxoId` — human-readable like `R-06`, `P-01` (unique per project, scoped by phase)
- `title` — short noun phrase
- `objective` — optional description (the original benefit sentence, if any)
- a tier: `CORE` (must-have for phase to work), `ADVANCED` (improves phase), `STRETCH` (delights / differentiates)

**Tier semantics:** CORE is baseline viability for the phase. ADVANCED raises quality once CORE is built. STRETCH is exploratory / aspirational.

**Health roll-up:** A UXO's status is derived from its layers — `storyCount`, `builtCount`, `conflictCount`, `driftDetected` are computed on read. Do not assume cached values are authoritative.

### Layer (Story) — stacking unit of work

A **Layer** (the DB entity is still `Story`, and the MCP tool is `stories`) is one unit of shipped work under a UXO. Layers stack **chronologically and cumulatively** — L2 does not override L1; together they describe the UXO's evolution.

- `storyId` convention: `<uxoId>-L<n>` — e.g. `R-06-L3` is the 3rd layer under UXO `R-06`.
- Status: `PLANNED` / `PARTIAL` / `BUILT` / `GAP`.
- Layers carry: a title, a user-story triplet (`as / want / so that`), acceptance criteria, capabilities (change entries), and relations to other layers.

To find the "next" layer id, look at the highest `L<n>` under the target UXO and add one.

### Capabilities — typed change entries within a layer

A layer's **capabilities** (`StoryCapability` rows) describe what that specific layer changed. Each entry has an action:

| Action | Meaning |
|---|---|
| `INTRODUCES` | Added a new capability (most common for L1 and new surface) |
| `MODIFIES` | Intentionally changed an existing capability's behavior |
| `FIXED` | Corrected a prior defect; optionally links to the offending layer via `fixesLayerId` |
| `DEPRECATES` | Marked a capability as deprecated; still works but is on the way out |
| `REMOVES` | Removed a capability — consumers must update |

Orthogonal flag: `isBreaking` — set this when the change breaks existing consumers regardless of action.

**Fold rule:** A UXO's current state at any point in time = fold of all change entries across its **BUILT** and **PARTIAL** layers, minus anything `DEPRECATES`d or `REMOVES`d. Capabilities are narrative; they do not mutate a separate "capability store".

### Relations — 10 typed edges between layers

Layers connect via `StoryRelation` rows. Use the relation type that best describes the narrative intent:

| Relation | Use when |
|---|---|
| `BUILDS_ON` | Layer extends a prior layer's surface without changing it (most common) |
| `MODIFIES` | Layer changes a prior layer's behavior |
| `CONFLICTS_WITH` | Two layers contradict each other; needs resolution |
| `REPLACES` | New layer supersedes an old one entirely |
| `DEPRECATES` | Marks a prior layer as deprecated (capability-level uses `action: DEPRECATES` instead) |
| `REMOVES` | Removes a prior layer's surface |
| `DEPENDS_ON` | Cannot ship until the target layer is BUILT |
| `RELATED_TO` | Thematic link with no hard coupling (rare; prefer a stronger type when possible) |
| `FIXES` | Narrative-level: "this layer fixes that layer" (pair with `FIXED` capability action when applicable) |
| `PART_OF` | Parent/child sub-story relation (reserved for future hierarchy work) |

### Product → Projects (forward-looking)

**Pending until P-08-L1 is BUILT.** The current model has `Project` as the top-level container. P-08-L1 introduces `Product` as the parent of many `Project`s, plus a cross-project release view. Until P-08-L1 ships, treat each `project_slug` as the outer boundary of any plan. Agents **may** draft work that would benefit from the Product concept, but should note the dependency and not call MCP tools that do not yet exist.

## Planning recipe for external agents

Use this when you are an LLM agent in an external repo and you want to propose new work against a P2E project.

1. **Pick a phase.** Call `mcp__p2e__projects` with `{ op: "get", project_slug }` to see the journey. Choose the phase that matches the user step your proposed work improves.

2. **Match or propose a UXO.** Scan the phase's UXOs across `CORE` / `ADVANCED` / `STRETCH`. If one already matches your proposed work, reuse it — new layers should stack under existing UXOs when possible. If nothing fits, propose a new UXO: pick a tier (CORE if the phase cannot work without it, ADVANCED if it improves the phase, STRETCH if exploratory), a human-readable `uxoId`, and a short `title`.

3. **Propose the next layer id.** Call `mcp__p2e__stories` with `{ op: "list", project_slug, uxo_id }` — find the highest `L<n>`. Next layer id is `<uxoId>-L<n+1>`.

4. **Draft capabilities + AC.** For each user-visible change, draft a `StoryCapability` with the correct action (`INTRODUCES` for net-new, `MODIFIES` for behavior change, `FIXED` for defect correction, etc.) and set `isBreaking` only when existing consumers actually break. For each acceptance criterion, write a Given/When/Then sentence that an agent could verify against the UI or MCP surface.

5. **Call `/p2e-add-story` or MCP directly.** Preferred: run `/p2e-add-story` — it batches the stories/criteria/capabilities writes, auto-creates the GH issue, and follows the rules in this skill. Direct MCP is acceptable when you are scripting. Remember: every MCP mutation writes an AuditLog row server-side. Do not attempt to write audit entries yourself.
