# P2E Fix Workflow

This workflow takes one or more bugs and resolves each by **uprooting and re-implementing** rather than layering a patch on top. It enforces a "fix shape" discipline: the model identifies what should be DELETED before what should be ADDED. The wrapper stays platform-neutral — Claude, Codex, and Cursor all enter the same workflow.

The point of this workflow is to fight the AI-coder default of stitching band-aids. Local fixes are cheap and feel productive, but they accumulate into tech debt that compounds with every later request. The workflow trades short-term tokens for long-term cleanliness.

## Hard rules

- **Iron Law: no fix without root cause.** If the cause is unknown after one diagnostic pass, stop and report. Do not guess.
- **Iron Law: uproot before re-implement.** A "fix" that adds new code (a new conditional, a new fallback, a new override, a new wrapper layer) on top of broken code is REJECTED. The correct shape is `delete + replace`, not `keep + augment`.
- **Verify both directions before claiming complete.** The reported bug must be gone AND no other behavior may regress.
- **One bug at a time, even in batches.** Phases run per-bug. Do not collapse intake and verify across bugs — each must clear all phases independently.
- **No scope creep.** If the right fix touches code outside the bug's blast radius, surface it as a follow-up rather than expanding silently.
- **No silent suppression.** Disabling a test, removing a check, or adding `// eslint-disable` to make the bug "go away" is a band-aid by another name and is REJECTED.

## Purpose

- Resolve a list of bugs `b1, b2, ... bN` such that each fix is the right *shape*, not just the right *outcome*.
- Make the discipline explicit and reviewable: every bug has a logged "what I deleted" and "what I replaced it with".
- When the project is bound to P2E (`.p2e/project.json` present), append the discipline log to the relevant story so future readers see the shape of each fix.

## Preconditions

- The repo is checked out and the user is operating on a branch (worktree-isolated work is preferred but not required).
- For each bug, the user has provided enough context to *reproduce* it. If not, the workflow asks for it before any code reads.
- If `.p2e/project.json` is present, the bound `project_slug` is honored for any story-log writes.
- Host platform supplies a "systematic debugging" primitive — use it. On Claude this is `superpowers:systematic-debugging`; on Codex use the native debugging skill or `codex:rescue` for deeper diagnosis; on Cursor use the equivalent debug skill or fall back to the workflow's own root-cause checklist below.

## Inputs

The workflow accepts a free-form list of bug descriptors, comma- or newline-separated. Each item may be:

- a plain-language bug description (`"settings panel background turns red on dark mode"`)
- a file path with optional line (`"src/Sidebar.tsx:42 — wrong color"`)
- a GitHub issue reference (`"#123"` or `"owner/repo#123"`)
- a P2E story id (`"B-05-L21"`)

Optional flags:

- `--dry-run` — runs intake + reproduce + root-cause + fix-shape gate, but stops before applying changes. Renders the planned `delete + replace` for each bug.
- `--allow-band-aid="<bug-id-or-index>=<reason>"` — explicit, per-bug exception escape hatch. Requires a written justification; recorded in the discipline log. Use sparingly. (Mirrors Operative 1C exception rules.)

## Workflow

### Phase 0 — Intake

1. Parse the input list into discrete bug records. Assign each a stable index `b1..bN` for logging.
2. For each bug, classify the descriptor type (description / file / GH issue / story id) and resolve any references:
   - GitHub issue → fetch title + body via `gh issue view`
   - P2E story id → fetch via `mcp__p2e__stories op=get`
3. Group bugs by likely shared root cause (same component, same theme token, same data path). Grouped bugs share a single root-cause pass to avoid duplicating diagnostic work.
4. Render an intake summary: bug index, descriptor, classification, group. Ask the user to confirm groupings (they often know better than the model). If `--dry-run` is set, this summary forms part of the final output.

### Phase 1 — Reproduce

For each bug (or group):

1. Establish the broken behavior concretely: the smallest case that demonstrates it. For UI bugs, this means rendering the component and observing the visual symptom. For logic bugs, a failing test or a reproduction script.
2. If reproduction requires running the app, spin it up (dev server, test command from `package.json`, etc.) and confirm.
3. If reproduction is not possible from the provided context, STOP that bug and report what's missing. Do not proceed to root-cause on a bug you cannot trigger.

### Phase 2 — Root cause

Invoke the host's systematic-debugging primitive (see Preconditions). The output of this phase is a written root cause for each bug, with these fields:

- **Symptom:** the observed behavior
- **Mechanism:** the code path that produces the symptom
- **Cause:** the underlying decision/omission that made the mechanism wrong
- **Blast radius:** other places likely affected by the same cause

If you cannot fill all four fields with confidence, the diagnostic is incomplete. Loop or escalate. **Do not move to fix-shape gate without a written cause.**

### Phase 3 — Fix-shape gate (the discipline)

This is the phase that distinguishes this workflow from a normal bug fix. For each bug, answer **in this order**:

