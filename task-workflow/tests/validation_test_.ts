import { describe, expect, test } from 'bun:test'
import { mkdir, readFile } from 'node:fs/promises'
import path from 'node:path'
import { runCheck, requiredChecksPassed } from '../src/validation.js'
import { removeDirectory, gitRepository, stateFixture } from './fixtures.js'

describe('validation evidence', () => {
  test('records a passing command and its output without credentials', async () => {
    const root = await gitRepository()
    try {
      const state = stateFixture(root)
      const output = path.join(root, 'task-output')
      const record = await runCheck(state, { id: 'pass', command: ['node', '-e', 'console.log("ok")'] }, output, root)
      expect(record.exitCode).toBe(0)
      expect(await readFile(record.outputPath, 'utf8')).toContain('ok')
      expect(requiredChecksPassed([record])).toBe(true)
    } finally { await removeDirectory(root) }
  })

  test('does not treat optional failures as required failures', async () => {
    const root = await gitRepository()
    try {
      const state = stateFixture(root)
      const record = await runCheck(state, { id: 'optional', command: ['node', '-e', 'process.exit(2)'], required: false }, path.join(root, 'task-output'), root)
      expect(record.exitCode).toBe(2)
      expect(requiredChecksPassed([record])).toBe(true)
    } finally { await removeDirectory(root) }
  })
})
