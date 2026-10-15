import { describe, expect, test } from 'bun:test'
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { initTask } from '../src/engine.js'
import { ensureWorktree, integrateState } from '../src/integration.js'
import { loadConfig } from '../src/config.js'
import { taskDir, type TaskState } from '../src/state.js'
import { writeJsonAtomic } from '../src/storage.js'
import { removeDirectory, git, gitRepository } from './fixtures.js'

describe('resumable Git integration', () => {
  test('commits only planned files, merges, validates the target and cleans up', async () => {
    const root = await gitRepository()
    try {
      await writeFile(path.join(root, '.gitignore'), '.claude/worktrees/\n')
      git(root, 'add', '.gitignore')
      git(root, 'commit', '-m', 'ignore local worktrees')
      const created = await initTask({ root, sessionId: 'integration-session', requirement: 'Add integration fixture', allowCommit: true, allowMerge: true, allowCleanup: true })
      const stateFile = path.join(taskDir(created.state), 'state.json')
      let state = JSON.parse(await readFile(stateFile, 'utf8')) as TaskState
      state.stage = 'integrate'
      state.integrationStep = 'verify'
      state.status = 'pending'
      await mkdir(taskDir(state), { recursive: true })
      await writeFile(path.join(taskDir(state), state.artifacts.plan), '# integration plan\n')
      await writeFile(path.join(taskDir(state), state.artifacts.changeScope), JSON.stringify({ files: ['src/feature.txt'] }))
      await writeJsonAtomic(stateFile, state)

      state = await ensureWorktree(state)
      await mkdir(path.join(state.worktree, 'src'), { recursive: true })
      await writeFile(path.join(state.worktree, 'src/feature.txt'), 'implemented\n')
      await writeFile(path.join(state.worktree, 'unexpected.txt'), 'must not be committed\n')
      // The unexpected file is intentionally present to prove the core blocks
      // instead of broad-staging a model's accidental output.
      await expect(integrateState(stateFile, await loadConfig(root))).rejects.toThrow('exceed declared scope')
      expect((JSON.parse(await readFile(stateFile, 'utf8')) as TaskState).status).toBe('blocked')
      await import('node:fs/promises').then(fs => fs.rm(path.join(state.worktree, 'unexpected.txt')))
      state = JSON.parse(await readFile(stateFile, 'utf8')) as TaskState
      state.status = 'pending'
      state.lastError = undefined
      await writeJsonAtomic(stateFile, state)

      const result = await integrateState(stateFile, await loadConfig(root))
      expect(result.status).toBe('done')
      expect(result.stage).toBe('cleanup')
      expect(git(root, 'branch', '--list', result.taskBranch)).toBe('')
      expect(git(root, 'status', '--porcelain')).toBe('')
      expect(await readFile(path.join(root, 'src/feature.txt'), 'utf8')).toBe('implemented\n')
    } finally { await removeDirectory(root) }
  })

  test('preserves the task when target validation fails', async () => {
    const root = await gitRepository()
    try {
      await writeFile(path.join(root, '.gitignore'), '.claude/worktrees/\n')
      git(root, 'add', '.gitignore')
      git(root, 'commit', '-m', 'ignore local worktrees')
      await writeFile(path.join(root, '.task-workflow.json'), JSON.stringify({ validations: [{ id: 'fail', command: ['node', '-e', 'process.exit(2)'], required: true }] }))
      const created = await initTask({ root, sessionId: 'validation-session', requirement: 'Fail validation', allowCommit: true, allowMerge: true, allowCleanup: true })
      const stateFile = path.join(taskDir(created.state), 'state.json')
      let state = JSON.parse(await readFile(stateFile, 'utf8')) as TaskState
      state.stage = 'integrate'; state.integrationStep = 'verify'; state.status = 'pending'
      await writeFile(path.join(taskDir(state), state.artifacts.plan), '# plan\n')
      await writeFile(path.join(taskDir(state), state.artifacts.changeScope), JSON.stringify({ files: ['src/feature.txt'] }))
      await writeJsonAtomic(stateFile, state)
      state = await ensureWorktree(state)
      await mkdir(path.join(state.worktree, 'src'), { recursive: true })
      await writeFile(path.join(state.worktree, 'src/feature.txt'), 'implemented\n')
      await expect(integrateState(stateFile, await loadConfig(root))).rejects.toThrow('required target validation failed')
      const preserved = JSON.parse(await readFile(stateFile, 'utf8')) as TaskState
      expect(preserved.status).toBe('blocked')
      expect(await readFile(path.join(state.worktree, 'src/feature.txt'), 'utf8')).toBe('implemented\n')
    } finally { await removeDirectory(root) }
  })
})