1. **What should be DELETED?** Name the lines, files, or constructs that are wrong. If the answer is "nothing — I just need to add X," that is a red flag: re-examine the root cause. Pure additions are valid only when the bug is a missing-feature class (e.g. "we never handled timezones at all"), not a broken-implementation class.
2. **What should be REPLACED?** Describe the right-shaped construct that goes in place of what's deleted. This is where the model reaches for the proper abstraction: theme tokens instead of inline colors, library components instead of hand-rolled ones (Operative 1), shared helpers instead of duplicated logic.
3. **What is being PRESERVED?** Make explicit which surrounding code stays. Helps catch accidental over-deletion and forces a clean diff.
4. **What is the band-aid alternative I'm rejecting?** State the patch that would also "fix" the bug locally. Naming the band-aid out loud makes the choice deliberate. Examples to call out: inline style overrides, new `if (theme === 'dark')` branches where tokens belong, `!important`, fallback layers, defensive try/catches that swallow the symptom, new conditional on a single one-off case, suppressing a failing assertion.

Render the gate output for each bug. If `--dry-run` is set, this is the final output. Otherwise, ask the user to ACCEPT, REVISE, or SKIP per bug. Only ACCEPTED bugs proceed.

If the user invoked `--allow-band-aid` for a specific bug, this phase records the exception with the user-provided reason and skips items 1–4 for that bug. The exception is logged verbatim.

### Phase 4 — Apply

For each ACCEPTED bug, in this order (do not interleave):

1. **Delete** the code identified in step 1 of the gate. Commit the deletion as its own logical change in the diff (does not need to be a separate git commit, but should be visually separable in review).
2. **Replace** with the right-shaped construct from step 2.
3. Re-read the diff. Confirm the band-aid alternative from step 4 is NOT present in the resulting code. If you accidentally added it, revert and redo.

### Phase 5 — Verify

For each bug:

1. **Original-problem check:** re-run the reproduction from Phase 1. Symptom must be gone.
2. **Regression check:** run the project's test suite (or the closest equivalent — type-check, lint, focused test for the affected area). Anything that was green before must still be green.
3. **Visual check (UI bugs):** render the affected component in the browser. Confirm the fix in light mode, dark mode (if the project has one), and any other relevant theme/state.
4. If either check fails, return to Phase 2 for that bug. Do NOT proceed to log/commit. The first iteration of a fix often reveals a deeper root cause.

### Phase 6 — Log (optional, conditional)

If `.p2e/project.json` is present:

1. For each bug whose descriptor was a P2E story id, append a discipline-log entry to that story via `mcp__p2e__story_log op=append`.
2. The entry contains: bug index, root cause (4 fields from Phase 2), fix shape (4 answers from Phase 3), verification result.
3. If the descriptor was a GitHub issue, post the same summary as a comment on the issue (signed `— bchoor-claude`, matching project convention).
4. If the descriptor was a plain description with no P2E or GH anchor, skip — there's nothing to attach to.

If `.p2e/project.json` is absent, this phase is a no-op. The workflow remains useful in non-P2E repos.

## Outputs

For each bug processed, the workflow emits:

- `bug_id` and original descriptor
- root cause (Symptom / Mechanism / Cause / Blast radius)
- fix shape (Deleted / Replaced / Preserved / Band-aid rejected)
- verification result (Original-problem ✓ / Regression ✓ / Visual ✓ where applicable)
- file diffs touched (paths only — actual diffs are in the git history)

Aggregate output: a per-bug table with status `FIXED | DRY-RUN | SKIPPED | BLOCKED`, plus a one-line summary of what was uprooted across the batch.

## Platform asymmetries

- **Claude Code**: invoke `superpowers:systematic-debugging` in Phase 2. The workflow self-enforces the fix-shape gate; there is no `PreToolUse` hook backstop.
- **Codex**: use the native debugging primitive in Phase 2; escalate to `codex:rescue` if root cause is not reached after one pass. No `PreToolUse` hook is available — the workflow self-enforces the fix-shape gate.
- **Cursor**: use the host's debugging skill in Phase 2 if available; otherwise apply the four-field root-cause checklist directly. No native hook surface; rely on the discipline encoded in this workflow.

## Why this is one workflow, not a skill or hook

A skill (e.g. `superpowers:systematic-debugging`) shapes *how the model thinks*. A hook shapes *what the model is allowed to do*. This workflow is a third thing: a **batched, opinionated procedure** that combines the discipline of the skill with the explicit gate of a hook, plus per-bug logging. It exists because the skill alone doesn't enforce the *shape* of the fix once the cause is known, and a hook alone is too noisy when the user wants to fix three bugs at once with conscious intent.

If you find yourself reaching for `/p2e-fix` for every bug, the band-aid problem is bad enough that you should also configure a `PreToolUse` hook (Claude Code only) to flag the worst patterns at edit-time. The two complement each other.
