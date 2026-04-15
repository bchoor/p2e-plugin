# P2E Codex Compatibility Design

## Goal

Make `p2e-plugin` work as a first-class Codex plugin while keeping Claude and Codex behavior aligned from one shared workflow definition.

## Context

The repo is currently a Claude-oriented plugin:

- Claude command entrypoints live in `commands/`
- Shared policy lives in `skills/p2e/SKILL.md`
- Claude-only named-agent prompts live in `agents/`
- P2E domain operations already run through `.mcp.json`

Codex can support plugin-local skills and MCP servers via `.codex-plugin/plugin.json`, but it does not provide Claude-style slash commands or a manifest-level `agents` field. A direct packaging-only port would install, but it would not preserve the existing workflow surface.

## Outcome

After this change, the plugin should have:

- a Codex plugin manifest that exposes the plugin cleanly in Codex
- Codex-native skills for plain-language routing and direct aliases
- a shared workflow core used by both Claude and Codex adapters
- aligned workflow behavior across both platforms
- `work-on-next` as the canonical orchestrator name on both platforms
- automatic end-of-run label sync in `work-on-next` when context is sufficient
- standalone `sync-labels` kept for explicit repair and targeted reconciliation

## User-Facing Surface

### Codex

Primary experience:

- `p2e` routes plain-language requests such as "work on the next planned story" to the correct internal workflow

Direct aliases:

- `p2e-bootstrap`
- `p2e-add-story`
- `p2e-work-on-next`
- `p2e-sync-labels`

### Claude

Slash commands:

- `/p2e-bootstrap`
- `/p2e-add-story`
- `/p2e-work-on-next`
- `/p2e-sync-labels`

Backward compatibility for `/p2e-work-on-next-story` is intentionally not required.

## Architecture

### 1. Shared workflow core

Create a shared source of truth for workflow behavior that defines the canonical semantics for:

- `bootstrap`
- `add-story`
- `work-on-next`
- `sync-labels`

This shared core should describe:

- inputs and routing rules
- required MCP reads and writes
- GitHub side effects
- orchestration and escalation behavior
- completion and reconciliation behavior

It should be written so both platforms can wrap it without duplicating domain logic.

### 2. Platform adapters

#### Claude adapter

Claude command files remain the user-facing entrypoints, but become thin wrappers over the shared workflow contract instead of being the only place where behavior is defined.

Changes:

- rename `commands/p2e-work-on-next-story.md` to `commands/p2e-work-on-next.md`
- update command instructions to point at the shared workflow contract
- keep Claude-specific invocation details only where slash-command behavior differs from Codex

#### Codex adapter

Codex gets a native plugin package shape:

- `.codex-plugin/plugin.json`
- Codex-facing skills for `p2e`, `p2e-bootstrap`, `p2e-add-story`, `p2e-work-on-next`, and `p2e-sync-labels`

The top-level `p2e` skill owns plain-language routing. The direct skills are explicit aliases and power-user entrypoints.

### 3. Agent orchestration portability

The current named-agent concepts remain, but their invocation changes by platform.

Shared prompt intent:

- architect flow
- staff-engineer wave-planning flow

Platform-specific execution:

- Claude continues using its existing command/agent patterns
- Codex uses subagent prompts invoked through native subagent tooling rather than Claude named-agent manifest support

The prompt content should be shared or closely derived from one source, while invocation instructions stay adapter-specific.

## Runtime and Tooling

### MCP

The plugin remains MCP-first.

- `.mcp.json` stays the authoritative P2E server definition
- `P2E_MCP_URL` remains the override mechanism
- both Claude and Codex workflows use P2E MCP tools for all domain reads and writes

This includes:

- projects
- phases
- UXOs
- stories
- criteria
- capabilities
- relations

### GitHub

GitHub remains the secondary integration layer for:

- issue creation
- issue comments
- PR creation
- label transitions
- final reconciliation

### Boundaries

Domain truth belongs to P2E MCP. Workflow-side GitHub actions must reflect the P2E state machine, not replace it.

