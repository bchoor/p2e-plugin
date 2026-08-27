---
title: /p2e-work-on-next v2 — Supervisor Architecture Implementation Plan
hash: 0843ae6
status: draft
date: 2026-06-11
owner: bchoor
---

# /p2e-work-on-next v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the work-on-next orchestrator from a main-session-driven 6-step TaskCreate ladder into a supervisor architecture — parallel `p2e-story-lead` subagents per wave (nested workers, depth ≤ 5), an optional dynamic-Workflow batch mode for ≥ 4 stories, adaptive skill selection, track-tiered single-primary reviews, one TaskCreate per story, and **no release step in the loop** (stories end at `IN_REVIEW`; the user cuts releases separately).

**Architecture:** The main session becomes a pure supervisor (recommend `/model fable` high-effort; opus acceptable): it selects/gates stories, gets a wave plan from `p2e-staff-engineer`, flips statuses, dispatches one `p2e-story-lead` agent per story per wave (each in its own worktree), then reviews each lead's structured JSON report, toggles ACs, flips `IN_REVIEW`, and syncs labels. The story-lead owns the per-story lifecycle (plan → implement via nested workers → verify with internal strike-1 retry → commit + PR → track-tiered review) and never writes story status. Approved decisions: hybrid substrate (story-leads + Workflow for ≥ 4), 1 task per story, track-tiered reviews, no cut-release.

**Tech Stack:** Markdown workflow docs, Claude Code agent definitions (`agents/*.md`), bash PreToolUse hook, Claude/Codex/Cursor wrapper files. No application code; verification is grep-based content assertions + the cross-platform compliance checklist.

---

## File structure

| File | Action | Responsibility |
|---|---|---|
| `workflows/p2e-policy.md` | Modify | Add `## Model ladder`, `## Adaptive skill matrix`, `## Review tiering`; fix stale "PR merge" wording |
| `workflows/p2e-work-on-next.md` | Rewrite | Supervisor phases 0–4, story-lead dispatch contract, report contract, Workflow batch mode, 1-task board, cross-platform fallback |
| `agents/p2e-story-lead.md` | Create | New story-lead subagent definition |
| `hooks/pre-agent-spawn-story-status.sh` | Modify (comments/messages only) | Reference new phase numbering; note story-lead is gated (NOT allowlisted) |
| `commands/p2e-work-on-next.md` | Modify | New args (`limit=`, `--workflow`), supervisor notes |
| `skills/p2e-work-on-next/SKILL.md` | Modify | Codex fallback note |
| `.cursor/skills/p2e-work-on-next/SKILL.md` | Modify | Cursor fallback note |
| `workflows/p2e-ship-batch.md` | Modify | Re-point Phase B references; dedupe Phase D reviews |
| `skills/p2e/SKILL.md` | Modify | Router line for work-on-next |
| `README.md` | Modify | Command-table row |
| `CHANGELOG.md` | Modify | Unreleased entry |

Execution branch: rename worktree branch to `feat/<STORY-ID>-work-on-next-v2` (via `/update-branch-name`) once the P2E story exists, BEFORE the PR is opened.

---

### Task 1: Policy additions (`workflows/p2e-policy.md`)

**Files:**
- Modify: `workflows/p2e-policy.md` (insert after `## Adaptive router` section, line ~39; one wording fix at line 58)

- [ ] **Step 1: Insert three new sections after the `## Adaptive router` section** (immediately before `## Canonical orchestrator naming`):

