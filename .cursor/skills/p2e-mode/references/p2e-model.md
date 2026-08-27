# P2E model — definitions and operating recipes

Canonical entity definitions and create/update/UXO recipes. **`p2e-mode` points here** before any drafting work. Product repos may extend via `docs/P2E-lifecycle.md`.

P2E is **product intelligence**: a living map that grows iteratively — not a one-shot spec generator.

---

## The graph

```
Product
  └── Flow (persona | foundation)
        └── Phase
              └── UXO
                    └── Layer (Story)
                          ├── Acceptance criteria
                          ├── Capabilities
                          └── Relations → other layers
```

---

## Definitions

| Entity | Is | Is not |
|--------|----|--------|
| **Product** | The whole product map, bound via `.p2e/project.json` → `product_slug`. | A repo — the repo is where the binding lives. |
| **Flow** | A lane of phases: **persona** (user journey) or **Foundation** (platform/infra; system-immutable). | A field on a layer — derive via UXO → Phase → Flow. |
| **Phase** | One journey step (persona) or one of 8 fixed Foundation slots (Surfaces, Security, Data, Compute, Build-Deploy, Distribution, Observability, Cross-cutting). | Creatable on Foundation — the 8 slots are seeded and immutable. |
| **UXO** | **User Experience Objective** — a **grouping bucket** for one coherent slice of product machinery under a phase. Holds `objectives[]` (3–6 MECE noun phrases) + one-sentence `description` synthesized from them. | A user narrative — RRR prose lives on layers. |
| **Layer** (Story) | One landable slice of work under a UXO: RRR + thick-spec + status + priority; advances one UXO objective. | The whole feature — a UXO holds many layers over time. |
| **Capability** | Concrete change on a layer: `INTRODUCES` / `MODIFIES` / `DEPRECATES` / `REMOVES` (+ `isBreaking`). | A UXO objective — objectives name scope; capabilities name change. |
| **Criterion** (AC) | One testable acceptance condition; verifier and auditor assess separately in review. | A capability; not bulk-approvable. |
| **Relation** | Typed edge between layers (`DEPENDS_ON`, `BUILDS_ON`, `FIXES`, `SUPERSEDES`). | Containment — that's UXO → layer. |

**What is a UXO?** Despite the name, a User Experience Objective is **not** a user story or UX write-up. It is the map's **grouping construct** — the bucket that answers "what machinery does this part of the product own?" Think machine part (session lifecycle, membership roster, deploy pipeline), not user journey prose. `objectives[]` name the concerns the bucket owns (MECE within the UXO); **layers** under it carry RRR, capabilities, and ACs that land on those objectives. One UXO typically holds many layers over time.

**Foundation vs persona:** Journey work → persona Flow. Platform/infra → Foundation slots. ADRs (`docs/adrs/`) link from Foundation UXOs via `spec_file`; description references the decision, does not restate it.

---

## Layer anatomy

**RRR:** `storyAs`, `storyWant`, `storySoThat`, `background` — intent prose on the layer.

**Thick-spec (readiness before implementation):**

| Field | Purpose |
|-------|---------|
| `filesHint` | Paths/globs likely touched |
| `constraints` | Hard requirements, invariants |
| `nonGoals` | Explicit out-of-scope |
| `contextDocs` | ADRs, specs to read first |
| `effortHint` | `medium` … `max` |
| `verificationCmd` | Shell command that proves done |

**Sizing vs priority:** `sizing` (`XS`–`XXL`, effort + review cost; default `M`) and `priority` (`P0`–`P3` / `null`, queue order) are **independent axes**.

**Thick vs thin:** Thick = all six thick-spec fields populated (default for implementable work). Thin = title + RRR + conservative ACs for fast capture. Both require **preview → confirm → write**. Thick gate (`validate op=run`) must pass before `OPEN → IN_PROGRESS`.

---

## UXO recipe (distilled)

1. Draft **`objectives[]` first**, `description` last — description-first contaminates objectives.
2. **MECE within the UXO**, not across siblings.
3. **Landing test:** every existing story under the UXO lands on exactly one objective (zero → missing objective; two → overlap).
4. Objectives are **noun phrases** — no imperative verbs, no library names. Gaps become thin DRAFT layers, not diluted objectives.

---

## Things to do

### Create a layer

- **Place:** persona vs Foundation slot → pick or create UXO (`flows`, `phases`, `uxos`).
- **Context:** `stories op=context` with `uxo_id` — note DONE capabilities, IN_PROGRESS siblings.
- **Draft:** title, RRR, ACs, capabilities, priority; thick fields unless fast capture.
- **Preview** with provenance (`stated-by-user` / `derived-from-source` / `defaulted`) → confirm.
- **Write (fail-fast):** `stories op=create` → `criteria` → `capabilities` → `create_github_issue` → link issue.

### Update a layer

- `stories op=get` → **thicken** (fill empty) | **steer** (diff populated) | `op=move` | rename `story_id` | set priority | promote to OPEN (thick gate) | link PR.
- Same preview → confirm → write. Surface `validate op=run` failures.
- Mid-flight negotiation → `story_log op=append` (`DECISION` / `SCOPE_CHANGE` / `BLOCKER` / `COMMENT`).

### Thicken

- Anchor `stories op=context`; fill six fields from: layer's own title+fields → linked source → siblings/graph.
- **Empty beats invented filler.** Annotate provenance on every filled field.
- Infer sizing from title + capabilities + AC count + tags; default `M`.

### Manage a UXO

- Read stories under it (`stories op=list uxo_id=`).
- Rewrite `objectives[]` (3–6 MECE noun phrases; run landing test), then `description` as one-sentence synthesis.
- Gaps → thin DRAFT layers or propose new UXO to user; never silently create UXOs.

### Pick next work

- `coverage op=get` for UXO health.
- Queue: `P0 → P3 → null`, then oldest-first, across all Flows.
- Skip unresolved `DEPENDS_ON`; thick gate before `IN_PROGRESS`.

### Build iteratively

- Small landable layers, not monolithic drops.
- Chain with relations; each DONE layer enriches the graph for the next.
- Read the graph before drafting — never greenfield without checking siblings and shipped capabilities.

---

## Invariants

- MCP is authoritative — no parallel story state in files.
- Preview before every write.
- Never create Foundation phases via MCP.
- Coder ends at `IN_REVIEW`; human Mark DONE is the sole acceptance gate.
