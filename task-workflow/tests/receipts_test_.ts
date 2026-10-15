import { describe, expect, test } from 'bun:test'
import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { removeDirectory, stateFixture, tempDirectory } from './fixtures.js'
import { readReceipt, validCompletionReview } from '../src/receipts.js'

describe('receipts', () => {
  test('accepts only the active attempt token and stage', async () => {
    const root = await tempDirectory('task-receipt-')
    try {
      const state = stateFixture(root, { attempt: { attemptId: 'attempt', token: 'token', stage: 'analyze', review: false, startedAt: new Date().toISOString(), receiptPath: path.join(root, 'receipt.json'), expectedRevision: 0 } })
      await writeFile(state.attempt.receiptPath, JSON.stringify({ attemptId: 'attempt', token: 'token', stage: 'analyze', status: 'completed' }))
      expect((await readReceipt(state.attempt.receiptPath, state)).status).toBe('completed')
      await writeFile(state.attempt.receiptPath, JSON.stringify({ attemptId: 'old', token: 'token', stage: 'analyze', status: 'completed' }))
      await expect(readReceipt(state.attempt.receiptPath, state)).rejects.toThrow('does not belong')
    } finally { await removeDirectory(root) }
  })

  test('requires evidence for a completed review and rejects required deferrals', () => {
    const valid = { status: 'completed' as const, reviewed: true, requirements: [{ requirement: 'feature', status: 'passed' as const, evidence: 'test output' }], remainingRequired: [], deferredChecks: [{ check: 'manual UI', required: false as const, reason: 'automated coverage is sufficient' }] }
    expect(validCompletionReview(valid)).toBe(true)
    expect(validCompletionReview({ ...valid, remainingRequired: ['missing behavior'] })).toBe(false)
    expect(validCompletionReview({ ...valid, deferredChecks: [{ check: 'required gate', required: true as false, reason: 'not run' }] })).toBe(false)
  })
})
