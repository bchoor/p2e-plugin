---
name: p2e-html
description: Force the next doc-producing skill in this turn to write a pure single-file HTML doc (overrides the default rich-Markdown output). Use when you want a standalone .html artifact instead of Markdown with embedded HTML blocks.
argument-hint: <followed by the doc-producing skill invocation, e.g. /p2e-html /superpowers:brainstorming redesign the comments rail>
---

# /p2e-html

This command is a thin override that loads pure-HTML-output instructions into context for the next doc-producing skill in the same turn — instead of the default rich-Markdown (Markdown + embedded HTML blocks).

Follow the contract in `workflows/p2e-rich-docs.md` § "When producing pure HTML (`/p2e-html`)". Use `skills/writing-rich-docs/references/template.html` plus the components and strategies from the `writing-rich-docs` skill.

The override applies only to the next doc write in this turn. After that, the default rich-Markdown output resumes.
