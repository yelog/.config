import { mkdir, open, readFile, rm, stat } from 'node:fs/promises'
import path from 'node:path'
import { randomUUID } from 'node:crypto'
import { ProtocolError } from './protocol.js'

type LockRecord = { owner: string; pid: number; host: string; createdAt: string; kind: string }

async function pidAlive(pid: number): Promise<boolean> {
  if (pid === process.pid) return true
  try { process.kill(pid, 0); return true } catch (error) {
    return (error as NodeJS.ErrnoException).code === 'EPERM'
  }
}

export async function withLock<T>(lockFile: string, kind: string, fn: () => Promise<T>): Promise<T> {
  await mkdir(path.dirname(lockFile), { recursive: true })
  const owner = randomUUID()
  const record: LockRecord = { owner, pid: process.pid, host: process.env.HOSTNAME ?? 'localhost', createdAt: new Date().toISOString(), kind }
  let handle: Awaited<ReturnType<typeof open>> | undefined
  try {
    try {
      handle = await open(lockFile, 'wx', 0o600)
      await handle.writeFile(`${JSON.stringify(record)}\n`)
    } catch (error) {
      const existing = await readFile(lockFile, 'utf8').catch(() => '')
      let current: Partial<LockRecord> = {}
      try { current = JSON.parse(existing) } catch {}
      if (current.pid && !(await pidAlive(current.pid))) {
        throw new ProtocolError('recoverable', `stale ${kind} lock requires explicit recovery: ${lockFile}`, current)
      }
      throw new ProtocolError('conflict', `${kind} lock is held`, current, true)
    }
    return await fn()
  } finally {
    await handle?.close().catch(() => {})
    try {
      const current = JSON.parse(await readFile(lockFile, 'utf8')) as LockRecord
      if (current.owner === owner) await rm(lockFile, { force: true })
    } catch {}
  }
}

export function taskLockFile(directory: string, taskId: string): string {
  return path.join(directory, 'task-workflow', 'locks', `task-${taskId}.lock`)
}

export function integrationLockFile(directory: string, root: string): string {
  const key = Buffer.from(path.resolve(root)).toString('base64url')
  return path.join(directory, 'locks', `integration-${key}.lock`)
}

export async function lockInfo(file: string): Promise<LockRecord | undefined> {
  try { return JSON.parse(await readFile(file, 'utf8')) as LockRecord } catch { return undefined }
}

export async function lockAge(file: string): Promise<number | undefined> {
  try { return Date.now() - (await stat(file)).mtimeMs } catch { return undefined }
}
