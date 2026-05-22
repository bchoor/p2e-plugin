# P2E Ship-Batch Workflow

Heavyweight quality-gate orchestrator. Selects a filtered batch of OPEN stories, runs the full `/p2e-work-on-next` implementation flow per story, then layers per-story 360° verification, PR creation + review, conditional security review, and a roll-up shipping report.

Reach for this when shipping a release. For single-story or fast-track spot work, use `/p2e-work-on-next` directly — this workflow is opt-in heavy.

## Purpose

- Select a filtered batch of OPEN stories from the queue using the same selection rules as `p2e-work-on-next`.
- Delegate per-story implementation to the existing work-on-next workflow without forking its logic.
- Layer post-implementation gates: 360° verify, per-story PR + review, conditional security review.
- Emit a per-story rich-HTML UAT report (via `/p2e-verify-story`) and a batch roll-up index.
- Configurable failure isolation, security auto-detection from diff paths, and optional release-cut handoff.
- Capture every implementer-side spec deviation as a `SCOPE_CHANGE` or `DECISION` story-log entry so a hands-off batch run is fully auditable.
- Track each story as a TaskCreate task so the user has a live view of every workstream in the batch.

## When to use vs. work-on-next

| Situation | Use |
| --- | --- |
| Single story, you're at the keyboard | `/p2e-work-on-next` |
| Fast-track story (ui/docs/copy, ≤3 ACs) | `/p2e-work-on-next` |
| Release batch (≥2 stories under a `release=` filter) | `/p2e-ship-batch` |
| Multi-story flush of a phase or tag | `/p2e-ship-batch` |
| You want a roll-up report you can hand to a reviewer | `/p2e-ship-batch` |

## Workflow

### Phase A — Select & plan

1. Resolve filters: `release=`, `phase=`, `tag=`, `priority=` (comma-separated `P0,P1`), `story_id=` (repeatable), `--exclude=<id>` (repeatable), `--max=<n>`.
2. Query the queue using the canonical selection rule from `workflows/p2e-work-on-next.md` steps 1–4: `mcp__p2e__stories op=list status=OPEN` with the filters, sort by `priority` ascending then `createdAt` ascending, fetch full detail (`op=get`) for each candidate, and apply the thin-draft check per `## Thin drafts` in policy.
3. Apply the **thick-gate** (per `## Thick-gate` in policy) to every candidate. **Hard refuse the batch** if any selected story has `isThick=false` or `status != "OPEN"` — direct the user to `/p2e-update-story <story_id>` for each failing story, or to re-run with `--exclude=<bad-id>`. Do not proceed with a partial batch.
4. Apply the adaptive router (per `## Adaptive router` in policy) per story to classify track and decide whether the architect + `superpowers:writing-plans` run (`--full-team` passes through to work-on-next).
5. Ask `p2e-staff-engineer` for a wave plan (this workflow is by definition multi-story — batch size ≥ 1 but the staff engineer always runs because of the post-implementation gates).
6. Estimate token-day cost per story via the `/estimate-effort` heuristic. If `--budget=<n>` was passed and the batch sum exceeds it, stop and present the over-budget list — the user can re-run with `--max=<n>` or a narrower filter.
7. Present the **pre-flight summary** to the user: queue, classification, wave plan, security-gate trigger evaluation per story (based on `filesHint[]` and capabilities — see Phase D), token-day estimate, planned worktree path. Confirm before proceeding unless `--yes` was passed.

8. **Create per-story tracking tasks** — after the user confirms, emit one `TaskCreate` call per selected story so the user has a live ops view of every workstream throughout the batch:
   - `subject`: `<story_id>: <story title>`
   - `description`: one-line story `RRR` summary + the Flow name (persona / Foundation slot) + the resolved track (Fast / Standard / Architectural) + the wave number from the staff-engineer plan.
   - `activeForm`: `Shipping <story_id>` (used by the spinner when the task is `in_progress`).
   - Initial status: `pending`.
   
   The task list becomes the orchestrator's heartbeat for the batch. Steps 9 and 22 below issue `TaskUpdate` calls **unconditionally**. Steps 11, 14, and 20 issue `TaskUpdate` calls **conditionally** — only when an audit / verification / review failure path fires. Status semantics:
   - `pending` → before Phase B implementation starts.
   - `in_progress` → from Phase B start through Phase E roll-up.
   - `completed` → on Phase E successful row emission for this story.
   - Back to `pending` (with a status-line note) → on Phase B / C failure that sends the story back to a prior phase.
   - Kept `in_progress` with a "needs review attention" note → on Phase D blocker findings (the workstream is alive but waiting on human review).
   
   On hosts without TaskCreate (Codex / Cursor today), degrade to a chat-prose progress block printed at the start of each phase boundary. The behavior contract stays the same — the user sees the same information, just rendered differently.

