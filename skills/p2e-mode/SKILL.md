---
name: p2e-mode
description: >-
  P2E operating mode for product intelligence — bind via .p2e/project.json,
  MCP lifecycle contract (IN_PROGRESS=code+verify; IN_REVIEW=blind opinion/human),
  and assessment gates. Use when working on P2E layers/stories, Waves, UXOs,
  verification, evidence, or when the user invokes /p2e-mode or runs it as a Custom Mode.
disable-model-invocation: true
icon: book-open
color: cyan
---

# p2e-mode

P2E is **product intelligence**: **Product → Flow → Phase → UXO → Layer** (`Story`), plus **Release → Wave** packages. MCP is the write interface; UI and agents share the same actions. Domain state lives in MCP — never parallel story files.

Before create/update/UXO/Wave work: [`references/p2e-model.md`](references/p2e-model.md).

## Bind & scope

- `.p2e/project.json` → `product_slug` on every MCP call. No binding → create one before any other call.
- Legacy `project_slug` still accepted.

## Lifecycle

`DRAFT → OPEN → IN_PROGRESS → IN_REVIEW → DONE` (+ `BLOCKED`, `CANCELLED`)

| Who | Typical action |
|-----|----------------|
| **coder** | Implement layer; ends at **IN_REVIEW** — never Mark DONE |
| **verifier** | Tests + evidence + `criteria op=propose` (verifier role) |
| **reviewer** | Blind review + `criteria op=propose` (reviewer role) |
| **human** | Comments; **Mark layer DONE** (sole acceptance gate) |

- **`IN_PROGRESS`** — code + verify loop; evidence and verifier assessments live here.
- **`IN_REVIEW`** — blind second opinion and/or human review; only a human may **Mark DONE**.
- Thick layers required for `OPEN → IN_PROGRESS`. No write without a confirmed preview.

## Gates & roles

Roles: **coder** → **verifier** → **reviewer** → **human**. Assessment facts: [`references/p2e-model.md`](references/p2e-model.md#assessments).

- Every AC needs a verifier assessment before `IN_REVIEW`; none may be `NOT_TESTED`.
- Any verifier `FAIL` → stay `IN_PROGRESS`.
- AC `BLOCKED` = coder/verifier cannot align → escalate to human (≠ `StoryStatus.BLOCKED`).
- Reviewer is blind to verifier output — `criteria op=list` with reviewer viewer role only.
- Coder never writes assessments; agents use `criteria op=propose`, never `op=verdict` / `op=toggle`.
- Release audit is a batch over DONE sets — not a story status.
- AuditLog on every mutation.
- Never create Foundation phases via MCP.

## Wave packages (BUILD)

**Wave** is a first-class unbounded package (`W{n}`, `n ≥ 1` — **no W25 ceiling**). Facts: [`references/p2e-model.md`](references/p2e-model.md#wave-package).

Before listing or executing BUILD work for a package:

1. `waves.get` (by `id` or `release` + `n`) — freeze: members, gate, branch, status, shipChecks, PR.
2. Prefer the returned **ordered members** as the BUILD set.
3. Do not treat `stories.list` wave filters as a substitute for package membership.

Create/update packages via `waves` (`n=auto` or explicit); membership rewrite stamps `Story.wave`.

## Review pipeline (`IN_REVIEW`)

1. **Verifier** — run `verificationCmd`, capture proof, upload assets, propose PASS/FAIL/BLOCKED per AC.
2. **Reviewer** — read evidence + UXO/flow context only; propose PASS/FAIL per AC (never sees verifier verdict). Do not read `story_log` or inline log entries from `stories op=get` — they leak verifier output.
3. **Mismatch** — verifier ≠ reviewer → human reads Review view / AC modal.
4. **Human** — Mark DONE when satisfied.

## Tags

Tags (`backend` / `ui` / `external` / `docs` / `security`) select the verify/evidence shape the gate expects — same lifecycle, different proof. Shapes: `references/p2e-model.md`.

## MCP

`products`/`flows`/`phases`/`uxos` · **`waves`** (`list`/`get`/`create`/`update`) · `stories` · `criteria` (`op=propose`) · `capabilities` · `relations` · `coverage` · `story_assets` · `story_log` · `validate` · `evidence`

## Pointers

- Model + Wave + tags: `references/p2e-model.md`
- Release reviewer subagent (Cursor): `.cursor/agents/p2e-reviewer.md`
- Product repo (when present): `docs/P2E-lifecycle.md`, `docs/P2E-handover.md`
