import { describe, expect, test } from 'bun:test'
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { completeTask, initTask, nextTask } from '../src/engine.js'
import { taskDir } from '../src/state.js'
import { removeDirectory, git, gitRepository } from './fixtures.js'

async function receiptFor(next: any, status: any = 'completed', extra: Record<string, unknown> = {}): Promise<void> {
  const payload = { token: next.token, attemptId: next.attemptId, stage: next.stage, status, ...extra }
  await writeFile(next.receiptPath, JSON.stringify(payload))
  await mkdir(path.dirname(next.receiptPath), { recursive: true })
}

describe('workflow engine', () => {
  test('creates a task, rejects stale receipts, and advances through planning', async () => {
    const root = await gitRepository()
    try {
      const created = await initTask({ root, sessionId: 'session-1', requirement: 'Add cache invalidation', allowCommit: true, allowMerge: true, allowCleanup: true })
      expect(created.state.stage).toBe('analyze')
      const analyze = await nextTask({ root, sessionId: 'session-1' })
      await expect(completeTask({ root, sessionId: 'session-1', attemptId: analyze.attemptId, token: 'old-token' })).rejects.toThrow('stale attempt')
      await receiptFor(analyze)
      await writeFile(path.join(taskDir(created.state), created.state.artifacts.analysis), '# analysis\n')
      const afterAnalyze = await completeTask({ root, sessionId: 'session-1', attemptId: analyze.attemptId, token: analyze.token })
      expect(afterAnalyze.summary.stage).toBe('plan')
      const plan = await nextTask({ root, sessionId: 'session-1' })
      await receiptFor(plan)
      const current = JSON.parse(await readFile(path.join(created.state.commonDir, 'task-workflow', 'tasks', created.state.taskId, 'state.json'), 'utf8'))
      await writeFile(path.join(taskDir(current), current.artifacts.plan), '# plan\n')
      await writeFile(path.join(taskDir(current), current.artifacts.changeScope), JSON.stringify({ files: ['src/cache.ts'] }))
      const afterPlan = await completeTask({ root, sessionId: 'session-1', attemptId: plan.attemptId, token: plan.token })
      expect(afterPlan.summary.stage).toBe('implement')
    } finally { await removeDirectory(root) }
  })

  test('requires a review after implementation before integration', async () => {
    const root = await gitRepository()
    try {
      const created = await initTask({ root, sessionId: 'session-review', requirement: 'Add feature', allowCommit: true, allowMerge: true, allowCleanup: true })
      const stateFile = path.join(taskDir(created.state), 'state.json')
      let state = JSON.parse(await readFile(stateFile, 'utf8'))
      state.stage = 'implement'; state.worktree = path.join(root, '.claude', 'worktrees', 'review-worktree'); state.taskBranch = 'task/review'; state.base = git(root, 'rev-parse', 'HEAD')
      await writeFile(stateFile, JSON.stringify(state))
      const attempt = await nextTask({ root, sessionId: 'session-review' })
      await receiptFor(attempt, 'completed')
      await mkdir(path.dirname(attempt.receiptPath), { recursive: true })
      await writeFile(path.join(taskDir(state), state.artifacts.implementation), '# implementation\n')
      const review = await completeTask({ root, sessionId: 'session-review', attemptId: attempt.attemptId, token: attempt.token })
      expect(review.review).toBe(true)
    } finally { await removeDirectory(root) }
  })
})
