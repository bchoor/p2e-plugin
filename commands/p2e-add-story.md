---
name: p2e-add-story
description: Autonomous story creation. Given a free-form description, infer phase/tier/UXO/AC/capabilities/release, show ONE preview, write everything including the GH issue, then print a rich summary with RRR alignment.
argument-hint: <free-form description> [--dry-run]
---

# /p2e-add-story

Take a short description of the story. Do the work. Ask only when genuinely unclear. Finish with a summary that proves the GH issue aligns with the user story.

## Invocation

```
/p2e-add-story <free-form description>   [--dry-run]
```

Examples:

- `/p2e-add-story command palette to fuzzy-search UXOs and stories from the keyboard`
- `/p2e-add-story validator warns when two built layers declare the same capability name`

If the user invokes without a description, ask ONCE via `AskUserQuestion` with a single "Enter description" option (free-text via "Other"). Do not demand fields one at a time.

## Pre-flight

1. Default project slug to `p2e`.
2. Record `--dry-run` flag.

## Step 1. Fetch project context

Call `mcp__p2e__projects` with `{ op: "get", project_slug: "p2e" }`.

Cache as `ctx`. You need `ctx.phases[].title`, `ctx.phases[].uxos[].uxoId/title/tier/id`, and layer counts for story_id derivation.

## Step 2. Infer every field from the description

Do not prompt for these. Infer them, flag the derivation in the preview, and let the user override in Step 3 if anything looks wrong.

### Phase

Keyword match against the phase list (case-insensitive). Prefer the most specific match. On tie, pick the phase with more existing UXOs.

| Keywords in description | Phase |
|---|---|
| sign in, auth, login, oauth, session, access token | Authenticate |
| story map, plan, prioritize, dependency, launch | Plan |
| author, spec, edit story, ai spec, generate spec | Author |
| validate, lint, check, coverage, drift, conflict | Validate |
| server, api, rest, mcp, plugin, command, endpoint | Build |
| stack, layer, relation, breaking change, deprecate | Evolve |
| deploy, vercel, domain, ci, cd, hosting | Infra + CICD |
| website, marketing, landing, docs site, blog | GTM |

If no match, default to the phase with the most existing UXOs.

### Tier

Default `ADVANCED`. Override to:

- `STRETCH` if description contains "nice to have", "experimental", "optional", "stretch"
- `CORE` if description contains "must have", "fundamental", "core", "can't ship without"

### UXO — match existing or propose new

In `ctx.phases[phase].uxos` filtered to the chosen tier:

- Score each UXO's title against the description by (a) shared-word count ≥ 2 OR (b) normalized Levenshtein similarity ≥ 0.5.
- If any UXO passes, propose **attach**: `<uxoId>-L<n+1>` where n = that UXO's existing layer count.
- Otherwise propose **new UXO** with:
  - `uxo_id`: next free in the phase's letter-group (Plan=P, Authenticate=AU, Author=A, Validate=V, Build=B, Evolve=E, Infra + CICD=D, GTM=G). Compute by scanning all UXOs in the project; `<letter(s)>-<max+1>`.
  - `title`: noun-phrase distilled from the description (≤ 40 chars).
  - `description`: `null`.

### Title and user story (RRR: Role / Request / Reason)

- `title`: noun-phrase summary (≤ 60 chars).
- `story_as`: the role mentioned in the description, else `a user`.
- `story_want`: first-person phrasing of the requested action ("I want <verb phrase>").
- `story_so_that`: the benefit stated in the description; if none stated, draft a plausible one based on the value prop (flag as `inferred` in the preview).

### Acceptance criteria — draft 3–5

Break the description into testable outcomes. Each AC is a single verifiable condition phrased as `<Given / When> ... <then> ...` or a flat outcome ("Palette opens in <100ms", "Query filters by prefix case-insensitively"). Do not invent features that aren't in the description.

### Capabilities — draft 1–3

One per distinct behavior change. Format:

- `action`: `INTRODUCES` for new, `MODIFIES` for enhancement to a named existing behavior, `FIXED` for a bug, `DEPRECATES` for removal on notice, `REMOVES` for immediate removal.
- `name`: lower-snake.dot (e.g. `ui.command_palette`, `api.stories_search`).
- `description`: one sentence.
- `isBreaking`: `false` unless description says rename / remove / replace / break.

### Release

Call `mcp__p2e__stories` with `{ op: "list", project_slug: "p2e", status: "PLANNED" }` and pick the most recently created story's `release` field as the default. If none exists, default to `v0.3` and flag `default` in the preview.

## Step 3. Preview + single confirm

Render ONE block. Annotate each line with the derivation type in parentheses: `(matched)` from the description, `(inferred)` Claude-derived, `(default)` fallback, `(query)` looked up via MCP.

