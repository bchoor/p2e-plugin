# AC{{N}} proof — {{STORY_ID}}

Verified: {{ISO_TIMESTAMP}}

## Result
**PASS** — describe outcome

## Scope
- Brief scope note for this AC

## Tests
| Location | Test | Result |
|----------|------|--------|
| `path/to/test.ts:42` | describe what was exercised | PASS |

## HTTP proof
### `path/to/test.ts:42` — short title
```http
GET /api/example
```
Asserted:
- `path/to/test.ts:50` expect(response.status).toBe(200);

<details>
<summary>Line references</summary>

- `path/to/test.ts:42`
- `path/to/test.ts:50`

</details>
