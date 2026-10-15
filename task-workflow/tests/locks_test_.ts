import { describe, expect, test } from 'bun:test'
import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { removeDirectory, tempDirectory } from './fixtures.js'
import { lockInfo, taskLockFile, withLock } from '../src/locks.js'

describe('locks', () => {
  test('serializes concurrent owners of a task lock', async () => {
    const root = await tempDirectory('task-lock-')
    try {
      const file = taskLockFile(root, 'one')
      let release!: () => void
      const held = new Promise<void>(resolve => { release = resolve })
      const first = withLock(file, 'task', async () => { await held; return 'first' })
      await Bun.sleep(10)
      await expect(withLock(file, 'task', async () => 'second')).rejects.toThrow('lock is held')
      release()
      expect(await first).toBe('first')
      expect(await lockInfo(file)).toBeUndefined()
    } finally { await removeDirectory(root) }
  })

  test('does not silently remove a stale lock owned by another process', async () => {
    const root = await tempDirectory('task-stale-lock-')
    try {
      const file = taskLockFile(root, 'one')
      await mkdir(path.dirname(file), { recursive: true })
      await writeFile(file, JSON.stringify({ owner: 'old', pid: 999999, host: 'test', createdAt: new Date().toISOString(), kind: 'task' }))
      await expect(withLock(file, 'task', async () => 'value')).rejects.toThrow('stale task lock requires explicit recovery')
    } finally { await removeDirectory(root) }
  })
})