```markdown
## Model ladder

Roles and default models for the supervisor architecture (Claude Code). Other platforms map to their nearest equivalent and document the asymmetry.

| Role | Model | Notes |
| --- | --- | --- |
| Supervisor (main session) | `fable` high-effort recommended; `opus` acceptable | Plans, dispatches, reviews. Never implements. The workflow should surface the recommendation once at run start if the session model is below opus. |
| `p2e-staff-engineer` | `opus` | Wave planning, batch ≥ 2 (unchanged). |
| `p2e-architect` | `opus` | Opt-in approach review + two-strike escalation (unchanged). |
| `p2e-story-lead` | `sonnet` (Fast/Standard) / `opus` (Architectural) | Owns one story's lifecycle. Supervisor passes the model explicitly at dispatch. |
| Workers (spawned by story-lead) | `haiku` mechanical/UAT capture; `sonnet` coding; `opus` debugging or cross-cutting refactors | Nested under the story-lead; total agent depth must stay ≤ 5. |
| `fable` subagents | Only with explicit user approval at dispatch time | Reserved for judgment-critical one-offs. Never auto-dispatched. |

## Adaptive skill matrix

The story-lead (or the inline implementer on platforms without subagents) selects implementation skills from the story's signals. First matching row per category wins; rows are additive across categories.

| Signal | Skill to pull in | When it runs |
| --- | --- | --- |
| `constraints` contains `approach-review` OR `--full-team` | `p2e-architect` + `superpowers:writing-plans` | Before dispatch (supervisor-side, unchanged shape-aware rule) |
| Tag `ui` with code changes (not copy-only) | `frontend-design` | During implementation |
| Standard/Architectural story whose `filesHint` spans ≥ 3 top-level directories OR has ≥ 3 capabilities | `feature-dev` phased pattern (explore → architect → implement) | During implementation |
| Tag `bug` or `fix`, or story has a `FIXES` relation | `superpowers:systematic-debugging` | Before any fix is written |
| Any capability with `isBreaking: true` | `superpowers:test-driven-development` | Tests precede implementation (unchanged rule) |
| None of the above | Self-plan inline from the first-turn briefing | Default |

## Review tiering

Exactly one **primary** reviewer per story — never two review tools on the same diff.

| Track | Primary review | When |
| --- | --- | --- |
| Fast | `/code-review` on the working-tree diff | Before the PR is opened; findings fixed, then commit + PR |
| Standard / Architectural | `pr-review-toolkit:review-pr` on the open PR | After the PR is opened |

`/security-review` is a conditional **secondary** dimension, not a duplicate: it fires only when (a) the diff touches the security globset (auth/session/crypto/secret/PII/migration paths, as defined in `workflows/p2e-ship-batch.md` Phase D), (b) the story's UXO sits in the Foundation **Security** slot, or (c) `--security` was passed. `--no-security` forces it off and requires a `kind: DECISION` story-log entry with the reason.

`/ultrareview` is user-triggered and billed; no workflow may auto-invoke it.
```

- [ ] **Step 2: Fix the stale lifecycle wording at line 58.** Replace:

```markdown
- On successful verification + PR merge the orchestrator moves the story to `IN_REVIEW` and toggles its acceptance criteria.
```

with:

```markdown
- On successful verification the orchestrator moves the story to `IN_REVIEW` and toggles its acceptance criteria. PR and review activity happen with the story at `IN_REVIEW`; the merge itself is outside the orchestrator (release is a separate, user-triggered concern).
```

- [ ] **Step 3: Verify**

Run: `grep -c '^## Model ladder\|^## Adaptive skill matrix\|^## Review tiering' workflows/p2e-policy.md`
Expected: `3`

Run: `grep -c 'PR merge' workflows/p2e-policy.md`
Expected: `0`

- [ ] **Step 4: Commit**

```bash
git add workflows/p2e-policy.md
git commit -m "feat(policy): model ladder, adaptive skill matrix, review tiering for work-on-next v2"
```

---

### Task 2: Rewrite `workflows/p2e-work-on-next.md`

**Files:**
- Rewrite: `workflows/p2e-work-on-next.md` (replace everything from the top through the `### Multi-story wave verbosity` section, i.e. lines 1–111; KEEP `## Thin-draft handling`, `## End-of-run sync`, `## Dry-run behavior` with light edits; UPDATE `## Story log checkpoint policy` authorship as specified below)

- [ ] **Step 1: Write the new top section.** Required structure and normative content (connective prose may be polished by the implementer, contracts are verbatim):

**Intro:** canonical orchestrator; supervisor architecture; the main session is the **supervisor** — it plans, dispatches, and reviews, and never implements. Recommend `/model fable` (high effort) for the supervisor; opus acceptable. Surface the recommendation once at run start, do not block on it.

**Arguments:** existing `release=`, `phase=`, `tag=`, `story_id=`, `--full-team`, `--dry-run`; NEW `limit=N` (max stories to select this run, default 1) and `--workflow` (force dynamic-Workflow batch mode; auto-selected at N ≥ 4).