### Phase B — Implement (delegated to work-on-next)

9. `TaskUpdate` each story's task to `in_progress` as its wave starts. Delegate per-wave implementation to `workflows/p2e-work-on-next.md` **steps 9–12 exactly as written** (steps 7–8 — worktree setup and staff-engineer wave plan — were already handled in Phase A steps 5–7 above; do not re-run them). Do not fork the briefing, status-gate, two-strike, AC-toggle, or label-sync logic. Pass `--full-team` through if the user supplied it. The only ship-batch-specific interception inside this range is the scope-change audit (step 11 below), which fires after work-on-next step 9c (implementer verification passes) and before work-on-next step 11 (the IN_REVIEW flip + AC toggle).

10. **Implementer deviation reporting** (enforced via `workflows/p2e-first-turn-briefing.md` — see its `## Deviation reporting` section). The implementer is contracted to emit a story-log entry **before** any mid-flight spec deviation:
    - `kind: SCOPE_CHANGE` for changes to the spec itself (AC dropped/modified, capability adjusted, non-goal added, scope reduced/expanded).
    - `kind: DECISION` for non-obvious judgment calls that don't change the spec (chose library A over B, picked a wrapper over a fork, deferred X to a follow-up story).

11. **Scope-change audit** — after the implementer reports completion (work-on-next step 9c finishes with verification pass) and **before** work-on-next step 11 executes the `IN_REVIEW` flip and AC toggle, the orchestrator runs the audit:
    - Diff the as-implemented state against the briefed spec: ACs toggled vs. checked, capabilities matched vs. specced, non-goals respected vs. crossed.
    - **Non-trivial delta + zero `SCOPE_CHANGE`/`DECISION` entries in the post-briefing window = a missed report.** Surface it to the user with the diff and one of three resolutions:
      a. Author a retroactive `SCOPE_CHANGE` / `DECISION` entry now (user dictates the message).
      b. Accept the delta silently and append a `kind: NOTE` flagging it for follow-up review.
      c. Reject the implementation — the story goes back to `IN_PROGRESS`, two-strike does NOT apply (this is a process miss, not an implementation failure), the implementer is re-briefed with explicit emphasis on the deviation protocol, and the story's task drops back to `pending` with a status-line note.

12. Each story completes Phase B at `status=IN_REVIEW` with toggled criteria and a clean story-log trail. Stories that hit two-strike escalation are at `status=BLOCKED` — those are **excluded from Phases C–E**, their task is kept `in_progress` with a "BLOCKED — needs human triage" status-line note, and they're surfaced in the final roll-up under "Blocked".

### Phase C — 360° verify per story

13. For each story now at `IN_REVIEW`, call `/p2e-verify-story <story_id>` (the v0.10.2-shipped UAT-report workflow). The command bind-checks `.p2e/project.json`, fetches the story via `mcp__p2e__stories op=get`, brings the dev server up reliably (detached `nohup` launch with `lsof` port verification), reproduces every AC via a browser-driver MCP (`mcp__chrome-devtools__*` preferred, `mcp__claude-in-chrome__*` fallback) or curl for backend-only ACs, and emits a self-contained rich-HTML report at `docs/feat-<topic>/uat-results/results.html` (preferred) or `.claude/uat-results/<story-id>/results.html` (fallback when no feature folder is bound). Pass `--artifacts-dir=<path>` per-batch to redirect output if needed.

14. **On verify failure** (any AC verdict `FAIL`): the story is moved back to `IN_PROGRESS`, its task drops to `pending` with a "verify failed: AC<n>" status-line note. The two-strike rule from `## Two-strike escalation` in policy applies (counter shared with Phase B failures). Append a `kind: VERIFICATION` story-log entry with the failure reason, the failing AC list, and a link to the UAT report. The story is **excluded from Phase D** for this batch run.

