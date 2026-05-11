---
name: p2e-md-to-html
description: Convert an existing markdown spec/design/ADR/retro to a rich HTML doc using the writing-rich-html-docs template. Reads the .md file, maps its sections to the canonical HTML shape, writes the result as .html alongside the source. Source .md is preserved for audit.
argument-hint: <path-to-md-file>, e.g. /p2e-md-to-html docs/feat-comments-rail-redesign/spec.md
---

# /p2e-md-to-html

This command converts an existing markdown doc into a rich single-file HTML doc using the canonical template + components.

Follow the contract in `workflows/p2e-rich-html-docs.md` § "When converting MD → HTML". Source `.md` is preserved; output written to the same path with `.html` extension.

After conversion, print a one-line summary of which sections were mapped and which were left as plain prose blocks (so the user can review and adjust if needed).