**`## Phase 0 — Select & gate`** (carries today's steps 1–5 unchanged in substance): queue query `mcp__p2e__stories op=list status=OPEN` + filters; canonical priority sort (P0→P3→null, then `createdAt` asc, one global queue across all Flows — copy today's step-2 text verbatim); take the top `limit` stories; per-candidate `op=get` + thin-draft check; thick-gate (refuse `isThick=false` or `status != "OPEN"` → `/p2e-update-story`, stop); adaptive router per policy.

**`## Phase 1 — Plan & confirm`**: staff-engineer wave plan when N ≥ 2 (JSON contract unchanged); architect + `superpowers:writing-plans` opt-in per the shape-aware rule; ensure a batch worktree exists; present ONE confirm gate to the user showing: selected queue, track + model per story, skill-matrix hits per story (from `## Adaptive skill matrix` in policy), wave plan + collisions, review tier per story, and the note that the run ends at `IN_REVIEW` with **no release**. Create the task board: **one `TaskCreate` per story**, title `[#<story-id>] <story title>`, status `pending`. The task description is the per-story progress surface — update it via `TaskUpdate` at each lifecycle transition (`briefed → implementing → verifying → PR open → in review → IN_REVIEW` or `BLOCKED (strike 2)`).

**`## Phase 2 — Execute waves`**: per wave:
- **2a Status flip:** `/p2e-update-story <id> status=IN_PROGRESS` for each story in the wave (label reconciliation + cache refresh are required side effects — keep today's 9a warning verbatim, including the PreToolUse hook note: the hook blocks implementer/story-lead spawns for stories not at IN_PROGRESS/IN_REVIEW; `p2e-story-lead` is intentionally NOT in the hook's allowlist).
- **2b Briefing:** materialize the first-turn briefing per `workflows/p2e-first-turn-briefing.md` for each story (Flow membership surfaced, unchanged). If the briefing surfaces OPEN_QUESTIONS, emit one `kind: NOTE` story-log entry per question and resolve them with the user BEFORE dispatch — story-leads cannot ask the user mid-flight.
- **2c Dispatch:** one `p2e-story-lead` per story, **in parallel within the wave**, each with `isolation: worktree`; model per the policy model ladder (sonnet Fast/Standard, opus Architectural); the briefing (+ architect sketch if produced) is the turn-1 message; `TaskUpdate` each story's task to `in_progress`.
- **2d Workflow batch mode (N ≥ 4 in the run, or `--workflow`):** instead of direct Agent dispatches, the supervisor compiles **one dynamic Workflow invocation per wave** from the staff-engineer JSON. Skeleton (verbatim in the doc):

````markdown
```js
export const meta = {
  name: 'p2e-wave-exec',
  description: 'Execute one P2E story wave via story-lead agents',
  phases: [{ title: 'Wave' }],
}
const reports = await parallel(args.stories.map(s => () =>
  agent(s.briefing, {
    agentType: 'p2e-story-lead', label: `story:${s.id}`, phase: 'Wave',
    isolation: 'worktree', model: s.model, schema: args.report_schema,
  })))
return { reports: reports.filter(Boolean) }
```
````

The supervisor processes reports BETWEEN waves (Phase 3) — never fire wave k+1 before wave k's stories are closed or blocked. Workflow mode is Claude-Code-only; the slash-command instruction in this workflow is the user's opt-in.

**`## Phase 3 — Close per story`** (supervisor, on each story-lead report):
- `outcome: "pass"` → review the report against the story's ACs (spot-check evidence, don't rubber-stamp); toggle ACs (`mcp__p2e__criteria op=toggle`); write the `AC_CHANGE` + `VERIFICATION` story-log checkpoints; flip `IN_REVIEW` (`op=update status=IN_REVIEW`); post the summary + PR URL to the linked issue; `TaskUpdate` → `completed`.
- `outcome: "blocked"` (story-lead exhausted its internal strike-1 retry) → this IS strike 2: write the strike-2 `BLOCKER` checkpoint, set `status=BLOCKED`, post to the linked issue, route to `p2e-architect` for a fresh approach (Claude Code) or `codex:rescue` (Codex), `TaskUpdate` description → `BLOCKED (strike 2)`, leave task `in_progress`.

