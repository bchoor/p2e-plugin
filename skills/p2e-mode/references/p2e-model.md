# P2E model

Canonical entity and assessment facts. **`p2e-mode` points here** before drafting. Product repos may extend via `docs/P2E-lifecycle.md`.

## Graph

```
Product → Flow (persona | foundation) → Phase → UXO → Layer (Story)
  Layer holds: acceptance criteria, capabilities, relations → other layers
```

## Entities

| Entity | Is | Is not |
|--------|----|--------|
| **Product** | Whole map; bound via `.p2e/project.json` → `product_slug` | The git repo |
| **Flow** | Persona (journey) or Foundation (8 immutable platform slots) | A field on a layer |
| **Phase** | Journey step or one Foundation slot | Creatable on Foundation |
| **UXO** | Grouping bucket under a phase (`objectives[]` + `description`) | User-story prose (that is RRR on layers) |
| **Layer** | Landable work under a UXO (RRR, thick-spec, status, priority) | The whole feature |
| **Capability** | `INTRODUCES` / `MODIFIES` / `DEPRECATES` (+ `isBreaking`; `DEPRECATES` absorbs retired `REMOVES`) | A UXO objective |
| **Criterion** | One testable AC; verifier and reviewer assess separately | Bulk-approvable |
| **Relation** | `DEPENDS_ON` / `BUILDS_ON` / `FIXES` / `SUPERSEDES` | Containment |

Foundation slots are seeded and immutable. Journey → persona Flow; platform/infra → Foundation.

## Layer fields

**RRR:** `storyAs`, `storyWant`, `storySoThat`, `background`.

**Thick-spec:** `filesHint`, `constraints`, `nonGoals`, `contextDocs`, `effortHint`, `verificationCmd`. Thick = all six set. Thick gate (`validate op=run`) before `OPEN → IN_PROGRESS`.

**Sizing** (`XS`–`XXL`) and **priority** (`P0`–`P3` / `null`) are independent.

## Status vs AC blocked

- **`StoryStatus.BLOCKED`** — unfinished dependency (`DEPENDS_ON`) or equivalent wait.
- **AC verdict `BLOCKED`** — coder and verifier cannot align on that criterion; escalate to human.

Statuses: `DRAFT | OPEN | BLOCKED | IN_PROGRESS | IN_REVIEW | DONE | CANCELLED`.

## Assessments

Role ladder: **coder** → **verifier** → **reviewer** → **human**.

| Role | MCP usage |
|------|-----------|
| verifier | `criteria op=propose` with verifier role; `criteria op=list` includes verifier block |
| reviewer | `criteria op=propose` with reviewer role; `criteria op=list` with reviewer viewer role (verifier block omitted — blind invariant) |

Wire enum values for verifier and reviewer roles: read the live **`criteria`** tool schema at session start — MCP is authoritative. Plugin docs use **reviewer** only; never the retired role name.

Verdicts: verifier `PASS | FAIL | BLOCKED`; reviewer `PASS | FAIL` only. Absence / `NOT_TESTED` = unassessed.
- Agents write via `criteria op=propose`. `op=verdict` / `op=toggle` are not for agents.
- Reviewer is blind to verifier output — `criteria op=list` with reviewer viewer role (table above; verifier block omitted).
- Evidence attaches via `story_assets` (`criterion_id`); proof markdown via `evidence` tool where applicable.

## Tag shapes

- **backend** — automated/unit proof; digest/`ac{N}-proof.md` expected.
- **ui** — visual proof (screenshot/video); digest alone is insufficient.
- **external** — contract/integration proof; digest/`ac{N}-proof.md` expected.
- **docs** — short written note sufficient.
- **security** — security review expected in addition to other tags' shapes.

Multi-tag layers take the union of shapes.

## UXO facts

`objectives[]` are MECE noun phrases within the UXO; `description` synthesizes them. Layers land on objectives; gaps are new layers, not diluted objectives.

## Invariants

- MCP is authoritative — no parallel story state in files.
- Preview before writes on layers/UXOs/criteria/capabilities.
- Never create Foundation phases via MCP.
- Human Mark DONE is the sole acceptance gate for a layer.