15. **On verify pass** (all AC verdicts `PASS` or `CAVEAT`-accepted-by-user): append a `kind: VERIFICATION` story-log entry — see `## Story log checkpoints` below for the message shape. Proceed to Phase D.

### Phase D — PR per story + review

16. For each story that passed Phase C, open **one PR per story** (clean diff-per-story is the right grain for review):
    - Branch: `feat/<story_id>-<short-slug>` (per repo branch-naming convention in `CLAUDE.md`).
    - PR title: `<story_id>: <story title>`.
    - PR body: links to the story (via the linked GH issue if present), the UAT-report HTML path (from Phase C), and a one-paragraph summary sourced from the story log's VERIFICATION entry. Attach the UAT report as a PR artifact when supported.

17. Run `/pr-review-toolkit:review-pr <pr-number>` on each PR. Capture: total findings count, severity histogram (blocker / major / minor / nit), and the inline-comment URLs.

18. **Security gate trigger** — evaluate the PR diff path list against the security trigger globset:
    - `**/auth*` `**/session*` `**/crypto*` `**/secret*` `**/token*` `**/oauth*` `**/permission*` `**/password*` `**/identity*` `**/login*` `**/jwt*` `**/saml*` `**/iam*`
    - Any file with `pii`, `gdpr`, `hipaa`, `pci`, `phi` in the path
    - Any change under `**/migrations/**` that adds or modifies a column whose name matches `email`, `phone`, `ssn`, `tax_id`, `address`, `dob`, `birthdate`
    - Any capability on the story with action `DEPRECATES` or `REMOVES` against an auth/session/permission identifier
    - The story sits in the Foundation Flow `Security` slot
    
    If **any** of the above match, OR if `--security` was passed: also run `/security-review` on the PR. The `--no-security` flag forces this off (use sparingly — document the override reason in a `kind: DECISION` log entry).

19. Append a `kind: VERIFICATION` story-log entry summarizing the review pass — see `## Story log checkpoints`.

20. **On review-blocker findings (severity = blocker):** post the findings as PR comments (`/pr-review-toolkit:review-pr` already does this via `--comment`), leave the PR in draft, append a `kind: BLOCKER` story-log entry with the finding count and a one-line summary. The story stays at `IN_REVIEW`, its task is kept `in_progress` with a "needs review attention: <n> blockers" status-line note, and it's surfaced in the roll-up under "Needs review attention" rather than "Shipped". The batch continues to the next story by default; `--stop-on-fail` halts here.

### Phase E — Roll-up

21. Emit a single rich-Markdown index at `docs/feat-ship-batch-<YYYY-MM-DD>/index.md` via the `writing-rich-docs` skill (per `workflows/p2e-rich-docs.md`). The index is a promote-to-HTML candidate — use the comparison-matrix component to render the per-story status grid. Per-story rows include:
    - Story id + title + Flow (persona / Foundation slot)
    - Outcome (shipped / blocked-implementation / blocked-verify / blocked-review / needs-attention)
    - Link to the UAT-report HTML from Phase C
    - PR link + review summary (findings count, severity histogram)
    - Security review (run / skipped / clean / findings count)
    - Scope-change summary — count of `SCOPE_CHANGE` + `DECISION` entries logged during this run, with the first 200 chars of each

22. For each successfully-shipped story (verify pass + review pass + no security blockers), `TaskUpdate` its task to `completed`. Print the roll-up doc path + a one-screen summary table to the user.

### Phase F — Optional release handoff

23. If `--cut-release` was passed AND every batch story landed at `IN_REVIEW` with the PR merged AND no blocker review findings remain open: invoke `/cut-release` (Claude Code only — on Codex/Cursor, print the next step for the user to run manually).
24. If any story is still blocked, needs review attention, or has open security findings: print the gating list and **do not** auto-invoke `/cut-release`.

## Failure isolation

Default failure mode is **skip + continue + mark BLOCKED / needs-attention**:

| Failure point | Default | `--stop-on-fail` |
| --- | --- | --- |
| Phase B two-strike escalation | `status=BLOCKED`, continue with next story | Halt the entire batch |
| Phase B scope-change audit rejection | Re-brief implementer (does not consume strike), continue | Halt the entire batch |
| Phase C verify failure | Move story back to `IN_PROGRESS`, two-strike applies, exclude from Phases D/E | Halt the entire batch |
| Phase D review blocker findings | PR stays draft, story stays `IN_REVIEW`, surface in roll-up | Halt the entire batch |
| Phase D security finding (any severity) | PR stays draft, story stays `IN_REVIEW`, surface in roll-up | Halt the entire batch |

