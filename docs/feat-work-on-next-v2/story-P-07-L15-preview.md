---
title: Story preview — P-07-L9 (work-on-next v2 supervisor)
hash: 0843ae6
status: draft
date: 2026-06-11
owner: bchoor
---

# Story preview — `P-07-L9`

Thick-mode preview for `/p2e-add-story --thick`. Nothing below has been written to P2E yet — this is the confirm-gate render. Provenance: every field is `derived-from-source` (the approved plan at `docs/feat-work-on-next-v2/plan.md`) unless marked otherwise.

## Placement

| Field | Value | Provenance |
|---|---|---|
| story_id | `P-07-L9` (server auto-appends next layer under `P-07`) | auto |
| UXO | attach to existing `P-07` — "Story lifecycle + health" | matched: same UXO as P-07-L8 (the v0.10.5 ladder story) |
| Phase / Flow | **Plan** / persona Flow "Build the product" | from UXO |
| Status | `OPEN` | thick spec passes the isThick predicate |
| Release | `v0.11` | derived: sibling P-07-L8 release |
| Tags | `plugin`, `workflow` | derived-from-source |
| Sizing | **XL** | derived-from-source: title "Rewrite" bump + isBreaking capability + 11 filesHint + 8 AC → XL |
| Priority | `null` | defaulted (no urgency phrase in the request) |
| effortHint | `high` | derived-from-source |

## Title

> Rewrite /p2e-work-on-next as v2 supervisor: story-lead waves, adaptive skills, tiered reviews

## RRR

- **As** a developer running /p2e-work-on-next
- **I want** the orchestrator to act as a supervisor that dispatches parallel story-lead subagents in waves, with adaptive skill selection and exactly one primary review per story
- **So that** multiple stories execute concurrently in one session without the main session hand-driving 6 tasks per story, ending at IN_REVIEW with releases left to me

**Background:** v0.10.5 shipped a 6-step TaskCreate ladder that forces the main session to drive 6N tasks for an N-story batch. Nested subagents (depth ≤ 5) and dynamic Workflows now make a supervisor architecture possible: the main session (fable high-effort recommended) plans/dispatches/reviews while p2e-story-lead agents own each story's lifecycle. Approved decisions: hybrid substrate (story-leads + Workflow batch mode at N≥4), one TaskCreate per story, track-tiered single-primary reviews, and no in-loop release. Implementation plan: docs/feat-work-on-next-v2/plan.md.

## Acceptance criteria (8)

1. `workflows/p2e-work-on-next.md` defines supervisor Phases 0–4 (Select & gate / Plan & confirm / Execute waves / Close per story / End of run); the "N/6" ladder vocabulary appears nowhere in the repo.
2. `workflows/p2e-policy.md` contains new sections `## Model ladder`, `## Adaptive skill matrix`, and `## Review tiering`.
3. `agents/p2e-story-lead.md` exists with `model: sonnet`, the 5-step lifecycle (plan → implement via nested workers → verify with one internal retry → commit+PR → tiered review), a JSON report contract field-identical to the one in the workflow doc, and hard rules forbidding status writes, AC toggles, and any release invocation.
4. The workflow documents one TaskCreate per story titled `[#<story-id>] <story title>` with TaskUpdate description transitions (briefed → implementing → verifying → PR open → in review → IN_REVIEW/BLOCKED); the 6N ladder is gone.
5. The workflow documents dynamic-Workflow batch mode (auto at N ≥ 4 or `--workflow`) with the per-wave script skeleton, explicitly marked Claude-Code-only with Codex/Cursor sequential fallback.
6. Review tiering is normative: Fast → `/code-review` pre-PR; Standard/Architectural → `pr-review-toolkit:review-pr` post-PR; `/security-review` only on globset/Security-slot/`--security` triggers; the workflow states the orchestrator never invokes `/p2e-cut-release` or `/ultrareview`.
7. All three wrappers updated (Claude command gains `limit=` and `--workflow`; Codex and Cursor wrappers document the sequential fallback); `hooks/pre-agent-spawn-story-status.sh` still gates `p2e-story-lead` spawns (not allowlisted) and passes `bash -n`.
8. `workflows/p2e-ship-batch.md` Phase B re-pointed to v2 phase names with Phase D review dedup; `skills/p2e/SKILL.md` router line, README command table, and CHANGELOG Unreleased entry updated; cross-platform checklist from `reference/cross-platform-pattern.md` passes.

