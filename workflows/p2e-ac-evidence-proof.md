# P2E AC Evidence Proof Contract

Canonical contract for per-AC verification evidence. Owned by **p2e-plugin**; consumed by the P2E MCP `evidence` tool and the in-app evidence digest viewer.

## Schema: `ac-evidence-proof/v1`

### Required

| Element | Rule |
| --- | --- |
| **Filename** | `ac{N}-proof.md` where N is the 1-based AC index |
| **H1** | `# AC{N} proof — {story-id}` (em dash between "proof" and story id) |
| **Result** | `## Result` with bold verdict: `**PASS**`, `**FAIL**`, or `**BLOCKED**` |
| **Line references** | `<details><summary>Line references</summary>` containing one or more `- \`repo-relative-path:line\`` bullets |

### Recommended

- `## Scope` — one-line scope note
- `## Tests` — table: Location | Test | Result
- `## HTTP proof` — one `### \`path:line\` — title` block per exchange/test cluster
- `Asserted:` bullet list under each proof block with `- \`path:line\` expect(...)`

### Optional companion

`ac{N}-proof.json`:

```json
{
  "schema": "ac-evidence-proof/v1",
  "storyId": "P-07-L9",
  "criterionIndex": 1,
  "verdict": "PASS",
  "focusLines": [{ "file": "test/example.test.ts", "line": 42 }]
}
```

The UI prefers Line references bullets; companion JSON is optional.

## Agent workflow

1. `mcp__p2e__evidence op=template schema=ac-evidence-proof/v1 criterion_index=N story_id=<id>`
2. Fill from verification run (tests, HTTP captures, asserted lines)
3. `mcp__p2e__evidence op=validate_proof content=<md> filename=acN-proof.md` — must return `valid: true`
4. `mcp__p2e__story_assets op=upload_url` (or `link`) with `criterion_id=<ac-cuid>`
5. `mcp__p2e__criteria op=verdict` with matching verdict

## Offline validation

Without MCP:

```bash
bun scripts/validate-ac-evidence-proof.ts path/to/ac1-proof.md
```

Exit 0 = valid; JSON summary on stdout.

## Deprecated formats

- `ac-evidence-digest` with `## Verdict` and `focusLines` JSON inside `<details>`
- `### Exchange N — \`file:line\`` headers (still rendered; migrate to proof blocks)

Spec: `specs/ac-evidence-proof.v1.yaml`. Template: `templates/ac-proof.v1.md`.

## References

- `workflows/p2e-verify-story.md` — gate-engine evidence capture
- `workflows/p2e-policy.md` — verify gate verdict recording
- P2E UI: evidence digest viewer (`parse-evidence-digest.ts`)
