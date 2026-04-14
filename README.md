# p2e-plugin — Claude Code plugin for P2E

Three slash commands that drive [P2E](https://github.com/bchoor/p2e) — a self-hosted product-to-engineering tool — from Claude Code, backed by the P2E MCP server:

- `/p2e-add-story` — thin wizard that creates a story (and optionally a UXO) via the p2e MCP, with an auto-created GitHub issue.
- `/p2e-work-on-next-story` — select 1–N PLANNED stories from a queue, classify each (Fast / Standard / Architectural), optionally run the `p2e-architect` (approach selection) and/or `p2e-staff-engineer` (wave planning) subagents, then implement in parallel waves within a single worktree.
- `/p2e-sync-labels` — finisher run after a batch PR merges; transitions `ready → review → done` on linked GitHub issues.

## Install

From inside a Claude Code session:

```
/plugin marketplace add bchoor/p2e-plugin
/plugin install p2e@p2e-plugins
```

Pin the marketplace to a tag for stability:

```
/plugin marketplace add bchoor/p2e-plugin@v0.2.0
/plugin install p2e@p2e-plugins
```

(The marketplace is named `p2e-plugins` — that's the `@<marketplace>` suffix on install. The plugin itself is named `p2e`.)

## Configure

The plugin talks to a running P2E instance. It defaults to the hosted demo at `https://p2e-mocha.vercel.app/api/mcp`. Point it at your own instance with `P2E_MCP_URL`:

```
export P2E_MCP_URL="https://<your-p2e-instance>/api/mcp"
```

Auth is handled by Claude Code's MCP OAuth flow on first use — no manual token setup required.

## Commands at a glance

| Command | When to use |
|---|---|
| `/p2e-add-story <description>` | Create a new PLANNED story from a one-line description. Auto-infers phase/tier/UXO, drafts AC + capabilities, opens a GitHub issue with label `ready`. |
| `/p2e-work-on-next-story [story_id=X-YY-LZ] [--full-team] [--dry-run]` | Pick up work. Without args, lists the top-ranked PLANNED stories and lets you multi-select. Classifies each story and routes to the right model tier. |
| `/p2e-sync-labels` | Run after a `/p2e-work-on-next-story` PR merges. Moves linked issues `review → done` and posts the merge sha. |

## Track → model mapping

When `/p2e-work-on-next-story` classifies a story, it routes the implementer subagent to this model tier:

| Track | Implementer model |
|---|---|
| Fast | haiku |
| Standard | sonnet |
| Architectural | sonnet |

Opus is reserved for the named `p2e-architect` and `p2e-staff-engineer` agents (pinned via `model: opus` in their frontmatter). Override an implementer's model by including an explicit `opus-justified:` line in the spawn brief.

## Requirements

- Claude Code CLI (plugin system)
- `gh` CLI authenticated against the P2E GitHub repo (for issue / PR operations)

## Links

- P2E (main repo): https://github.com/bchoor/p2e
- Hosted demo: https://p2e-mocha.vercel.app
- Issue tracker: https://github.com/bchoor/p2e/issues