The roll-up doc (Phase E) is emitted regardless of failure isolation — even a partially-failed batch produces the report.

## Story log checkpoints

This workflow uses every checkpoint defined in `workflows/p2e-work-on-next.md#story-log-checkpoint-policy` and **adds two more** plus extends authorship on two existing kinds.

### Authorship extension

`SCOPE_CHANGE` and `DECISION` are no longer human-authored only — they may now be authored by `"implementer"` or `"orchestrator"` in addition to `"user"`. The full extension lives in `workflows/p2e-first-turn-briefing.md#deviation-reporting` so it applies to both `/p2e-work-on-next` and `/p2e-ship-batch`.

### Checkpoint 4 — 360° verify pass (Phase C, step 15)

```json
{ "kind": "VERIFICATION", "author": "orchestrator", "message": "360° verify pass via /p2e-verify-story: all <n> ACs satisfied. UAT report: <uat-report-path>/results.html" }
```

One entry per story that passed Phase C. Replace `<n>` with the satisfied AC count and `<uat-report-path>` with the rich-HTML report path emitted by `/p2e-verify-story` (typically `docs/feat-<topic>/uat-results/<story_id>.html`).

### Checkpoint 5 — PR review pass (Phase D, step 19)

```json
{ "kind": "VERIFICATION", "author": "orchestrator", "message": "PR review pass on PR #<n>: <findings count> findings (<blocker>/<major>/<minor>/<nit>). Security: <run|skipped|clean|<finding-count> findings>." }
```

One entry per story that completed Phase D. The security field is one of:
- `run` (security gate triggered but findings not yet enumerated)
- `clean` (security gate triggered, zero findings)
- `<n> findings` (security gate triggered, n findings)
- `skipped` (security gate did not trigger and `--security` was not passed)

### Failure entries

Phase C / Phase D failures append `kind: BLOCKER` per the existing pattern — message includes the phase + a short reason + the failing surface (failing AC, PR URL with findings, security report path).

## Dry-run behavior

`--dry-run` is read-only:
- Resolve the queue + classification + wave plan + security trigger evaluation exactly as a real run.
- Show which browser-driver MCP path (`mcp__chrome-devtools__*` preferred vs. `mcp__claude-in-chrome__*` fallback) `/p2e-verify-story` would use per story, based on host MCP availability.
- Show the per-story PR branch + title that WOULD be created.
- Print the planned roll-up doc path.
- Skip every state-changing call: no `op=update`, no story-log writes, no PR creation, no `review-pr` / `security-review` invocations, no roll-up doc emitted, no `cut-release` handoff.

## Platform asymmetries

- `/p2e-verify-story` ships in v0.10.2 and is the canonical Phase C path on all three platforms (Claude Code / Codex / Cursor) — it uses `mcp__chrome-devtools__*` (preferred) or `mcp__claude-in-chrome__*` (fallback) for the browser driver.
- `/security-review` is a user-installed command; when missing on the host, the Phase D security gate hard-skips with a logged `kind: DECISION` entry recording the skip reason and the matched trigger paths.
- `TaskCreate` / `TaskUpdate` are Claude Code natives. On Codex and Cursor, the per-story tracking degrades to a chat-prose progress block printed at each phase boundary; the workstream visibility contract stays the same, just without the spinner UI.
- Phase F `--cut-release` auto-handoff is **Claude Code only**. On Codex and Cursor, the workflow prints the next step for the user to run manually.
- The `PreToolUse` status-gate hook is Claude Code only — Phase B inherits work-on-next's self-enforced MCP status discipline (`workflows/p2e-work-on-next.md` step 9a — the `OPEN → IN_PROGRESS` transition that must complete before implementers are spawned).
- The `p2e-architect` and `p2e-staff-engineer` subagents are Claude Code natives. On Codex and Cursor, the workflow inlines the equivalent prompts as sub-steps in the same chat (per `skills/p2e/SKILL.md` persona routing matrix).

## Cost ceiling

`--budget=<token-days>` sets a soft cap (default: no cap). Phase A step 6 sums per-story estimates from the staff-engineer wave plan; if the sum exceeds the budget, the workflow stops with the over-budget list and the user can re-run with `--max=<n>` or a narrower filter.