```
╭─ Story preview ────────────────────────────────
│ Story:    <proposed_story_id>            (inferred)
│ Phase:    <phase>                         (matched | default)
│ Tier:     <tier>                          (matched | default)
│ Release:  <release>                       (query | default)
│ UXO:      <new|attach> <uxo_id> — <uxo_title>   (new | matched)
│
│ Title:    <title>                         (inferred)
│ RRR:      As <story_as>, I want <story_want>, so that <story_so_that>.
│           role(inferred), request(matched), reason(inferred)
│
│ AC (N):   (inferred)
│   1. <ac text>
│   2. <ac text>
│   ...
│ Caps (N): (inferred)
│   INTRODUCES  <name>  — <description>     [breaking]?
│   ...
│ GH issue: will be created with label `ready`.
│           Body will echo the RRR above verbatim.
╰────────────────────────────────────────────────
```

Then ONE `AskUserQuestion` (options, in order):

1. **Accept and write** (Recommended) — proceed with the preview exactly as shown.
2. **Adjust phase/tier** — re-prompt phase then tier via single-choice lists; re-render preview; re-ask.
3. **Adjust UXO** — show existing UXOs in the selected phase/tier (with layer counts) plus "Create new UXO (edit the proposal)"; on choice, update state and re-render.
4. **Adjust story fields** — free-text (via "Other") for title, then story_as, then story_want, then story_so_that. Re-render after each.
5. **Adjust AC** — free-text; replace the AC list entirely with the user's lines.
6. **Adjust capabilities** — free-text; replace the caps list entirely. Parse each line with regex `^(INTRODUCES|MODIFIES|FIXED|DEPRECATES|REMOVES)(\[!\])?\s+([a-z][a-z0-9_.-]*)\s*—\s*(.*)$`.
7. **Abort** — exit without writing.

The Adjust options loop back to the preview; only `Accept and write` or `Abort` exits the loop.

Under `--dry-run`: print the preview + the exact MCP tool calls the Write section would execute, then exit. No AskUserQuestion, no writes, no GH call.

## Step 4. Write (single batch)

On `Accept and write`, run in order. Stop at the first failure; surface the failing step + item index.

1. **(Only if UXO is new)** Call `mcp__p2e__uxos` with `{ op: "create", project_slug: "p2e", items: [{ phase_title, uxo_id, title, tier, description: null }] }`. Store the returned DB cuid as `resolvedUxoId`.

2. **Create story.** Call `mcp__p2e__stories` with `{ op: "create", project_slug: "p2e", items: [{ story_id: "<uxoId>", uxo_id: "<resolvedUxoId or matched uxo.id>", title, status: "PLANNED", release, tags, story_as, story_want, story_so_that }] }`. The server auto-appends `-L<n+1>`. Store the returned full `storyId`.

3. **Create AC.** Call `mcp__p2e__criteria` with `{ op: "create", project_slug: "p2e", items: [{ story_id, text }, ...] }` (all AC in one batch).

4. **Create capabilities.** Call `mcp__p2e__capabilities` with `{ op: "create", project_slug: "p2e", items: [{ story_id, name, action, description, is_breaking }, ...] }` (all caps in one batch).

5. **Create GH issue.**

   ```bash
   cat > /tmp/p2e-add-story-body.md <<EOF
   Story: **$storyId** — $title
   UXO: $uxoId — $uxoTitle ($phase / $tier)
   Release: $release

   ## User story
   As $story_as, I want $story_want, so that $story_so_that.

   ## Acceptance
   $ac_bullets

   ## Capabilities
   $cap_bullets

   — bchoor-claude
   EOF

   ISSUE_URL=$(gh issue create --repo "$(gh repo view --json nameWithOwner -q .nameWithOwner)" \
     --title "$storyId: $title" \
     --body-file /tmp/p2e-add-story-body.md \
     --label "ready")
   ISSUE_NUMBER=$(basename "$ISSUE_URL")
   ```

6. **Link issue back.** Call `mcp__p2e__stories` with `{ op: "update", project_slug: "p2e", items: [{ story_id, github_issue_number, github_issue_url }] }`.

## Step 5. Final summary

Render:

```
✓ <storyId> created
──────────────────────────────────────────────
Phase / Tier:   <phase> / <tier>
Release:        <release>
UXO:            <uxo_id> — <uxo_title>   (created | attached)

User story (RRR)
  Role:     <story_as>
  Request:  <story_want>
  Reason:   <story_so_that>

Acceptance Criteria (N)
  □ <ac 1>
  □ <ac 2>
  ...

Capabilities (N)
  <ACTION>  <name>  — <description>   [breaking if isBreaking]
  ...

GitHub issue
  URL:    <issue_url>
  Title:  <storyId>: <title>
  Label:  ready
  Body echoes the RRR above — confirmed aligned.
```

Finish with a one-liner: `→ /p2e-work-on-next-story to start work`.

## Idempotency

Buffered state only until Accept. Any `AskUserQuestion` abort at any Adjust loop stage → no MCP writes, no GH calls.

Under `--dry-run` the command is always read-only: it may call `mcp__p2e__projects` and `mcp__p2e__stories` (both reads) to populate the preview, but never `mcp__p2e__uxos.create`, `mcp__p2e__stories.create`, `mcp__p2e__criteria.create`, `mcp__p2e__capabilities.create`, `mcp__p2e__stories.update`, or `gh issue create`.
