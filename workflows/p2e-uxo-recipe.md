# P2E UXO Writing Recipe

This document defines the canonical recipe for writing a UXO's `description` and `objectives[]` fields. It is referenced by every workflow that creates or edits a UXO (`p2e-bootstrap`, `p2e-add-story` when a UXO is introduced mid-flow, `p2e-update-story` when UXO placement is re-evaluated, and any direct UXO edit path).

A UXO is a **grouping construct** — it answers "what is this bucket of the product's machinery?" It is not a user-experience narrative; narratives live on the Story layer (RRR). Treat a UXO the way a systems thinker treats a machine part: engine, transmission, brakes. Each part has a clear job; the parts together = the whole machine.

## The core insight

> **MECE is exercised *within* the UXO, not across siblings.**
> Objectives[] come first; the description is their succinct articulation.

Two consequences:

1. **Draft `objectives[]` first**, then write `description` as the synthesis. Writing the description first creates narrative pressure that contaminates the objectives.
2. The MECE test is "does this UXO's set of objectives hold together as a complete, non-overlapping scope?" — not "is this description distinct from the sibling UXO's description?" Sibling disambiguation falls out naturally when each UXO's objectives[] are MECE-clean within itself.

## Step-by-step recipe

### Step 1 — Read the evidence

Before drafting anything, gather:

- The UXO's existing `title`, `tier`, `phaseId`, `description`, `objectives[]`.
- **Every story currently under the UXO** (`mcp__p2e__stories op=list uxo_id=<cuid>`) — titles and tags are enough for the first pass; read full specs only if evidence is thin.
- Sibling UXOs in the same phase+tier cell (for later sibling-MECE sanity, not as the primary MECE gate).

If the UXO has zero stories, the recipe still applies — just use the `title` + any source context as the scope anchor.

### Step 2 — Brainstorm candidate objectives

Enumerate every distinct concern the UXO plausibly owns. Err on the side of too many — you will dedupe in Step 3. Useful prompts:

- What state does this UXO hold?
- What operations mutate that state?
- What invariants does this UXO enforce?
- What boundaries / hardening does it need?
- What lifecycle stages does it go through?

### Step 3 — MECE-audit the candidate list

Apply three passes in order:

1. **Mutual-exclusion pass** — merge overlapping bullets. Two bullets that could reasonably own the same story should collapse into one. Example: "sign-in" + "session expiry" + "sign-out" all collapse into "session lifecycle".
2. **Collective-exhaustiveness pass** — ask: "If I implemented every bullet, is this UXO complete, or is something missing?" Call out gaps explicitly. If a gap is legitimately out of scope for the current release, **flag it** (see `## Gap flagging`) but do not include it — silently including out-of-scope concerns dilutes the UXO.
3. **Story-landing pass** — take every existing story under the UXO and place it on exactly one objective bullet. A story that lands on zero bullets exposes a missing objective; a story that lands on two bullets exposes an ME overlap.

Typical landing size: **3–6 objectives per UXO**. Fewer when the UXO is narrowly scoped; more only when the UXO has genuinely distinct concerns. If you end up with 8+ bullets, either the UXO should be split into two UXOs, or the bullets are too granular.

### Step 4 — Write `objectives[]` as noun-phrase bullets

Each objective is **one sentence fragment naming a concern the UXO owns**. Shape:

- Noun-phrase form (e.g., "Session lifecycle", "Per-project membership list")
- Optionally followed by a parenthetical qualifier clarifying what's inside (e.g., "Sign-in and session lifecycle (Google OAuth; establish, refresh, terminate)")
- NOT story-shaped: avoid imperative verbs ("Establish X", "Let user do Y"). Those belong on Story rows via RRR.
- NOT implementation-leaky: avoid naming libraries, frameworks, or file paths. Those belong on capabilities and story `filesHint`.

### Step 5 — Write `description` as a single sentence synthesis

The description is the **succinct articulation** of the locked objectives[]. Do not add new scope that isn't in the objectives — if you find yourself writing something new, that's a signal to return to Step 2.

**Grammar template:**

```
<capability verb> <capability subject> for <target system>
  — <em-dash enumeration of the key objectives> —
  so <verifiable outcome(s)>, by <release anchor>.
```

**Hard constraints:**

