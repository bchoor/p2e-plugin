---
name: p2e-update-story
description: Thicken an existing P2E story's spec from a PRD, issue URL, or spec YAML; `--dry-run` previews only.
argument-hint: <story_id> [source=<prd-path-or-issue-url-or-spec-yaml>] [--dry-run]
---

# /p2e-update-story

This command is a thin wrapper over `workflows/p2e-policy.md` and `workflows/p2e-update-story.md`.
Follow the shared workflow contract exactly.

## Preview rendering (sizing)

The preview rendered by this command includes a `sizing` row alongside the other thick-spec fields. During the **Thicken empty fields** action the row is re-inferred from the staged title + capabilities + acceptance-criteria count + tags + `files_hint` length per the rubric in `workflows/p2e-sizing-rubric.md`, annotated `derived-from-source: <evidence>` with the inputs cited inline. The confirm step's **Adjust sizing** (and **Steer** on the `sizing` field) lets the user override to any of `XS | S | M | L | XL | XXL` before the `mcp__p2e__stories op=update` write; the override annotates the row `steered-by-user` in the re-rendered preview.
