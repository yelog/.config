import { describe, expect, test } from 'bun:test'
import { progressLabel, shouldReview, terminal } from '../src/progress.js'
import { stateFixture } from './fixtures.js'

describe('progress policy', () => {
  test('distinguishes review, terminal and normal execution', () => {
    expect(progressLabel(stateFixture('/repo'))).toBe('running')
    expect(progressLabel(stateFixture('/repo', { reviewPending: true, stage: 'implement' }))).toBe('review')
    expect(progressLabel(stateFixture('/repo', { status: 'paused' }))).toBe('paused')
    expect(terminal('done')).toBe(true)
    expect(terminal('running')).toBe(false)
    expect(shouldReview(stateFixture('/repo', { reviewPending: true, stage: 'implement' }))).toBe(true)
  })
})
