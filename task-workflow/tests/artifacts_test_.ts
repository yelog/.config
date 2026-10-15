import { describe, expect, test } from 'bun:test'
import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { copyOwnedArtifact, ensurePlanInWorktree } from '../src/artifacts.js'
import { removeDirectory, tempDirectory } from './fixtures.js'

describe('owned artifacts', () => {
  test('copies a task-owned plan idempotently and refuses a different destination', async () => {
    const root = await tempDirectory('task-artifacts-')
    try {
      const source = path.join(root, 'task', 'plan.md')
      const worktree = path.join(root, 'worktree')
      await mkdir(path.dirname(source), { recursive: true })
      await writeFile(source, '# plan\n')
      expect(await ensurePlanInWorktree(source, worktree, 'docs/plans/task.md')).toHaveLength(64)
      expect(await ensurePlanInWorktree(source, worktree, 'docs/plans/task.md')).toHaveLength(64)
      await writeFile(path.join(worktree, 'docs/plans/task.md'), '# other\n')
      await expect(copyOwnedArtifact(source, path.join(worktree, 'docs/plans/task.md'))).rejects.toThrow('destination differs')
    } finally { await removeDirectory(root) }
  })
})
