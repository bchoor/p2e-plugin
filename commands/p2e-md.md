---
name: p2e-md
description: Force the next doc-producing skill in this turn to write markdown output (overrides the audience classification in CLAUDE.md). Use for trivial config-only ADRs or when you want a fast MD-only spec.
argument-hint: <followed by the doc-producing skill invocation, e.g. /p2e-md /superpowers:brainstorming trivial config-only ADR>
---

# /p2e-md

This command is a thin override that loads MD-output instructions into context for the next doc-producing skill in the same turn.

Follow the contract in `workflows/p2e-rich-html-docs.md` § "When producing MD". The doc-producing skill's normal MD output is used; the existing CLAUDE.md MD conventions still apply.

The override applies only to the next doc write in this turn. After that, default audience-classification resumes.
