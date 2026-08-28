---
name: p2e-mode
description: >-
  P2E operating mode for product intelligence — bind via .p2e/project.json,
  MCP lifecycle contract (IN_PROGRESS=code+verify; IN_REVIEW=blind opinion/human),
  and assessment gates. Use when working on P2E layers/stories, UXOs, verification,
  evidence, or when the user invokes /p2e-mode or runs it as a Custom Mode.
disable-model-invocation: true
icon: book-open
color: cyan
---

# p2e-mode

P2E is **product intelligence**: **Product → Flow → Phase → UXO → Layer** (`Story`). MCP is the write interface; UI and agents share the same actions. Domain state lives in MCP — never parallel story files.

Before create/update/UXO work: [`references/p2e-model.md`](references/p2e-model.md).

## Bind & scope

- `.p2e/project.json` → `product_slug` on every MCP call. No binding → create one before any other call.
- Legacy `project_slug` still accepted.

## Lifecycle

`DRAFT → OPEN → IN_PROGRESS → IN_REVIEW → DONE` (+ `BLOCKED`, `CANCELLED`)

- **`IN_PROGRESS`** — code + verify loop; evidence and VERIFIER assessments live here.
- **`IN_REVIEW`** — blind second opinion and/or human review; only a human may **Mark DONE**.
- Thick layers required for `OPEN → IN_PROGRESS`. No write without a confirmed preview.

## Gates & roles

Roles: **coder** → **verifier** → **reviewer** → **human**.

- Every AC needs a VERIFIER assessment before `IN_REVIEW`; none may be `NOT_TESTED`.
- Any VERIFIER `FAIL` → stay `IN_PROGRESS`.
- AC `BLOCKED` = coder/verifier cannot align → escalate to human (≠ `StoryStatus.BLOCKED`).
- Reviewer is blind to verifier output (`criteria op=list` + `viewer_role=AUDITOR`; MCP wire name unchanged).
- Coder never writes assessments; agents use `criteria op=propose`, never `op=verdict` / `op=toggle`.
- Release audit is a batch over DONE sets — not a story status.
- AuditLog on every mutation.
- Never create Foundation phases via MCP.

## Tags

Tags (`backend` / `ui` / `external` / `docs` / `security`) select the verify/evidence shape the gate expects — same lifecycle, different proof. Shapes: `references/p2e-model.md`.

## MCP

`products`/`flows`/`phases`/`uxos` · `stories` · `criteria` (`op=propose`) · `capabilities` · `relations` · `coverage` · `story_assets` · `story_log` · `validate` · `evidence`

## Pointers

- Model + tags: `references/p2e-model.md`
- Product repo (when present): `docs/P2E-lifecycle.md`, `docs/P2E-handover.md`