## Capabilities (4)

| # | Capability | Action | Breaking | Description |
|---|---|---|---|---|
| 1 | `p2e_plugin.work_on_next_workflow` | MODIFIES | **yes** | Supervisor architecture replaces the 6-step TaskCreate ladder; removes the in-loop release step (stories end at IN_REVIEW). |
| 2 | `p2e_plugin.story_lead_agent` | INTRODUCES | no | New agents/p2e-story-lead.md: per-story lifecycle owner dispatched per wave, returns structured JSON report. |
| 3 | `p2e_plugin.policy_matrices` | INTRODUCES | no | Policy gains Model ladder, Adaptive skill matrix (frontend-design / feature-dev / systematic-debugging / TDD by story signals), and Review tiering sections. |
| 4 | `p2e_plugin.ship_batch_workflow` | MODIFIES | no | Phase B references re-pointed to v2 phases; Phase D skips duplicate review-pr when the in-loop review already ran. |

## Thick-spec fields

**filesHint (11):**
1. `workflows/p2e-work-on-next.md`
2. `workflows/p2e-policy.md`
3. `agents/p2e-story-lead.md`
4. `hooks/pre-agent-spawn-story-status.sh`
5. `commands/p2e-work-on-next.md`
6. `skills/p2e-work-on-next/SKILL.md`
7. `.cursor/skills/p2e-work-on-next/SKILL.md`
8. `workflows/p2e-ship-batch.md`
9. `skills/p2e/SKILL.md`
10. `README.md`
11. `CHANGELOG.md`

**constraints (5):**
1. Cross-platform compliance: behavior lives in workflows/, wrappers stay thin; Codex/Cursor get a documented sequential fallback — never silent platform forks
2. p2e-story-lead must NOT be added to the status-gate hook allowlist — the IN_PROGRESS gate exists for exactly these spawns
3. No in-loop release: the orchestrator never invokes /p2e-cut-release or /ultrareview
4. The story-lead JSON report contract must be field-identical between workflows/p2e-work-on-next.md and agents/p2e-story-lead.md
5. Keep the 3-checkpoint story-log policy intact; only checkpoint authorship changes (strike-1 BLOCKER moves to the story-lead)

**nonGoals (4):**
1. No changes to workflows/p2e-first-turn-briefing.md
2. No goal-primitive integration beyond the loop mention for long runs
3. No absorption of ship-batch's verify/UAT phases into work-on-next
4. No version bump — release is user-triggered after this lands

**contextDocs (4):** `docs/feat-work-on-next-v2/plan.md`, `workflows/p2e-policy.md`, `reference/cross-platform-pattern.md`, `agents/p2e-staff-engineer.md`

**verificationCmd:**

```bash
bash -n hooks/pre-agent-spawn-story-status.sh && ! grep -rn '/6 ' workflows/ commands/ skills/ agents/ README.md && grep -q '## Model ladder' workflows/p2e-policy.md && grep -q 'p2e-story-lead' workflows/p2e-work-on-next.md && test -f agents/p2e-story-lead.md
```

## Write order on acceptance

1. `mcp__p2e__stories op=create` (story with all thick fields, status OPEN)
2. `mcp__p2e__criteria op=create` (8 items)
3. `mcp__p2e__capabilities op=create` (4 items)
4. `mcp__p2e__create_github_issue` (labeled `ready`, linked back)

Fail-fast, non-atomic: earlier writes persist if a later phase fails.
