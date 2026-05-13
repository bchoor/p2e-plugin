---
name: p2e-md-to-html
description: Convert an existing Markdown spec/design/ADR/retro/postmortem to a pure single-file HTML doc using the writing-rich-docs template. Reads the .md file, maps its sections (and carries over any embedded HTML blocks) to the canonical HTML shape, writes the result as .html alongside the source. Source .md is preserved for audit.
argument-hint: <path-to-md-file>, e.g. /p2e-md-to-html docs/feat-comments-rail-redesign/spec.md
---

# /p2e-md-to-html

This command converts an existing Markdown doc (plain or rich Markdown with embedded HTML blocks) into a pure single-file HTML doc using the canonical template + components.

Follow the contract in `workflows/p2e-rich-docs.md` § "When converting MD → HTML (`/p2e-md-to-html`)". Use `skills/writing-rich-docs/references/template.html`. Source `.md` is preserved; output written to the same path with the `.html` extension.

After conversion, print a one-line summary of which sections were mapped and which were left as plain prose blocks (so the user can review and adjust if needed).
