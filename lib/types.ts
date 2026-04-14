export type StoryStatus = 'PLANNED' | 'PARTIAL' | 'BUILT' | 'GAP'
export type Tier = 'CORE' | 'ADVANCED' | 'STRETCH'
export type CapabilityAction = 'INTRODUCES' | 'MODIFIES' | 'FIXED' | 'DEPRECATES' | 'REMOVES'

export interface Capability {
  id?: string
  name: string
  action: CapabilityAction
  description?: string | null
  isBreaking: boolean
}

export interface AcceptanceCriterion {
  id?: string
  text: string
  checked?: boolean
}

export interface StoryDetail {
  id: string
  storyId: string
  title: string
  status: StoryStatus
  tags: string[]
  release: string | null
  storyAs?: string | null
  storyWant?: string | null
  storySoThat?: string | null
  githubIssueNumber?: number | null
  githubIssueUrl?: string | null
  capabilities?: Capability[]
  acceptanceCriteria?: AcceptanceCriterion[]
}

export type Track = 'Fast' | 'Standard' | 'Architectural'

export type AgentModel = 'haiku' | 'sonnet' | 'opus'

export interface Classification {
  storyId: string
  track: Track
  model: AgentModel
}
