---
name: p2e-mode
description: >-
  P2E operating mode — entity model, MCP surface, story lifecycle, and
  Coder→Verifier→Auditor→Human review pipeline. Read at the start of any
  P2E session. One mode, not a menu of /p2e-* commands.
---

# p2e-mode

P2E maps product journeys to engineering work: **Product → Flow → Phase → UXO → Layer** (layer = `Story`). MCP is the write interface; UI and agents share the same server actions.

**Read when needed:** `docs/P2E-lifecycle.md` (terminology), `docs/P2E-handover.md` (product/tech), `docs/feat-review-view/design.md` (review pipeline).

## Bind & scope

- Product binding: `.p2e/project.json` → `product_slug` on every MCP call.
- No binding → ask user to create one before project-scoped ops.
- Legacy `project_slug` param still accepted on MCP tools.

## Story lifecycle

`DRAFT → OPEN → IN_PROGRESS → IN_REVIEW → DONE` (+ `BLOCKED` side path)

| Who | Typical action |
|-----|----------------|
| Agent (coder) | Implement layer; ends at **IN_REVIEW** — never Mark DONE |
| Agent (verifier) | Tests + evidence + `criteria op=propose role=VERIFIER` |
| Agent (auditor) | Blind review + `criteria op=propose role=AUDITOR` |
| Human | Comments; **Mark layer DONE** (sole acceptance gate) |

Priority (`P0`…`P3`) orders open work. Thick stories (ACs + capabilities + verification command) before `OPEN → IN_PROGRESS`.

## MCP essentials

Domain state lives in MCP — do not invent parallel file-based story state.

| Tool | Use |
|------|-----|
| `stories` | CRUD layers, status, `op=get` with includes |
| `criteria` | AC CRUD; **`op=propose`** for agent assessments; `op=list` for verifier/auditor/mismatch |
| `story_assets` | Evidence upload (link `criterion_id`) |
| `story_log` | COMMENT, DECISION, BLOCKER, VERIFICATION — not duplicate status flips |
| `capabilities` / `relations` | Change entries and layer graph |

**Agents:** use `criteria op=propose`, not `op=verdict` or `op=toggle`.

**Auditor blind:** `criteria op=list` with `viewer_role=AUDITOR` — response has no verifier block.

## Review pipeline (IN_REVIEW)

1. **Verifier** — run `verificationCmd`, capture proof, upload assets, propose PASS/FAIL/BLOCKED per AC.
2. **Auditor** — read evidence + UXO/flow context only; propose PASS/FAIL per AC (never sees verifier verdict).
3. **Mismatch** — verifier ≠ auditor on an AC → human should read Review view / AC modal.
4. **Human** — Mark DONE when satisfied (warn on mismatch/fail/unassessed; never hard-block).

UI: `/{slug}/review`, AC Review modal, StagedProofViewer for proof markdown.

## Evidence (Cursor Cloud)

Prefer first-class tools over shell/ffmpeg pipelines:

- Terminal: `verificationCmd` output in proof markdown
- UI: `RecordScreen` / `computerUse` @ 125% scale + `walkthrough-artifacts`
- Discipline: coding-tools **`verify`** — evidence before "done"

Upload via `story_assets`; assessments via `op=propose` with one-line `summary` + optional `analysis`.

## Invariants

- MCP parity: every UI mutation has an MCP tool.
- AuditLog on every mutation.
- Specs in git (`specs/<slug>/`), read-only in P0.
- Coder does not write assessments; human does not per-AC approve.
- Never create Foundation phases via MCP — the 8 Foundation slots are seeded and immutable.

## Subagents (optional)

When splitting work: `p2e-story-lead` (code), `p2e-verifier`, `p2e-auditor`. Supervisor owns status flips.

---

*Legacy `/p2e-*` slash commands and granular workflow skills are deprecated in this repo — this file is the entry point.*