1. One sentence, 25–40 words. Two sentences only when a sibling-MECE disambiguator is genuinely needed.
2. Capability verb (see `## Verb palette` below) — pick the verb that fits the UXO's *kind of work*, not a default.
3. The em-dash enumeration must 1:1 match the objectives[] bullets (condensed form is fine).
4. The `so that` clause must be verifiable, not aspirational — coverage claim, threshold claim, or invariant claim. Avoid "so users feel X" or "so the experience is Y".
5. Release anchor: cite the earliest release by which the UXO is expected to be complete (the latest open layer's release, typically). Use `v0.x` format, not calendar dates.
6. **No implementation leak** — no library names (Better Auth, Prisma, Next.js), no framework-specific mechanisms.
7. **No user-journey verbs** — no `signs in`, `clicks`, `sees`, `chooses`, `opens`. Those are story-layer.

## Verb palette

Vary the verb to match the UXO's dominant mode of work. Sample mappings — not exhaustive:

| Verb | When it fits | Example UXO |
|---|---|---|
| `Establish` | Foundational — the UXO *introduces* a concept to the system | Dashboard sign-in (AU-01) |
| `Broker` | The UXO intermediates between two parties | MCP server OAuth (AU-02) |
| `Enforce` | The UXO keeps an invariant / blocks what's disallowed | User-scoped project access (AU-03) |
| `Govern` | The UXO decides policy within a domain | Role-based authorization (AU-04) |
| `Issue` | The UXO grants credentials or tokens | Personal Access Tokens (AU-05) |
| `Provide` | Generic capability-provision (fallback when nothing more specific fits) | Any |
| `Enable` | The UXO removes a blocker so something becomes possible | API ergonomics UXOs |
| `Expose` | The UXO surfaces a contract (API, UI panel) | MCP tool exposure |
| `Deliver` | Outcome-oriented; the UXO ships a user-facing capability | Report generation |
| `Detect` | The UXO recognizes a condition and reacts | Drift detection |

`Provide` is not wrong, but overusing it makes every description read the same. Pick the verb that describes what the UXO *does*, not what the user receives.

## Quality gates

Before writing, run three gates on the draft:

1. **Substitution gate** — remove the description entirely; do the `title` + `objectives[]` still communicate the UXO? If yes, the description is carrying no unique weight and can be tightened. If no, something is off — probably the objectives[] are too terse or the description is doing real narrative work the objectives should do.
2. **Narrative-smell gate** — read it out loud. If it sounds like a storyboard frame ("a user X, then Y, and then Z"), rewrite in capability-provision voice.
3. **Sibling-MECE gate (last, not first)** — swap this description into a sibling UXO's row. If it could plausibly live there, one of the two UXOs is too broadly scoped.

## Gap flagging

When the MECE audit surfaces a concern that logically belongs to the UXO but is not in scope for the current release, **capture it** — do not include it.

Options for capture, in preference order:

1. **Thin-DRAFT story under the existing UXO** (`op=create` on `stories` with `status: "DRAFT"` and a title naming the gap). Example: an AU-01 gap "account deletion / user lifecycle" becomes `AU-01-L7` DRAFT. Per `## Thin drafts` in `p2e-policy.md`, thin DRAFTs are valid planning artifacts.
2. **Comment / footnote in the source document** if the gap is cross-UXO and doesn't obviously slot anywhere yet.
3. **New UXO proposal** if the gap is clearly a distinct bucket (e.g., MFA, multi-device session management) — surface the proposal to the user via `AskUserQuestion`; do not silently create new UXOs.

Never dilute the current UXO's objectives[] with out-of-scope concerns just because the audit noticed them.

## Worked examples — Authenticate phase (P2E project)

These five UXOs were drafted end-to-end under this recipe.

### AU-01 — Dashboard sign-in *(CORE)*

**objectives[]**

1. Sign-in and session lifecycle (Google OAuth; establish, refresh, terminate)
2. User profile (display data behind the account menu)
3. User preferences (per-user UI state)
4. User-held credentials (user-row secrets encrypted at rest, e.g., GitHub PAT)
5. Auth-endpoint hardening (rate limits on sign-in/auth paths)

**description**

> Establish an authenticated human-user identity for the P2E dashboard — Google sign-in and session lifecycle, profile, preferences, user-held credentials, and auth-endpoint hardening — so every dashboard interaction runs under a known user who self-manages their identity state from one settings surface, by v0.11.

*Verb choice:* `Establish` — AU-01 is what *introduces* the concept of "authenticated user" to the dashboard. *Flagged gaps (not in scope):* account deletion, MFA, multi-device session management.

### AU-02 — MCP server OAuth *(CORE)*

**objectives[]**

1. Protected Resource discovery on unauthenticated calls (RFC 9728)
2. Google-delegated end-user consent
3. Bearer-token issuance to the client
4. Refresh-token rotation
5. Token revocation
6. Refresh-token replay detection

**description**

> Broker OAuth 2.1 authorization for the P2E MCP endpoint — RFC 9728 Protected Resource discovery, Google-delegated consent, bearer-token issuance, refresh-token rotation, revocation, replay detection — so every MCP tool call is token-authenticated and unauthenticated clients can auto-discover the auth flow, by v0.11.

*Verb choice:* `Broker` — P2E sits between the external client and Google.

### AU-03 — User-scoped project access *(ADVANCED)*

**objectives[]**

1. Per-project membership list
2. Membership lifecycle (owner-on-create grant, Owner-driven add/remove)
3. Read-path filtering by membership (list/get)
4. Mutation denial for non-members (create/update/delete)

**description**

> Enforce project-scoped access across the P2E dashboard and MCP — per-project membership list, membership lifecycle (owner-on-create, add, remove), read-path filtering, mutation denial for non-members — so no principal can list, read, or mutate any project where they hold no membership row, by v0.12.

*Verb choice:* `Enforce` — invariant-keeping work (visibility boundary).

### AU-04 — Role-based authorization *(ADVANCED)*

**objectives[]**

1. Single-role assignment per (user, project) pair: Owner / Editor / Viewer
2. Permission matrix (read vs mutation) keyed by role
3. Unified enforcement at the shared server-action layer (UI + MCP resolve identically)
4. Owner-only role management (non-Owners cannot change roles)

**description**

> Govern operations within each P2E project by role — Owner / Editor / Viewer assignment, a permission matrix gating read vs mutation, unified enforcement at the shared server-action layer, Owner-only role management — so any caller's permission verdict is identical whether the call comes via UI or MCP, by v0.12.

*Verb choice:* `Govern` — policy decision work within a bounded domain.

### AU-05 — Personal Access Tokens *(STRETCH)*

**objectives[]**

1. Token lifecycle from the user's dashboard (issue, list, revoke)
2. Token constraints (permission scope, optional project restriction)
3. MCP verification parity (tokens accepted on the same verification path as OAuth bearer tokens)

**description**

> Issue non-interactive credentials for the P2E MCP endpoint — user-driven token lifecycle (issue, list, revoke), token constraints (permission scope, optional project restriction), MCP verification parity with OAuth bearer tokens — so headless clients (CI, scripts) authenticate without a browser consent flow, by v0.12.

*Verb choice:* `Issue` — credential-granting work. *Flagged gap (not in scope):* token expiry / rotation.

## Anti-patterns — what a UXO description is NOT

| Anti-pattern | Example | Why it's wrong |
|---|---|---|
| Narrative / storyboard | "A user signs in with Google and sees only their own projects." | That's a Story-layer RRR. UXO lives above stories. |
| Implementation catalog | "Uses Better Auth session cookies on Next.js middleware routes." | Implementation belongs on capabilities and filesHint. |
| Aspirational metric | "Make sign-in feel seamless and delightful." | Not verifiable; not MECE with siblings. |
| Feature-list grab bag | "Google sign-in, MCP OAuth, roles, PATs, and membership." | That's the phase, not a single UXO. |
| Sibling-overlapping scope | AU-01 claiming "user sees only their own projects" (that's AU-03) | Dilutes sibling MECE. |
| Empty / tautological | "Dashboard sign-in." | Restates the title; adds no scope info. |

## Audit trail

This recipe was authored by calibrating AU-01 across five feedback rounds with the project steward (2026-04-20) and then extended to AU-02..AU-05 under the locked recipe. The resulting descriptions + objectives[] for the Authenticate phase are the canonical reference examples above.
