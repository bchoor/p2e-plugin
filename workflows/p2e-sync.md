# P2E Sync Workflow

This is the explicit on-demand drift reconciliation workflow for a single P2E story and its linked GitHub issue. Use it when you suspect the GH issue body has drifted from the P2E story state — for example after a human edited the issue in the GitHub UI, a comment-triggered bot rewrote the body, or an out-of-band PR description was copied in.

This workflow is **user-invoked, not automatic** — it has no polling, no webhook consumer, and no git-hook trigger. It complements `/p2e-sync-labels` (which owns lifecycle label reconciliation) and `/p2e-update-story` (which owns write-through body patches on every non-lifecycle write). Run it ad-hoc per story when drift is suspected.

## Hard rules

- Never write any field without the user having reviewed and confirmed a direction.
- If the GH issue body does not contain the p2e-sync fence (`<!-- p2e-sync:start v1 -->`), abort with a diagnostic pointing at the missing fence and instruct the user to re-run `/p2e-update-story` to regenerate the body before using `/p2e-sync`.
- Every write goes through MCP (`mcp__p2e__stories`, `mcp__p2e__criteria`, `mcp__p2e__capabilities`) — never call `src/lib/audit.ts` directly from the plugin.
- Label reconciliation is out of scope — `/p2e-sync-labels` owns lifecycle labels. Never touch labels.
- This workflow reconciles the issue body only. AC checkbox state (`- [x]` / `- [ ]`) is out of scope (owned by B-02-L3); only AC text is reconciled.
- Bulk multi-story sync is out of scope — single story per invocation. Loop externally if needed.

## Purpose

- Detect field-level drift between a P2E story and its linked GH issue body.
- Render a human-readable diff and let the user choose a reconciliation direction.
- Apply the chosen direction and post a GH comment summarizing what changed.

## Preconditions

- The target story must exist. Use the human-readable story id (e.g. `B-05-L4`), not the DB cuid.
- The story must have a linked GitHub issue (`githubIssueNumber` is non-null). If not, tell the user to run `/p2e-update-story` to create the issue first.
- The linked repo must be reachable via the `gh` CLI with existing auth. No project-level PAT is required — `gh` CLI auth is sufficient.

## Workflow

### When invoked without a story_id

Print a short usage message:

```
Usage: /p2e-sync <story_id>

  Reconcile drift between a P2E story and its linked GitHub issue body.
  This command is user-invoked on-demand (no polling, no webhook, no git-hook).

  Complements:
    /p2e-sync-labels  — lifecycle label reconciliation
    /p2e-update-story — write-through body patch on every update

  Example:
    /p2e-sync B-05-L4
```

### When invoked with a story_id

1. **Fetch both sources in parallel:**
   - Story: `mcp__p2e__stories op=get story_id=<id> project_slug=<slug>`. Capture `storyId`, `title`, `storyAs`, `storyWant`, `storySoThat`, `background`, `release`, `tags`, `acceptanceCriteria[]`, `capabilities[]`, and `githubIssueNumber`.
   - GH issue body: `gh api repos/<repo>/issues/<githubIssueNumber>` (use `project.githubRepo` from `mcp__p2e__projects op=get`). Extract `title` and `body`.

2. **Parse the GH issue body** using the inverse of the `formatIssueBody` write-through template (src/lib/github.ts `parseIssueBody`). The issue body is expected to contain the fence `<!-- p2e-sync:start v1 -->` / `<!-- p2e-sync:end v1 -->`. If either fence is absent, abort:

   ```
   ERROR: Issue body is missing the p2e-sync fence (<!-- p2e-sync:start v1 -->).
   The issue body was either created before B-05-L4 or was hand-edited to remove the fence.
   Fix: run /p2e-update-story <story_id> to regenerate the issue body, then re-run /p2e-sync.
   ```

3. **Compute the field-level diff.** Compare the following fields:

   | Field | P2E source | GH source |
   |---|---|---|
   | title | `story.title` | issue `title` (strip `[<storyId>] ` prefix) |
   | storyAs | `story.storyAs` | parsed `storyAs` |
   | storyWant | `story.storyWant` | parsed `storyWant` |
   | storySoThat | `story.storySoThat` | parsed `storySoThat` |
   | background | `story.background` | parsed `background` |
   | acceptanceCriteria | `story.acceptanceCriteria[].text` | parsed `acceptanceCriteria[].text` |
   | capabilities | `story.capabilities[]` (name+action+isBreaking+description) | parsed `capabilities[]` |
   | release | `story.release` | parsed `release` |

   A field is "in drift" when the P2E value and the GH value differ (null vs empty string counts as equivalent — normalize both to null before comparison).

4. **Render the diff.** If there is no drift, print:

   ```
   /p2e-sync <story_id>: no drift detected — story and issue are in sync.
   ```

   and exit without asking any questions.

   Otherwise, render a compact field-by-field table:

   ```
   Drift detected for <story_id> (issue #<n>):

   Field        | P2E value                   | GH value
   -------------|-----------------------------|---------
   title        | "Foo bar"                   | "Foo bar baz"
   storyAs      | "a PM using P2E"            | "a product manager"
   background   | (empty)                     | "Added by a bot..."
   AC[1].text   | "Fetches story and diff"    | "Fetches story and renders diff"
   cap[0].action| "INTRODUCES"                | "MODIFIES"
   release      | "v0.8.0"                    | (empty)
   ```

   Only drifted fields appear in the table; unchanged fields are not shown.

