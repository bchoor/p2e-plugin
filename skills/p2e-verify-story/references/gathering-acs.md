# Gathering ACs and User Story

The first phase of verification is sourcing the story's title, RRR, and ordered acceptance criteria. Get this wrong and every screenshot afterward is evidence for the wrong question. Always present the parsed story back to the user for confirmation before driving the browser.

In the P2E plugin, P2E MCP is **the default source** — `.p2e/project.json` guarantees a `project_slug`, and `mcp__p2e__stories op=get` returns the canonical record. Spec / issue / free-form are fallbacks for cases without a story id.

## Source 1 — P2E MCP (default)

If the input matches a P2E story id pattern (`DR-08-L8`, `P-01-L3`, `A-04-L7`):

```js
mcp__p2e__stories({
  op: "get",
  project_slug: "<from .p2e/project.json>",
  story_id: "P-01-L3"
})
```

The response contains:
- `story.title` — title for the report header
- `story.storyAs` / `story.storyWant` / `story.storySoThat` — RRR fields (Role / Request / Rationale, in that exact order)
- `story.acceptanceCriteria[]` — array of `{ id, text, checked, order }`. Use `order` for the AC index in the report.
- `story.background` — optional Background paragraph that goes under the user story
- `story.constraints[]`, `story.nonGoals[]` — useful for the "What was NOT verified" section
- `story.filesHint[]` — useful as scope context for the report header
- `story.specFile` — when present, points at the canonical `docs/feat-<topic>/spec.md`; use the parent dir as the default artifacts dir (see `## Output location` in `workflows/p2e-verify-story.md`)
- `story.priority`, `story.sizing`, `story.tags[]`, `story.release` — metadata shown in the report header for context

**If `.p2e/project.json` is missing**, stop and direct the user to `/p2e-bind` first. The verify-story workflow does not write `.p2e/project.json`; that's the bind workflow's job.

**If P2E MCP auth fails** (response is an authentication error rather than a record), stop with the concrete error message. Do not silently fall through to a different source — the user gave a story id, and a story id implies they want the canonical record.

## Source 2 — Spec file under `docs/feat-*/spec.md`

If the user gives a path or names a feature folder:

```bash
cat docs/feat-<topic>/spec.md
```

Expected shape (per the project's doc conventions):

```yaml
---
title: <story title>
hash: <8-char hash>
status: Draft | Review | Done
date: 2026-MM-DD
owner: <name>
---

## Background
<one-paragraph context>

## User story
As a <role>, I want <request>, so that <rationale>.

## Acceptance criteria
1. AC1 text — one testable statement.
2. AC2 text.
...
```

Parsing rules:
- **Title** from frontmatter `title:` field.
- **RRR** from the `As ..., I want ..., so that ...` sentence (single line). If split into a list, concatenate.
- **ACs** from the `## Acceptance criteria` block — both numbered lists (`1. ...`) and bulleted lists (`- ...`) are valid. Strip leading numbers / bullets, keep the rest verbatim.

If the spec uses a different heading like `## ACs` or `## Acceptance Criteria` (capitalization variance), accept it. If the spec has no explicit AC section but lists "Goals" or "Success criteria", treat that as a fallback — but flag the loose mapping in the preview so the user can correct.

## Source 3 — GitHub issue

If the user gives `#91` or `https://github.com/.../issues/91`:

```bash
gh issue view 91 --repo <owner>/<repo> --json title,body,number
```

The body usually follows the same structure as the spec file (often pasted from one — `/p2e-update-story` keeps the issue body in sync with the canonical story), so apply the same parsing. If the issue is terse and lacks structured ACs, prefer Source 1 (look up the linked story by repo / story-id label) before falling back to Source 4.

## Source 4 — User-supplied free-form text

When no structured source is available, ask the user for:
1. The story title
2. The user story / RRR (one sentence)
3. The ACs as a numbered list

Echo back the parsed structure as a preview before continuing.

## Preview format (before any browser action)

Always present a brief preview like this:

```
Story: <story_id> · <title>
Source: <P2E MCP | spec.md path | GH issue #N | user-supplied>
Project: <project_slug from .p2e/project.json>

User story:
  As <role>,
  I want <request>,
  so that <rationale>.

Background: <one-paragraph if present>

ACs to verify:
  1. <AC1 text>
  2. <AC2 text>
  ...

Out-of-scope (will note in report):
  - <non-goal 1>
  - <constraint 1>

Artifacts dir: <resolved path>
Browser MCP: <chrome-devtools | claude-in-chrome>
Dev-server: <package.json script(s) that will be launched>
```

Then ask the four-option confirm via `AskUserQuestion` (Claude) or the host's equivalent (Codex / Cursor): `Proceed with verification`, `Adjust ACs`, `Change artifacts dir`, `Abort`. Do NOT start the browser flow without an explicit `Proceed`.

## Special cases

- **Multi-line AC** — some ACs span multiple sentences ("AC2: switch through Manual / Git: HEAD / Git: ref…; chosen mode persists across reload."). Keep all sentences as one AC; do not split. Each entry in `acceptanceCriteria[]` (or each numbered item in the source) is one verification target.
- **Conditional AC** — "AC3: when no docs root is set, the menu shows 'No folder open'" — treat the precondition as part of the setup phase, not as a separate AC.
- **Backend-only AC** — "AC4: GET /api/foo returns 200 with shape {bar}" — capture via curl into a `.txt` evidence file. Still gets a verdict pill and an Expected / Observed block in the report.
- **Multi-pre-condition AC** — if an AC requires extensive setup (e.g. "AC5: after editing the user's profile in three places, the audit log shows 3 entries"), document the setup explicitly in the Observed column so the reviewer understands what was done.
- **AC already checked in P2E** — `acceptanceCriteria[i].checked === true` means the story author marked it done. The verify-story workflow still re-verifies; the `checked` flag is metadata, not a skip signal.
