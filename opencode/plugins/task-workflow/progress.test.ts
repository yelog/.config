import { expect, test } from 'bun:test'
import { initialReviewProgress, recordReviewProgress, hasReviewProgress, checkEvidence, validCompletionReview, requiredExternalCondition } from './progress'

test('validation evidence ignores duplicate order, timestamps and receipt identities, but retains changed results', () => {
  const first = checkEvidence(['2026-10-16T08:00:00Z PASS cargo test --test monitor', 'PASS cargo check', 'PASS cargo check'])
  const second = checkEvidence(['PASS cargo check', '2026-10-17T10:30:01Z PASS cargo test --test monitor'])
  expect([...first].sort()).toEqual([...second].sort())
  expect(checkEvidence(['FAIL cargo test --test monitor'])).not.toEqual(checkEvidence(['PASS cargo test --test monitor']))
  expect(checkEvidence(['PASS receipt implement-12345678-1234-1234-1234-123456789abc.json']))
    .toEqual(checkEvidence(['PASS receipt implement-87654321-4321-4321-4321-cba987654321.json']))
})

test('only new code or new validation evidence clears the unchanged-review streak', () => {
  let progress = recordReviewProgress(initialReviewProgress(), 'code-a', ['PASS cargo check'], true)
  for (let n = 0; n < 3; n++) progress = recordReviewProgress(progress, 'code-a', ['PASS cargo check'], true)
  expect(progress.unchanged).toBe(3)
  expect(hasReviewProgress(progress, 'code-a')).toBe(false)
  expect(hasReviewProgress(progress, 'code-b')).toBe(true)
  const pending = recordReviewProgress(progress, 'code-a', ['PASS cargo test --test monitor'], false)
  expect(pending.unchanged).toBe(3)
  expect(hasReviewProgress(pending, 'code-a')).toBe(true)
  const reviewed = recordReviewProgress(pending, 'code-a', [], true)
  expect(reviewed.unchanged).toBe(0)
  expect(hasReviewProgress(reviewed, 'code-a')).toBe(false)
})

test('legacy checkpoints establish a baseline only when the checkpoint was itself a review', () => {
  const implemented = initialReviewProgress({ review: false, fingerprint: 'new-code', checks: ['PASS monitor test'] })
  expect(implemented.fingerprint).toBeUndefined()
  expect(hasReviewProgress(implemented, 'new-code')).toBe(true)
  const reviewed = initialReviewProgress({ review: true, fingerprint: 'reviewed-code', checks: ['PASS monitor test'] })
  expect(hasReviewProgress(reviewed, 'reviewed-code')).toBe(false)
  expect(reviewed.unchanged).toBe(0)
})

test('required external blockers reject completion while supplementary checks remain deferrable', () => {
  const completed = { reviewed: true, requirements: [{ requirement: 'Implement monitoring', status: 'passed', evidence: 'monitor.ts and monitoring test' }],
    remainingRequired: [], deferredChecks: [{ check: 'Optional manual smoke', required: false, reason: 'PTY unavailable; automated behavior passed' }] }
  expect(validCompletionReview(completed)).toBe(true)
  const blocked = { ...completed, blocker: { kind: 'external', required: true, condition: 'Required live endpoint missing' } }
  expect(requiredExternalCondition(blocked)).toBe('Required live endpoint missing')
  expect(validCompletionReview(blocked)).toBe(false)
  const optional = { ...blocked, blocker: { ...blocked.blocker, required: false } }
  expect(requiredExternalCondition(optional)).toBeUndefined()
  expect(validCompletionReview(optional)).toBe(true)
})