5. **Confirm direction** using `AskUserQuestion` (Claude host) or native prompt (Codex host):

   ```
   How would you like to reconcile?
   A) Update GH from story  — overwrite the issue body with current P2E state
   B) Update story from GH  — parse GH body and write drifted fields into P2E
   C) Cherry-pick per-field — choose direction per drifted field (Claude host only)
   D) Abort                 — make no changes
   ```

   Codex host exposes only A, B, D (no cherry-pick mode).

6. **Execute the chosen direction** (see sections below).

7. **Post a GH comment** after any successful write:

   ```
   gh issue comment <issue_number> --repo <repo> --body "..."
   ```

   Comment body:
   ```
   /p2e-sync reconciled <story_id> — direction: <direction> — fields: <comma-separated list>

   — bchoor-claude
   ```

---

## Direction A: Update GH from story

Regenerate the full issue body from the current P2E story state using the same `formatIssueBody` template as `/p2e-update-story`'s write-through patch (NOT `/p2e-add-story` — the source-of-truth template shifted in v0.6.0).

Steps:
1. Fetch the full story again (or reuse the result from step 1) including all AC and capabilities.
2. Build the issue body:
   - Format using `formatIssueBody` (src/lib/github.ts) — this produces the fenced body with `<!-- p2e-sync:start v1 -->` / `<!-- p2e-sync:end v1 -->` markers.
   - Title: `[<storyId>] <title>`
3. Write via `gh issue edit <issue_number> --repo <repo> --title "<title>" --body "<body>"`.
   - This preserves the issue's comment thread and labels (labels are owned by `/p2e-sync-labels`).
4. Note: No MCP write is needed for A; the P2E story is unchanged. No AuditLog row is required.

---

## Direction B: Update story from GH

Parse the GH issue body back into MCP fields and write drifted fields into P2E. Only write fields that actually differ — do not overwrite fields that are already in sync.

Steps:
1. Use the parsed body from step 2 above (already validated).
2. Build the MCP update payload from drifted fields only.
3. Issue MCP writes in this exact order, stopping at the first failure:
   a. `mcp__p2e__stories op=update story_id=<id>` — write drifted scalar fields (title, storyAs, storyWant, storySoThat, background, release). Only include fields that actually drifted.
   b. For drifted AC items: `mcp__p2e__criteria op=create/update/delete` per item.
   c. For drifted capability items: `mcp__p2e__capabilities op=create/update/delete` per item.
4. Surface the failing phase + item index on failure so earlier successful writes can be reconciled manually.
5. The MCP layer records AuditLog rows server-side for every mutation — no direct audit calls from the plugin.

### AC reconciliation semantics

- AC is reconciled by text. An AC item is considered the same if its text matches (case-insensitive trim).
- AC checkbox state (`checked`) is preserved from the P2E side — never overwrite checkbox state from GH (B-02-L3 owns that).
- New AC items in GH that don't exist in P2E: create via `mcp__p2e__criteria op=create`.
- AC items in P2E that are missing from GH: delete via `mcp__p2e__criteria op=delete` only if the user explicitly confirmed they should be removed.

### Capability reconciliation semantics

- Capabilities are reconciled by `name`. A capability is considered the same if its name matches.
- Changed fields within a matched capability (action, isBreaking, description): update via `mcp__p2e__capabilities op=update`.
- New capabilities in GH not in P2E: create via `mcp__p2e__capabilities op=create`.
- Capabilities in P2E missing from GH: skip by default (do not delete without explicit confirmation).

---

## Direction C: Cherry-pick per-field (Claude host only)

For each drifted field, ask the user which source wins. Use `AskUserQuestion` with two options per field:
- `P2E wins` — keep the P2E value (no write for this field)
- `GH wins` — write the GH value into P2E (or the P2E value into GH, depending on context)

Batch fields into a single `AskUserQuestion` call where the host allows multi-select (e.g. render as a checklist). If the host only supports single-answer, loop one field at a time.

Apply the per-field decisions using the same write steps as Direction B for GH-wins fields, and Direction A for P2E-wins fields (or skip GH body write if only some fields were selected for A).

---

## Template mismatch abort behavior

If the parsed GH body passes fence validation but a section heading is missing or has unexpected content that prevents parsing a non-null drifted field:

```
WARNING: Could not parse <field> from GH issue body — expected section "## <Heading>" was missing or empty.
The field will be treated as (empty) on the GH side for diff purposes.
```

Do not abort the whole flow for a single unparseable field. Treat it as null on the GH side and include it in the diff if the P2E value is non-null.

---

## AuditLog

Every mutation on `Story`, `AcceptanceCriterion`, or `StoryCapability` writes an AuditLog row server-side via `src/lib/audit.ts` in the P2E main repo. The plugin never calls audit helpers directly — it relies on the MCP layer to record history.

---

## Dry-run behavior

`--dry-run`: read-only. The workflow fetches story + issue, renders the diff, and prints the exact MCP payloads it would write at each phase — but issues no writes, no `gh issue edit`, and no GH comment.

---

## Error behavior

- If the story is not found, stop with a short blocker: `Story <id> not found in project <slug>.`
- If the story has no linked GitHub issue, stop: `Story <id> has no linked GitHub issue. Run /p2e-update-story to promote it to OPEN and create the issue.`
- If `gh api` fails (auth, rate limit, not found), stop with the gh error message verbatim + `Check that gh CLI is authenticated: gh auth status`.
- If Direction B phase fails at item i, stop: `Direction B: phase <phase> failed at item <i>. Earlier writes are persisted. Re-run /p2e-sync or use /p2e-update-story to reconcile manually.`
