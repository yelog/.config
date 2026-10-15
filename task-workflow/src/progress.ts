import { createHash } from 'node:crypto'
import { readFile } from 'node:fs/promises'
import { git } from './git.js'
import type { TaskState } from './state.js'

export async function codeFingerprint(root: string): Promise<string> {
  const hash = createHash('sha256')
  hash.update(await git(root, 'rev-parse', 'HEAD'))
  hash.update(await git(root, 'diff', 'HEAD', '--', '.'))
  const files = (await git(root, 'ls-files', '--others', '--exclude-standard', '-z')).split('\0').filter(Boolean).sort()
  for (const file of files) hash.update(file).update(await readFile(`${root}/${file}`))
  return hash.digest('hex')
}

export function shouldReview(state: TaskState): boolean {
  return state.stage === 'implement' && state.reviewPending
}

export function terminal(status: TaskState['status']): boolean {
  return status === 'done' || status === 'blocked'
}

export function progressLabel(state: TaskState): string {
  if (state.status === 'done') return 'done'
  if (state.status === 'paused' || state.status === 'blocked' || state.status === 'recoverable') return state.status
  if (state.reviewPending) return 'review'
  return state.stage === 'cleanup' ? 'cleaning' : 'running'
}
