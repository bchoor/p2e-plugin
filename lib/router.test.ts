import { describe, it, expect } from 'vitest'
import { classify } from './router'
import type { StoryDetail } from './types'

function story(overrides: Partial<StoryDetail>): StoryDetail {
  return {
    id: 'db-id',
    storyId: 'X-01-L1',
    title: 't',
    status: 'PLANNED',
    tags: [],
    release: null,
    capabilities: [],
    acceptanceCriteria: [],
    ...overrides,
  }
}

describe('classify', () => {
  it('returns Architectural + sonnet when any capability is breaking', () => {
    const s = story({
      capabilities: [{ name: 'a', action: 'INTRODUCES', isBreaking: true }],
    })
    const result = classify(s)
    expect(result.track).toBe('Architectural')
    expect(result.model).toBe('sonnet')
  })

  it('returns Architectural + sonnet when capability action is DEPRECATES or REMOVES', () => {
    const r1 = classify(story({ capabilities: [{ name: 'a', action: 'DEPRECATES', isBreaking: false }] }))
    expect(r1.track).toBe('Architectural')
    expect(r1.model).toBe('sonnet')
    const r2 = classify(story({ capabilities: [{ name: 'a', action: 'REMOVES', isBreaking: false }] }))
    expect(r2.track).toBe('Architectural')
    expect(r2.model).toBe('sonnet')
  })

  it('returns Architectural + sonnet for data-model / migration / infra tags', () => {
    expect(classify(story({ tags: ['data-model'] })).track).toBe('Architectural')
    expect(classify(story({ tags: ['migration'] })).track).toBe('Architectural')
    expect(classify(story({ tags: ['infra'] })).track).toBe('Architectural')
    expect(classify(story({ tags: ['data-model'] })).model).toBe('sonnet')
  })

  it('returns Architectural + sonnet when AC count >= 8', () => {
    const ac = Array.from({ length: 8 }, (_, i) => ({ text: `ac ${i}` }))
    const result = classify(story({ acceptanceCriteria: ac }))
    expect(result.track).toBe('Architectural')
    expect(result.model).toBe('sonnet')
  })

  it('returns Fast + haiku for ui/docs/copy tags with <= 3 AC and no breaking caps', () => {
    const r1 = classify(story({ tags: ['ui'], acceptanceCriteria: [{ text: 'a' }] }))
    expect(r1.track).toBe('Fast')
    expect(r1.model).toBe('haiku')
    const r2 = classify(story({ tags: ['docs'], acceptanceCriteria: [] }))
    expect(r2.track).toBe('Fast')
    expect(r2.model).toBe('haiku')
    const r3 = classify(story({ tags: ['copy'], acceptanceCriteria: [{ text: 'a' }, { text: 'b' }, { text: 'c' }] }))
    expect(r3.track).toBe('Fast')
    expect(r3.model).toBe('haiku')
  })

  it('returns Standard + sonnet by default (3 <= AC < 8, no flag tags, no breaking)', () => {
    const ac = Array.from({ length: 5 }, (_, i) => ({ text: `ac ${i}` }))
    const result = classify(story({ tags: ['backend'], acceptanceCriteria: ac }))
    expect(result.track).toBe('Standard')
    expect(result.model).toBe('sonnet')
  })

  it('breaking flag overrides Fast-track tags => Architectural + sonnet', () => {
    const s = story({
      tags: ['ui'],
      acceptanceCriteria: [{ text: 'a' }],
      capabilities: [{ name: 'a', action: 'INTRODUCES', isBreaking: true }],
    })
    const result = classify(s)
    expect(result.track).toBe('Architectural')
    expect(result.model).toBe('sonnet')
  })

  it('AC boundary: exactly 7 AC stays Standard + sonnet (not Architectural)', () => {
    const ac = Array.from({ length: 7 }, (_, i) => ({ text: `ac ${i}` }))
    const result = classify(story({ acceptanceCriteria: ac }))
    expect(result.track).toBe('Standard')
    expect(result.model).toBe('sonnet')
  })

  it('AC boundary: 4 AC with fast tag routes Standard + sonnet (not Fast)', () => {
    const ac = Array.from({ length: 4 }, (_, i) => ({ text: `ac ${i}` }))
    const result = classify(story({ tags: ['ui'], acceptanceCriteria: ac }))
    expect(result.track).toBe('Standard')
    expect(result.model).toBe('sonnet')
  })

  it('fast tag + 8 AC routes Architectural + sonnet (AC overflow wins over fast tag)', () => {
    const ac = Array.from({ length: 8 }, (_, i) => ({ text: `ac ${i}` }))
    const result = classify(story({ tags: ['ui'], acceptanceCriteria: ac }))
    expect(result.track).toBe('Architectural')
    expect(result.model).toBe('sonnet')
  })

  it('fast tag + architectural tag routes Architectural + sonnet (severity wins)', () => {
    const result = classify(story({ tags: ['ui', 'data-model'], acceptanceCriteria: [{ text: 'a' }] }))
    expect(result.track).toBe('Architectural')
    expect(result.model).toBe('sonnet')
  })

  it('empty story (no tags, no caps, no AC) routes Standard + sonnet', () => {
    const result = classify(story({}))
    expect(result.track).toBe('Standard')
    expect(result.model).toBe('sonnet')
  })

  it('storyId is propagated in Classification', () => {
    const s = story({ storyId: 'B-05-L7' })
    expect(classify(s).storyId).toBe('B-05-L7')
  })
})
