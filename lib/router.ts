import type { StoryDetail, Track, AgentModel, Classification } from './types'

const ARCHITECTURAL_TAGS = new Set(['data-model', 'migration', 'infra'])
const FAST_TAGS = new Set(['ui', 'docs', 'copy'])

export const TRACK_MODEL: Record<Track, AgentModel> = {
  Fast: 'haiku',
  Standard: 'sonnet',
  Architectural: 'sonnet',
}

function make(storyId: string, track: Track): Classification {
  return { storyId, track, model: TRACK_MODEL[track] }
}

export function classify(story: StoryDetail): Classification {
  const caps = story.capabilities ?? []
  if (caps.some((c) => c.isBreaking)) return make(story.storyId, 'Architectural')
  if (caps.some((c) => c.action === 'DEPRECATES' || c.action === 'REMOVES')) return make(story.storyId, 'Architectural')

  const tags = story.tags ?? []
  if (tags.some((t) => ARCHITECTURAL_TAGS.has(t))) return make(story.storyId, 'Architectural')

  const acCount = (story.acceptanceCriteria ?? []).length
  if (acCount >= 8) return make(story.storyId, 'Architectural')

  const hasFastTag = tags.some((t) => FAST_TAGS.has(t))
  if (hasFastTag && acCount <= 3) return make(story.storyId, 'Fast')

  return make(story.storyId, 'Standard')
}