**`## Story-lead dispatch contract`**: inputs (briefing turn-1, story id, project slug, track, review tier, verification command, branch name `feat/<STORY-ID>-<topic-kebab>`); the story-lead's 5-step lifecycle is defined in `agents/p2e-story-lead.md` — summarize: plan (skill matrix) → implement (nested workers) → verify (internal strike-1 retry) → commit + PR → review (tiered). The report contract (verbatim JSON block in the doc):

```json
{
  "story_id": "X-00-L0",
  "outcome": "pass | blocked",
  "branch": "feat/X-00-L0-topic",
  "pr_url": "https://github.com/... | null",
  "verification": { "cmd": "...", "result": "pass | fail", "summary": "..." },
  "acceptance_criteria": [{ "ordinal": 1, "met": true, "evidence": "..." }],
  "review": { "tool": "code-review | review-pr", "findings_addressed": 0, "wont_fix": [{ "finding": "...", "rationale": "..." }], "security_review": "run | skipped" },
  "deviations": ["story_log entries already written by the lead (DECISION/SCOPE_CHANGE/strike-1 BLOCKER)"],
  "files_touched": ["..."],
  "blocked_reason": null
}
```

**`## Phase 4 — End of run`**: label sync (keep today's `## End-of-run sync` rules); run summary table (story, outcome, PR, review findings); explicit statement: **the orchestrator never invokes `/p2e-cut-release` or `/ultrareview`** — releases are user-triggered; surviving stories sit at `IN_REVIEW` awaiting human acceptance + release.

**`## Branch-name convention`**: keep today's section content (regex `[A-Z]+-[0-9]+-L[0-9]+`, `/update-branch-name` before the PR) but motivated by the user's later `/p2e-cut-release`, not by a ladder step 6.

**`## Cross-platform fallback`** (replaces the ladder's fallback section): Claude Code = full supervisor architecture above. **Codex** = no nested Agent tree or Workflow tool; run the sequential fallback — per story, in priority order: brief → implement inline (skill matrix still applies) → verify with strike-1 retry → commit + PR → tiered review; use `update_plan` with one entry per story. **Cursor** = same sequential fallback, no task primitive: one `kind: NOTE` story-log entry per lifecycle transition (keep today's NOTE example verbatim). State plainly: parallel waves are Claude-Code-only; this is a documented asymmetry, not a defect.

- [ ] **Step 2: Update `## Story log checkpoint policy` authorship.** Keep the 3 checkpoints and exact entry shapes; change WHO writes them:
  - `AC_CHANGE` (checkpoint 1) and `VERIFICATION` (checkpoint 2): written by the **supervisor** in Phase 3.
  - Strike-1 `BLOCKER`: written by the **story-lead** when its internal verification retry is consumed (`"author": "implementer"`).
  - Strike-2 `BLOCKER`: written by the **supervisor** in Phase 3 on a `blocked` report (`"author": "orchestrator"`, message unchanged: `"Verification failed (strike 2): <short reason> — escalated to architect"`).
  - `DECISION`/`SCOPE_CHANGE`/`NOTE` self-reporting rules unchanged.

- [ ] **Step 3: Keep `## Thin-draft handling`, `## End-of-run sync`, `## Dry-run behavior` sections**, with one edit each: dry-run also shows the would-be wave dispatches + chosen Workflow mode; end-of-run sync references Phase 4; thin-draft unchanged.

- [ ] **Step 4: Verify**

Run: `grep -c 'TaskCreate.*[1-6]/6\|6-step\|cut-release.*step 6' workflows/p2e-work-on-next.md`
Expected: `0` (ladder fully removed)

Run: `grep -c 'p2e-story-lead' workflows/p2e-work-on-next.md`
Expected: ≥ 4

Run: `grep -c 'Phase 0\|Phase 1\|Phase 2\|Phase 3\|Phase 4' workflows/p2e-work-on-next.md`
Expected: ≥ 5

Run: `grep -ci 'p2e-cut-release' workflows/p2e-work-on-next.md`
Expected: ≥ 1 (only in the "never invokes" statement + branch-name rationale)

- [ ] **Step 5: Commit**

```bash
git add workflows/p2e-work-on-next.md
git commit -m "feat(work-on-next): v2 supervisor architecture — story-lead waves, Workflow batch mode, no in-loop release"
```

---

### Task 3: Create `agents/p2e-story-lead.md`

**Files:**
- Create: `agents/p2e-story-lead.md`

- [ ] **Step 1: Write the agent file** (complete content; implementer may polish prose, contracts verbatim):

```markdown
---
name: p2e-story-lead
description: Use when /p2e-work-on-next v2 dispatches one story for end-to-end implementation. Owns the per-story lifecycle — plan via the adaptive skill matrix, implement via nested workers, verify with one internal retry, commit + PR, run the track-tiered review — and returns a structured JSON report. Never writes story status; the supervisor owns all status flips.
model: sonnet
color: green
---

# p2e-story-lead — per-story lifecycle owner

You own exactly one P2E story from briefing to reviewed PR. Your turn-1 message is the first-turn briefing (per `workflows/p2e-first-turn-briefing.md`), plus the architect's implementation sketch when one was produced. You run inside a dedicated worktree.

## Inputs (from the supervisor)

1. First-turn briefing (turn-1 message) — story id, project slug, track, review tier, verification command, branch name `feat/<STORY-ID>-<topic-kebab>`.
2. Optional architect sketch (when `approach-review` / `--full-team` fired).

## Lifecycle (5 steps)

1. **Plan.** Apply `## Adaptive skill matrix` (workflows/p2e-policy.md): `ui` tag → `frontend-design`; multi-component Standard/Architectural → `feature-dev` phased pattern; `bug`/`fix`/`FIXES` → `superpowers:systematic-debugging`; `isBreaking` → TDD. Otherwise self-plan inline from the briefing. Consume the architect sketch when present instead of re-deriving an approach.
2. **Implement via nested workers.** You are depth 2 of a max-5 agent tree. Dispatch workers with explicit models: `haiku` for mechanical work (scripted edits, chrome-devtools UAT capture), `sonnet` for coding, `opus` for debugging or cross-cutting refactors (include an `opus-justified: <reason>` line in the prompt). Emit `kind: DECISION` / `kind: SCOPE_CHANGE` story-log entries BEFORE any deviating change (deviation-reporting contract in `workflows/p2e-first-turn-briefing.md`).
3. **Verify.** Run `story.verificationCmd`, or the track default from `## Verification matrix` in policy. On failure: write the strike-1 BLOCKER checkpoint (`{"kind":"BLOCKER","author":"implementer","message":"Verification failed (strike 1): <short reason>"}`), re-brief your worker with the failure output, and retry ONCE. On a second failure, stop — report `outcome: "blocked"` with `blocked_reason`. Do NOT keep iterating.
4. **Commit + PR.** Branch must be `feat/<STORY-ID>-<topic-kebab>` (rename before pushing if not). NEVER include a version bump commit. `git push -u origin HEAD`, then `gh pr create --fill` (add `Closes #<issue>` when a GitHub issue is linked). For Fast-track stories, run the review (step 5) BEFORE opening the PR.
5. **Review (track-tiered, per `## Review tiering` in policy).** Fast → `/code-review` on the diff, fix findings, then commit + PR. Standard/Architectural → `pr-review-toolkit:review-pr` on the open PR. Run `/security-review` only when its triggers fire (security globset, Foundation Security slot, `--security`). Address every finding or triage it as won't-fix with a rationale in the report. Material changes from review findings get a `DECISION`/`SCOPE_CHANGE` log entry.

## Report contract

Your final message is a single JSON block (the supervisor parses it):

[the exact JSON report contract from workflows/p2e-work-on-next.md `## Story-lead dispatch contract` — copy it verbatim into this file]

## Hard rules

- NEVER write `story.status` (`mcp__p2e__stories op=update status=...`) — the supervisor owns every status flip.
- NEVER invoke `/p2e-cut-release`, `/ultrareview`, or any release/version-bump step.
- NEVER toggle acceptance criteria — report evidence per AC; the supervisor toggles.
- Story-log writes you DO own: strike-1 `BLOCKER`, `DECISION`, `SCOPE_CHANGE` (items-form, per the checkpoint policy).
- Stay inside your story's worktree; do not touch sibling stories' files (the staff-engineer wave plan exists to prevent collisions — respect it).
- Two-strike rule: one internal retry, then report blocked. No third attempt.
```

- [ ] **Step 2: Verify**

Run: `grep -c 'NEVER write `story.status`\|never writes story status' agents/p2e-story-lead.md` — Expected: ≥ 1
Run: `grep -c 'model: sonnet' agents/p2e-story-lead.md` — Expected: `1`

- [ ] **Step 3: Commit**

```bash
git add agents/p2e-story-lead.md
git commit -m "feat(agents): add p2e-story-lead per-story lifecycle agent"
```

---

### Task 4: Hook reference tweaks (`hooks/pre-agent-spawn-story-status.sh`)

**Files:**
- Modify: `hooks/pre-agent-spawn-story-status.sh` (comments + one message; NO functional change — `p2e-story-lead` must stay OUT of the allowlist so the IN_PROGRESS gate applies to it)

- [ ] **Step 1: Update the header comment** (line 11). Replace:

```bash
#   3. subagent_type is one of: p2e-architect, p2e-staff-engineer, rescue
```

with:

```bash
#   3. subagent_type is one of: p2e-architect, p2e-staff-engineer, rescue
#      (p2e-story-lead is deliberately NOT allowlisted — story-lead spawns are the
#       implementer spawns this gate exists for; Phase 2a must flip IN_PROGRESS first)
```

- [ ] **Step 2: Update the block message** (line 146) to reference the new phase. Replace `implementer spawn requires IN_PROGRESS or IN_REVIEW.` with `implementer/story-lead spawn requires IN_PROGRESS or IN_REVIEW (work-on-next Phase 2a).`

- [ ] **Step 3: Verify**

Run: `bash -n hooks/pre-agent-spawn-story-status.sh && grep -c 'p2e-story-lead' hooks/pre-agent-spawn-story-status.sh`
Expected: syntax OK, count ≥ 2

- [ ] **Step 4: Commit**

```bash
git add hooks/pre-agent-spawn-story-status.sh
git commit -m "docs(hooks): reference work-on-next v2 phase numbering in status gate"
```

---

### Task 5: Update the three wrappers

**Files:**
- Modify: `commands/p2e-work-on-next.md`, `skills/p2e-work-on-next/SKILL.md`, `.cursor/skills/p2e-work-on-next/SKILL.md`

- [ ] **Step 1: Rewrite `commands/p2e-work-on-next.md`** (complete content):

```markdown
---
name: p2e-work-on-next
description: Pick the next open P2E story/stories (story_id= or limit=N) and run the v2 supervisor — parallel story-lead waves, tiered reviews, stories end at IN_REVIEW (no release).
argument-hint: [release=v0.3] [phase=Build] [tag=plugin] [story_id=X-00-L0] [limit=3] [--full-team] [--workflow] [--dry-run]
---

# /p2e-work-on-next

This command is a thin wrapper over `workflows/p2e-policy.md`, `workflows/p2e-work-on-next.md`, and `workflows/p2e-first-turn-briefing.md`.
Execute the shared orchestrator workflow exactly as defined there. The main session acts as the supervisor (`/model fable` high-effort recommended); story implementation is delegated to `p2e-story-lead` subagents per wave.

Flags: `limit=N` selects up to N stories (default 1). `--full-team` forces the architect + `superpowers:writing-plans` path. `--workflow` forces the dynamic-Workflow batch mode (auto at N ≥ 4). The run ends with stories at `IN_REVIEW` — releases are user-triggered via `/p2e-cut-release`, never by this command.
```

- [ ] **Step 2: Rewrite `skills/p2e-work-on-next/SKILL.md`** (complete content):

```markdown
---
name: p2e-work-on-next
description: Explicit Codex entrypoint for the P2E work-on-next workflow (v2 supervisor).
---

# p2e-work-on-next

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-work-on-next.md`
- `workflows/p2e-first-turn-briefing.md`

Execute the shared orchestrator workflow exactly. Codex has no nested Agent tree or dynamic Workflow tool — use the documented **sequential fallback** in `## Cross-platform fallback`: per story, brief → implement inline (adaptive skill matrix still applies) → verify with one retry → commit + PR → tiered review; track progress with `update_plan` (one entry per story). Stories end at `IN_REVIEW`; never cut a release.
```

- [ ] **Step 3: Rewrite `.cursor/skills/p2e-work-on-next/SKILL.md`** (complete content):

```markdown
---
name: p2e-work-on-next
description: Cursor entrypoint for the P2E work-on-next workflow (v2 supervisor). Picks the next open story/stories and runs the sequential fallback; --full-team enables architect+plan.
---

# p2e-work-on-next

Read:
- `workflows/p2e-policy.md`
- `workflows/p2e-work-on-next.md`
- `workflows/p2e-first-turn-briefing.md`

Execute the shared orchestrator workflow exactly, using the **sequential fallback** in `## Cross-platform fallback` (parallel story-lead waves and the dynamic-Workflow batch mode are Claude-Code-only).

## Cursor-specific notes

- The Claude `PreToolUse` status-gate hook does NOT run in Cursor. The workflow's status discipline is self-enforced — confirm a story is IN_PROGRESS through MCP before starting its implementation.
- Subagents (`p2e-architect`, `p2e-staff-engineer`, `p2e-story-lead`) are not native to Cursor. Inline their prompts as sub-steps in the same chat; emit one `kind: NOTE` story-log entry per lifecycle transition as the progress surface.
- Stories end at `IN_REVIEW`; never cut a release.

Cross-platform mirrors: `commands/p2e-work-on-next.md` (Claude), `skills/p2e-work-on-next/SKILL.md` (Codex).
```

- [ ] **Step 4: Verify**

Run: `grep -l 'IN_REVIEW' commands/p2e-work-on-next.md skills/p2e-work-on-next/SKILL.md .cursor/skills/p2e-work-on-next/SKILL.md | wc -l`
Expected: `3`

- [ ] **Step 5: Commit**

```bash
git add commands/p2e-work-on-next.md skills/p2e-work-on-next/SKILL.md .cursor/skills/p2e-work-on-next/SKILL.md
git commit -m "feat(wrappers): v2 supervisor wrappers for work-on-next (limit=, --workflow, sequential fallbacks)"
```

---

### Task 6: Re-point `workflows/p2e-ship-batch.md`

**Files:**
- Modify: `workflows/p2e-ship-batch.md`

- [ ] **Step 1:** Update every Phase B reference of the form "work-on-next steps 9–12" (and any "step 9a/9b/9c/11/12" references) to the v2 names: "work-on-next Phases 2–3" / "Phase 2a status flip" / "Phase 3 close". Use `grep -n 'step 9\|steps 9\|step 11\|step 12' workflows/p2e-ship-batch.md` to find them all.

- [ ] **Step 2:** Add a dedup rule at the top of Phase D: when Phase B ran the v2 supervisor (which already executes the track-tiered review in-loop), Phase D does NOT re-run `pr-review-toolkit:review-pr` on the same PR — it only (a) verifies each report's `review` block is present and findings are addressed, and (b) runs the conditional `/security-review` if it has not already run (the report's `security_review` field says so).

- [ ] **Step 3: Verify**

Run: `grep -c 'step 9\|steps 9' workflows/p2e-ship-batch.md` — Expected: `0`
Run: `grep -c 'security_review' workflows/p2e-ship-batch.md` — Expected: ≥ 1

- [ ] **Step 4: Commit**

```bash
git add workflows/p2e-ship-batch.md
git commit -m "fix(ship-batch): re-point Phase B to work-on-next v2 phases; dedupe Phase D reviews"
```

---

### Task 7: Router skill, README, CHANGELOG

**Files:**
- Modify: `skills/p2e/SKILL.md` (the work-on-next routing line), `README.md` (commands table row), `CHANGELOG.md` (new Unreleased entry)

- [ ] **Step 1:** In `skills/p2e/SKILL.md`, find the work-on-next routing line (`grep -n 'work-on-next' skills/p2e/SKILL.md`) and update its description to: "pick the next open story/stories and run the v2 supervisor (story-lead waves on Claude Code, sequential fallback on Codex/Cursor); stories end at IN_REVIEW, no release".

- [ ] **Step 2:** In `README.md`, find the `/p2e-work-on-next` row (`grep -n 'work-on-next' README.md`) and update the description to match the new command frontmatter description from Task 5 Step 1 (including `limit=` and `--workflow`).

- [ ] **Step 3:** In `CHANGELOG.md`, add directly under the title an `## [Unreleased]` section:

```markdown
## [Unreleased]

### Changed
- **`/p2e-work-on-next` v2 — supervisor architecture.** Replaces the 6-step TaskCreate ladder (v0.10.5) with: parallel `p2e-story-lead` subagent waves (nested workers, depth ≤ 5), dynamic-Workflow batch mode at N ≥ 4 (`--workflow`), one TaskCreate per story, adaptive skill matrix (`frontend-design` / `feature-dev` / `systematic-debugging` / TDD by story signals), track-tiered single-primary reviews (Fast → `/code-review` pre-PR; Standard/Architectural → `pr-review-toolkit:review-pr`; conditional `/security-review`), and **no in-loop release** — stories end at `IN_REVIEW`, `/p2e-cut-release` is user-triggered. New `limit=N` arg. New agent `agents/p2e-story-lead.md`. Policy gains `## Model ladder`, `## Adaptive skill matrix`, `## Review tiering`. Codex/Cursor run a documented sequential fallback.
```

- [ ] **Step 4: Verify**

Run: `grep -c 'Unreleased' CHANGELOG.md` — Expected: ≥ 1
Run: `grep -c 'limit=' README.md` — Expected: ≥ 1

- [ ] **Step 5: Commit**

```bash
git add skills/p2e/SKILL.md README.md CHANGELOG.md
git commit -m "docs: router/README/CHANGELOG for work-on-next v2"
```

---

### Task 8: Cross-platform compliance check + final verification

**Files:**
- Read-only: `reference/cross-platform-pattern.md`, all files touched above

- [ ] **Step 1:** Run the cross-platform checklist from `reference/cross-platform-pattern.md` against the change set. This change is a **behavior change** to an existing workflow (all platforms inherit from `workflows/`), plus wrapper updates — confirm: all four surfaces still exist and are thin (~10–20 lines, no domain logic); the new agent and Workflow batch mode are documented as Claude-Code-only asymmetries in the workflow body (not silent fallbacks); `skills/p2e/SKILL.md` router updated; README + CHANGELOG updated.

- [ ] **Step 2:** Sanity greps across the repo:

Run: `grep -rn '1/6 Brief\|2/6 Implement\|3/6 Verify\|4/6 Commit\|5/6 /review-pr\|6/6' workflows/ commands/ skills/ .cursor/ agents/ README.md`
Expected: no hits (ladder vocabulary fully gone)

Run: `grep -rln 'p2e-story-lead' workflows/ agents/ hooks/ .cursor/ skills/ CHANGELOG.md | wc -l`
Expected: ≥ 5

- [ ] **Step 3:** Read the rewritten `workflows/p2e-work-on-next.md` end-to-end once for internal consistency (phase numbering, report-contract field names match `agents/p2e-story-lead.md` exactly — `outcome`, `pr_url`, `blocked_reason`, `security_review`).

- [ ] **Step 4: Commit any fixes**

```bash
git add -A && git commit -m "chore: compliance fixes from cross-platform checklist" || echo "nothing to fix"
```

---

## Self-review notes (already applied)

- Spec coverage: all four approved decisions map to tasks (substrate → Tasks 2/3; task board → Task 2 Phase 1; review tiering → Task 1 + Task 3 step 5; no release → Tasks 2/5/7).
- The story-lead report contract appears in Task 2 and is referenced (copy-verbatim instruction) in Task 3 to prevent drift.
- `p2e-story-lead` deliberately NOT added to the hook allowlist (Task 4) — the status gate must apply to it.
- Out of scope (YAGNI): goal-primitive integration beyond the loop mention, absorbing ship-batch's verify/UAT phases, Codex `update_plan` schema details, any change to `workflows/p2e-first-turn-briefing.md`.
