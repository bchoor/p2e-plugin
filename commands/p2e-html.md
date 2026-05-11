---
name: p2e-html
description: Force the next doc-producing skill in this turn to write rich HTML output (overrides the audience classification in CLAUDE.md). Use when you want HTML for a doc that would have defaulted to MD.
argument-hint: <followed by the doc-producing skill invocation, e.g. /p2e-html /superpowers:brainstorming redesign the comments rail>
---

# /p2e-html

This command is a thin override that loads HTML-output instructions into context for the next doc-producing skill in the same turn.

Follow the contract in `workflows/p2e-rich-html-docs.md` § "When producing HTML". Use the canonical template, components, and strategies from the `writing-rich-html-docs` skill.

The override applies only to the next doc write in this turn. After that, default audience-classification resumes.
