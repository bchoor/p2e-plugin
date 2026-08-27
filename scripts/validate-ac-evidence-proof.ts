#!/usr/bin/env bun
/**
 * Offline validator for ac-evidence-proof/v1 markdown.
 * Mirrors mcp__p2e__evidence op=validate_proof for CI and local use without MCP.
 *
 * Usage: bun scripts/validate-ac-evidence-proof.ts path/to/ac1-proof.md
 */

import { readFileSync } from 'node:fs'
import { basename } from 'node:path'

const H1_PROOF_RE = /^#\s*AC(\d+)\s+proof\s*[—–-]\s*(.+)$/im
const VERDICT_VALUE_RE = /\*\*(PASS|FAIL|BLOCKED)\*\*/i
const DETAILS_RE = /<details>\s*<summary>([\s\S]*?)<\/summary>\s*([\s\S]*?)<\/details>/gi
const FILE_LINE_BACKTICK_RE = /`([^`:\n]+):(\d+)`/

function parseFocusLineBullets(text: string): { file: string; line: number }[] {
  const out: { file: string; line: number }[] = []
  for (const raw of text.split('\n')) {
    const trimmed = raw.trim()
    if (!trimmed.startsWith('-')) continue
    const m = FILE_LINE_BACKTICK_RE.exec(trimmed)
    if (m) out.push({ file: m[1]!, line: Number(m[2]) })
  }
  return out
}

function extractDetailsBlocks(markdown: string) {
  const blocks: { summary: string; focusLines: { file: string; line: number }[] }[] = []
  const cleaned = markdown.replace(DETAILS_RE, (_full, summary: string, body: string) => {
    blocks.push({ summary: summary.trim(), focusLines: parseFocusLineBullets(body) })
    return ''
  })
  return { cleaned, blocks }
}

function parseVerdict(markdown: string): string | null {
  const result = markdown.match(/## Result\s*\n+([^\n#]+)/i)
  return result?.[1]?.trim() ?? null
}

function validate(content: string, filename: string) {
  const errors: string[] = []
  const warnings: string[] = []

  const h1 = H1_PROOF_RE.exec(content)
  if (!h1) errors.push('Missing H1: `# AC{N} proof — {story-id}`')

  if (!/## Result\b/im.test(content)) {
    errors.push('Missing `## Result` section')
  }

  const verdictLine = parseVerdict(content)
  if (verdictLine && !VERDICT_VALUE_RE.test(verdictLine)) {
    errors.push('Result must include **PASS**, **FAIL**, or **BLOCKED**')
  }

  const { blocks } = extractDetailsBlocks(content)
  const lineRef = blocks.find((b) => /line references/i.test(b.summary))
  if (!lineRef) {
    errors.push('Missing `<details><summary>Line references</summary>` block')
  } else if (lineRef.focusLines.length === 0) {
    errors.push('Line references must include at least one `- `path:line`` bullet')
  }

  if (!/^ac\d+-proof\.md$/i.test(filename)) {
    warnings.push(`Filename should be ac{N}-proof.md (got ${filename})`)
  }

  return { valid: errors.length === 0, errors, warnings, focusLineCount: lineRef?.focusLines.length ?? 0 }
}

const path = process.argv[2]
if (!path) {
  console.error('Usage: bun scripts/validate-ac-evidence-proof.ts <acN-proof.md>')
  process.exit(2)
}

const content = readFileSync(path, 'utf8')
const result = validate(content, basename(path))
console.log(JSON.stringify({ ...result, schema: 'ac-evidence-proof/v1', filename: basename(path) }, null, 2))
process.exit(result.valid ? 0 : 1)