## Workflow Semantics

### `bootstrap`

No semantic change is required beyond moving the canonical behavior into the shared workflow core and exposing it in Codex-native form.

### `add-story`

No semantic change is required beyond shared-core extraction and Codex-native access.

### `work-on-next`

This is the main behavioral change.

Required changes:

- make `work-on-next` the canonical name on both platforms
- keep story selection, classification, and escalation behavior aligned across Claude and Codex
- treat end-of-run label reconciliation as part of the normal success path when the workflow has enough context to do it safely

The workflow should still:

- select from PLANNED work
- classify stories
- optionally invoke architect or staff-engineer reasoning
- orchestrate implementation
- update P2E story state
- reconcile GitHub issue labels when the batch run provides sufficient information

### Automatic sync behavior

At the end of a successful `work-on-next` run:

- if the workflow has enough context to reconcile the affected issues safely, it should perform the equivalent of sync-label behavior automatically
- if context is incomplete or ambiguous, it should surface that and leave standalone reconciliation available

This turns label sync into the default finish path without removing explicit operator control.

### `sync-labels`

Keep `sync-labels` as a separate explicit workflow for:

- targeted story reconciliation
- reruns after external changes
- recovery from partial or interrupted orchestrator runs
- repair when normal end-of-run sync could not complete

It is no longer the primary happy path, but it remains an important maintenance tool.

## Source-of-Truth Layout

Recommended structure:

- shared workflow docs or references describing canonical behavior
- shared prompt templates for architect/staff-engineer style subflows where practical
- Claude command wrappers in `commands/`
- Codex skill wrappers in `skills/` or plugin-local skill paths suitable for Codex discovery

The exact folder names can follow the simplest repo shape, but the design requirement is strict:

- workflow semantics must exist once
- platform-specific wrappers may differ
- adapter-specific tool syntax must not become the domain source of truth

## README and Packaging Changes

Update repo documentation to describe both installation surfaces:

- Claude plugin usage
- Codex plugin usage

The README should explain:

- the main `p2e` Codex skill
- direct alias entrypoints
- renamed Claude command surface
- MCP configuration
- the fact that `work-on-next` now performs normal label sync automatically when possible
- when to use standalone `sync-labels`

## Verification Strategy

### Structural verification

Verify:

- Codex manifest wiring to `.mcp.json`
- Codex skill discovery paths
- Claude command wrappers point at the new shared workflow contract
- shared workflow docs cover all four workflows

### Behavioral verification

Verify parity for:

- workflow routing
- story classification
- architect/staff-engineer escalation
- completion-state transitions
- automatic post-run sync semantics
- explicit `sync-labels` repair behavior

### Documentation verification

Verify README examples and naming match the implemented surface exactly.

## Non-Goals

- preserving `/p2e-work-on-next-story`
- keeping Claude and Codex as independently drifting workflow definitions
- replacing MCP with direct GitHub or ad hoc local state logic
- inventing new domain workflows unrelated to the current four commands

## Risks

### Drift during extraction

If shared workflow extraction is partial, the repo may still end up with behavior split across wrapper files. The implementation should aggressively centralize semantics.

### Over-adapting for Codex

Codex-native UX should not silently change domain behavior. Platform adaptation is acceptable; semantic divergence is not.

### Auto-sync overreach

Automatic label sync must only run when the workflow has enough context to do it safely. The standalone `sync-labels` flow remains the fallback when certainty is lower.

## Success Criteria

The work is successful when:

- the plugin installs cleanly as a Codex plugin
- Codex users can invoke `p2e` in plain language and reach the correct workflow
- direct Codex aliases exist for the four workflows
- Claude exposes the same four workflows, including `/p2e-work-on-next`
- both platforms rely on the same shared workflow definitions
- P2E MCP remains the authoritative domain tool layer
- normal `work-on-next` runs reconcile labels automatically when context is sufficient
- standalone `sync-labels` remains available for explicit targeted repair
