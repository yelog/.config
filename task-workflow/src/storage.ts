import { mkdir, readFile, rename, rm, writeFile, stat } from 'node:fs/promises'
import path from 'node:path'
import { randomUUID } from 'node:crypto'
import { ProtocolError } from './protocol.js'
import { assertState, type TaskState } from './state.js'

export async function ensureDir(directory: string): Promise<void> {
  await mkdir(directory, { recursive: true })
}

export async function exists(file: string): Promise<boolean> {
  try { await stat(file); return true } catch { return false }
}

export async function readJson<T>(file: string): Promise<T> {
  try { return JSON.parse(await readFile(file, 'utf8')) as T } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') throw new ProtocolError('not_found', `File not found: ${file}`)
    throw new ProtocolError('recoverable', `Cannot read JSON: ${file}`, String(error))
  }
}

export async function writeJsonAtomic(file: string, value: unknown): Promise<void> {
  await ensureDir(path.dirname(file))
  const temporary = `${file}.${process.pid}.${randomUUID()}.tmp`
  try {
    await writeFile(temporary, `${JSON.stringify(value, null, 2)}\n`, { mode: 0o600 })
    await rename(temporary, file)
  } finally {
    await rm(temporary, { force: true }).catch(() => {})
  }
}

export async function readState(file: string): Promise<TaskState> {
  return assertState(await readJson<unknown>(file))
}

export async function saveState(file: string, state: TaskState, expectedRevision?: number): Promise<TaskState> {
  if (expectedRevision !== undefined && state.revision !== expectedRevision) {
    throw new ProtocolError('conflict', `state revision mismatch: expected ${expectedRevision}, got ${state.revision}`)
  }
  const next = { ...state, revision: state.revision + 1, updatedAt: new Date().toISOString() }
  await writeJsonAtomic(file, next)
  return next
}
