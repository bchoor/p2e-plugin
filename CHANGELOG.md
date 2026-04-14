# Changelog

## v0.1.0 — 2026-04-14

Initial public release. Extracted from the private p2e monorepo (B-05-L1).

### Added
- `/p2e-add-story` slash command with inferred phase/tier/UXO + GH issue creation.
- `/p2e-work-on-next-story` batch orchestrator with Architect / Staff Engineer subagents and parallel wave implementation.
- `/p2e-sync-labels` finisher for post-merge label transitions.
- `p2e-architect` (approach selection, opus) and `p2e-staff-engineer` (wave planning, opus) subagents.
- `skills/SKILL.md` documenting P2E concepts, classification rules, and the planning recipe for external agents.
- `P2E_MCP_URL` env var support in `.mcp.json` for pointing at any P2E instance.

### Known limitations
- Requires `P2E_DEV_BEARER` env var; MCP auth is still a manual OAuth bootstrap (one-time per instance).
- Slash commands assume `gh` CLI is installed and authenticated against the P2E repo.
