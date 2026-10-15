import { describe, expect, test } from 'bun:test'
import path from 'node:path'
import { readFile } from 'node:fs/promises'
import { removeDirectory, stateFixture, tempDirectory } from './fixtures.js'
import { readState, saveState, writeJsonAtomic } from '../src/storage.js'

describe('durable storage', () => {
  test('writes complete JSON atomically and increments revisions', async () => {
    const root = await tempDirectory('task-storage-')
    try {
      const file = path.join(root, 'state.json')
      const state = stateFixture(root)
      await writeJsonAtomic(file, state)
      const saved = await saveState(file, state, 0)
      expect(saved.revision).toBe(1)
      expect((await readState(file)).revision).toBe(1)
      expect(await readFile(file, 'utf8')).toEndWith('\n')
    } finally { await removeDirectory(root) }
  })

  test('rejects an optimistic revision mismatch without overwriting state', async () => {
    const root = await tempDirectory('task-storage-conflict-')
    try {
      const file = path.join(root, 'state.json')
      const state = stateFixture(root)
      await writeJsonAtomic(file, state)
      await expect(saveState(file, { ...state, revision: 1 }, 0)).rejects.toThrow('revision mismatch')
      expect((await readState(file)).revision).toBe(0)
    } finally { await removeDirectory(root) }
  })
})
