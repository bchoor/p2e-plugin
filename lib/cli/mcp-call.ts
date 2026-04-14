#!/usr/bin/env bun
import { mcpCall } from '../mcp'

async function main(): Promise<void> {
  const tool = process.argv[2]
  const argsJson = process.argv[3]
  if (!tool || !argsJson) {
    console.error('usage: bun lib/cli/mcp-call.ts <tool> <json-args>')
    process.exit(1)
  }
  const args = JSON.parse(argsJson) as Record<string, unknown>
  const result = await mcpCall(tool, args)
  process.stdout.write(JSON.stringify(result) + '\n')
}

main().catch((err) => {
  process.stderr.write(`mcp-call failed: ${err.message}\n`)
  process.exit(2)
})
