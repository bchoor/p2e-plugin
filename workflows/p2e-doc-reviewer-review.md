# p2e-doc-reviewer-review — canonical doc-review reply workflow

Performs a three-step doc-review reply pass on any `.md` or `.html` file containing a `<!-- @doc-review-state … @end-doc-review-state -->` block. Works identically for both file types — the block format is the same HTML comment.

Shared operating rules: see `workflows/p2e-policy.md`.

## Input

Optional: a file path as the first argument. Default: the file being discussed in the current conversation. If ambiguous, ask the user before proceeding.

## Schema (canonical — source of truth: columenlabs/doc-reviewer `src/types.ts`)

```
ReviewState  { version: number; threads: Thread[]; bookmarks?: Bookmark[] }

Thread  {
  id: string            // UUID
  line: number          // snapshot line number (content may have shifted — use anchorText)
  author: string        // reviewer's username
  body: string          // root comment text
  createdAt: string     // ISO 8601
  editedAt?: string
  responses: Response[]
  resolved: boolean
  resolvedBy: string | null
  resolvedAt: string | null
  anchorText?: string   // first 120 chars of the anchored line at create time
  stale?: boolean       // runtime-only, NOT persisted
}

Response  {
  id?: string
  author: string        // "claude" for all AI responses
  body: string
  createdAt: string     // ISO 8601
  editedAt?: string
}

Bookmark  {
  line: number; anchorText?: string; stale?: boolean
  createdAt: string; author?: string; label?: string
}
```

**Never persist `stale` — it is recomputed at load time by the tool.**

## Step 1 — Read and group unresolved threads

1. Read the target file.
2. Parse the JSON block between `<!-- @doc-review-state` and `@end-doc-review-state -->`. The block sits at the very end of the file (only whitespace after the closer).
3. Filter `threads` where `resolved: false`.
4. Group/consolidate by topic (e.g., multiple threads about the same section). Print the grouping as a brief outline so the user can see the scope before you make changes.

## Step 2 — Per-thread reply and spec edits

For each unresolved thread (in document order, by `anchorText` location):

1. **Locate** the thread's topic in the document body using `anchorText` (not `line` — line numbers shift). If `anchorText` is absent, use the `line` field as a fallback.
2. **Make any spec edit** needed to address the comment.
3. **Append a response** object to the thread's `responses[]` (see *Response shape* below).
4. **Do NOT set `resolved`, `resolvedBy`, or `resolvedAt`** — the user resolves, never Claude.

### Response shape — succinct, precise, factual

Reply bodies are **terse status updates**, not essays. Each response MUST include:
- **A direct answer to the comment** (one sentence, no preamble).
- **The exact section(s) edited** by name — e.g., "Updated the Sentry chip popover in the Server stack-layer." or "Added a new `Two routers, two layers` section between the architecture diagram and repo anatomy." — so the reviewer can verify the change without diffing the file.
- **Only if a decision was made**: the position taken (one sentence) and the reason (one sentence).

```json
{
  "author": "claude",
  "body": "<answer> Edited: <named section(s)>. <position + reason, only if applicable>.",
  "createdAt": "<ISO 8601 timestamp>"
}
```

**Hard length cap: 5 sentences or 600 characters, whichever is shorter.** Longer responses require an explicit user ask for depth.

**Required: name the actual edit.** Reference the section heading, callout name, table row, chip popover, capability slot, or wrangler.jsonc key that was changed. If nothing was edited, say so explicitly: "Acknowledged — no spec change because …".

**Forbidden in response bodies:**
- Preambles ("Good question — and the answer is…", "Important to reframe first…", "Three concerns; I'll take them in order…").
- Restating the user's comment in different words before answering.
- "Where I'd push back on the framing" tangents unless the framing is actually wrong and the pushback changes the answer.
- Background lectures the user didn't ask for (what a tool *is*, how a primitive works in general, history of a service).
- Verifying or expanding on facts the comment didn't ask about (don't add Stripe's other plans when asked about the Sentry free tier).
- Listing alternatives that were already in the chip popover.
- Multi-section bodies with `---` separators or `**1.**`/`**2.**` numbering. If the reply needs sections, the reply is too long.
- Worked examples, code blocks longer than 3 lines, or ASCII diagrams. The doc body carries those; the response points at them.

**Good example** (concrete + short, names the edit):
> Sentry Developer free tier: 5k errors/mo + 10k perf units/mo, 30d retention, 1 user, no replays. Team is $26/mo, Business $80/mo. Edited: Sentry chip popover Cons cell (Server layer) + added Sentry-pricing row to the Changelog.

**Bad example** (verbose, no named edit, restates context):
> Great question on Sentry pricing — let me break it down. Sentry's free tier in 2026 includes several components: errors, performance monitoring, and retention windows. Here's the full breakdown: \n\n**Errors:** 5,000/mo \n**Performance:** 10,000/mo \n**Retention:** 30 days \n\n*Where I'd push back gently on framing*: the original "paid above free tier" wording was unhelpfully vague…

## Step 3 — Unanchored sweep

After replying to all threads:

1. Strip the `<!-- @doc-review-state … @end-doc-review-state -->` block from the document body to get the plain text.
2. For each thread, check whether `anchorText` appears in the plain text (zero or 2+ matches = unanchored/stale).
3. For any thread whose `anchorText` is not uniquely present: append a Claude response explaining the drift — point to where the topic now lives (or explain its removal). Do not silently re-anchor or update `anchorText`.

## JSON safety

After updating the block in memory, validate before writing:

```bash
python3 -c "import json, sys; json.loads(sys.stdin.read())" <<< '<the new JSON>'
```

If validation fails, stop and report the parse error — do not write a broken block.

Preserve the existing block format:
```
<!-- @doc-review-state
{ … 2-space-indented JSON … }
@end-doc-review-state -->
```

## Committing

1. Verify the working branch: `git branch --show-current` must NOT be `main` or `master`. If it is, stop and ask the user which branch to use.
2. Stage only the target file.
3. Commit message format:
   ```
   docs(<filename>): doc-review reply pass — N threads addressed, M unanchored flagged
   ```
4. Do not open a PR.

## HTML support

Applies identically to `.html` files. The `<!-- @doc-review-state … @end-doc-review-state -->` block is valid HTML comment syntax. The unanchored detection strips the comment block and searches the remaining document text.

## References

- Schema authority: [columenlabs/doc-reviewer — `src/types.ts`](https://github.com/columenlabs/doc-reviewer/blob/main/src/types.ts)
- Block parser: [columenlabs/doc-reviewer — `src/lib/reviewState.ts`](https://github.com/columenlabs/doc-reviewer/blob/main/src/lib/reviewState.ts)
