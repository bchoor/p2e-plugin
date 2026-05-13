---
name: p2e-md
description: Force the next doc-producing skill in this turn to write plain Markdown — no <style> preamble, no embedded HTML blocks (overrides the default rich-Markdown output). Use for trivial config-only ADRs or a fast MD-only spec.
argument-hint: <followed by the doc-producing skill invocation, e.g. /p2e-md /superpowers:brainstorming trivial config-only ADR>
---

# /p2e-md

This command is a thin override that loads plain-Markdown-output instructions into context for the next doc-producing skill in the same turn — suppressing the default rich-Markdown blend (no `<style>` preamble, no embedded HTML blocks).

Follow the contract in `workflows/p2e-rich-docs.md` § "When producing plain Markdown (`/p2e-md`)". The doc-producing skill's normal Markdown output is used; the existing CLAUDE.md MD conventions still apply (no hard-wrapped paragraphs; YAML front-matter on `docs/feat-*/` files).

The override applies only to the next doc write in this turn. After that, the default rich-Markdown output resumes.
