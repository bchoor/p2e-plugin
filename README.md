# p2e-plugin — Claude Code plugin for P2E

Three slash commands that drive [P2E](https://github.com/bchoor/p2e) — a self-hosted product-to-engineering tool — from Claude Code, backed by the P2E MCP server:

- `/p2e-add-story` — thin wizard that creates a story (and optionally a UXO) via the p2e MCP, with an auto-created GitHub issue.
- `/p2e-work-on-next-story` — select 1–N PLANNED stories from a queue, classify each (Fast / Standard / Architectural), optionally run the `p2e-architect` (approach selection) and/or `p2e-staff-engineer` (wave planning) subagents, then implement in parallel waves within a single worktree.
- `/p2e-sync-labels` — finisher run after a batch PR merges; transitions `ready → review → done` on linked GitHub issues.

## Install

```
claude plugin install bchoor/p2e-plugin
```

Pin to a tag for stability:

```
claude plugin install bchoor/p2e-plugin@v0.1.0
```

## Configure

The plugin talks to a running P2E instance. Point it at yours via `P2E_MCP_URL`; it defaults to the hosted demo at `https://p2e-mocha.vercel.app/api/mcp`.

```
export P2E_MCP_URL="https://<your-p2e-instance>/api/mcp"
```

### MCP auth

Every MCP call requires a bearer token. Run the OAuth bootstrap once per instance to obtain one and store it in your shell env:

```
export P2E_DEV_BEARER="<access_token>"
```

The full OAuth bootstrap flow (register client → browser authorize → exchange code → stash token) is documented in the main P2E repo's README under "MCP OAuth Bootstrap". Tokens are short-lived (~1h); refresh when expired.

## Commands at a glance

| Command | When to use |
|---|---|
| `/p2e-add-story <description>` | Create a new PLANNED story from a one-line description. Auto-infers phase/tier/UXO, drafts AC + capabilities, opens a GitHub issue with label `ready`. |
| `/p2e-work-on-next-story [story_id=X-YY-LZ] [--full-team] [--dry-run]` | Pick up work. Without args, lists the top-ranked PLANNED stories and lets you multi-select. Classifies each story and routes to the right model tier. |
| `/p2e-sync-labels` | Run after a `/p2e-work-on-next-story` PR merges. Moves linked issues `review → done` and closes them. |

## Track → model mapping

When `/p2e-work-on-next-story` classifies a story, it routes the implementer subagent to this model tier:

| Track | Implementer model |
|---|---|
| Fast | haiku |
| Standard | sonnet |
| Architectural | sonnet |

Opus is reserved for the named `p2e-architect` and `p2e-staff-engineer` agents (pinned via `model: opus` in their frontmatter). Override an implementer's model by including an explicit `opus-justified:` line in the spawn brief.

## Links

- P2E (main repo): https://github.com/bchoor/p2e
- Hosted demo: https://p2e-mocha.vercel.app
- Issue tracker: https://github.com/bchoor/p2e/issues
