#!/usr/bin/env bun
import { mcpCall } from '../mcp'
import { classify } from '../router'
import type { StoryDetail } from '../types'

async function main(): Promise<void> {
  const projectSlug = process.argv[2]
  const storyId = process.argv[3]
  if (!projectSlug || !storyId) {
    console.error('usage: bun lib/cli/classify.ts <project_slug> <story_id>')
    process.exit(1)
  }
  const raw = await mcpCall<{ story: StoryDetail }>('stories', {
    op: 'get',
    project_slug: projectSlug,
    story_id: storyId,
  })
  const story = (raw as { story?: StoryDetail }).story ?? (raw as unknown as StoryDetail)
  const classification = classify(story)
  process.stdout.write(JSON.stringify(classification) + '\n')
}

main().catch((err) => {
  process.stderr.write(`classify failed: ${err.message}\n`)
  process.exit(2)
})
