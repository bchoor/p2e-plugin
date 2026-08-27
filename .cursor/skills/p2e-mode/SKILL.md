---
name: p2e-mode
description: >-
  P2E operating mode — product intelligence session entry: bind, MCP surface,
  story lifecycle, and Coder→Verifier→Auditor→Human review pipeline. Read at
  session start; read references/p2e-model.md before create/update/UXO work.
---

# p2e-mode

P2E is **product intelligence** — a living map of your product that grows iteratively. MCP is the write interface; UI and agents share the same server actions. **Never invent parallel story state in files.**

**Before create/update/UXO work, read:** [`references/p2e-model.md`](references/p2e-model.md) — canonical definitions and operating recipes.

**Product-repo docs (when present):** `docs/P2E-lifecycle.md`, `docs/P2E-handover.md`, `docs/feat-review-view/design.md`.

---

## Bind & scope

- Product binding: `.p2e/project.json` → `product_slug` on every MCP call.
- No binding → ask user to create one before project-scoped ops.
- Legacy `project_slug` param still accepted on MCP tools.

---

## Story lifecycle

`DRAFT → OPEN → IN_PROGRESS → IN_REVIEW → DONE` (+ `BLOCKED`)

| Who | Typical action |
|-----|----------------|
| Agent (coder) | Implement layer; ends at **IN_REVIEW** — never Mark DONE |
| Agent (verifier) | Tests + evidence + `criteria op=propose role=VERIFIER` |
| Agent (auditor) | Blind review + `criteria op=propose role=AUDITOR` |
| Human | Comments; **Mark layer DONE** (sole acceptance gate) |

Thick layers (ACs + capabilities + `verificationCmd`) before `OPEN → IN_PROGRESS`. See `references/p2e-model.md` for thick vs thin and the thick gate.

**Preview → confirm → write** for every MCP mutation on layers, UXOs, criteria, and capabilities.

---

## MCP essentials

| Tool | Use |
|------|-----|
| `products` / `flows` / `phases` / `uxos` | Graph structure |
| `stories` | Layer CRUD, `op=get`, `op=context`, `op=move` |
| `criteria` | AC CRUD; **`op=propose`** for agent assessments |
| `capabilities` | Change entries per layer |
| `relations` | Inter-layer edges |
| `coverage` | UXO health (DONE / partial / gap) |
| `story_assets` | Evidence (link `criterion_id`) |
| `story_log` | COMMENT, DECISION, BLOCKER, VERIFICATION |
| `validate` | Thick-gate predicate |
| `evidence` | Proof markdown validate/template |

**Agents:** use `criteria op=propose`, not `op=verdict` or `op=toggle`.

**Auditor blind:** `criteria op=list` with `viewer_role=AUDITOR` — response has no verifier block.

Entity definitions and create/update recipes: **`references/p2e-model.md`**.

---

## Review pipeline (IN_REVIEW)

1. **Verifier** — run `verificationCmd`, capture proof, upload assets, propose PASS/FAIL/BLOCKED per AC.
2. **Auditor** — read evidence + UXO/flow context only; propose PASS/FAIL per AC (never sees verifier verdict).
3. **Mismatch** — verifier ≠ auditor → human reads Review view / AC modal.
4. **Human** — Mark DONE when satisfied.

UI: `/{slug}/review`, AC Review modal, StagedProofViewer for proof markdown.

---

## Evidence (Cursor Cloud)

- Terminal: `verificationCmd` output in proof markdown
- UI: `RecordScreen` / `computerUse` @ 125% scale + `walkthrough-artifacts`
- Discipline: coding-tools **`verify`** — evidence before "done"
- Upload via `story_assets`; assessments via `op=propose` with one-line `summary` + optional `analysis`
- Backend ACs: `specs/ac-evidence-proof.v1.yaml` + `mcp__p2e__evidence op=validate_proof`

---

## Invariants

- MCP parity: every UI mutation has an MCP tool.
- AuditLog on every mutation.
- Specs in git (`specs/<slug>/`), read-only in P0.
- Never create Foundation phases via MCP — 8 slots are seeded and immutable.
- Coder does not write assessments; human does not per-AC approve in bulk.

---

*Legacy `/p2e-*` slash commands and granular workflow skills are deprecated — this file is the entry point.*
