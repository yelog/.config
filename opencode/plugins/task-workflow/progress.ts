import { createHash } from 'node:crypto'
import { execFileSync } from 'node:child_process'
import { readFile } from 'node:fs/promises'
import path from 'node:path'

// Include contents, not just git status: successive edits can leave status identical.
export async function fingerprint(root: string): Promise<string> {
  const git = (...args: string[]) => execFileSync('git', args, { cwd: root })
  const hash = createHash('sha256').update(git('rev-parse', 'HEAD'))
  hash.update(git('diff', 'HEAD', '--', '.', ':!docs/plans/**'))
  const files = git('ls-files', '--others', '--exclude-standard', '-z').toString().split('\0').filter(Boolean).sort()
  for (const file of files) {
    if (file.startsWith('docs/plans/')) continue
    hash.update(file).update(await readFile(path.join(root, file)))
  }
  return hash.digest('hex')
}
export function transient(error: unknown): boolean {
  const text = typeof error === 'string' ? error : JSON.stringify(error)
  return /\b(429|500|502|503|504)\b|temporarily unavailable|ECONNRESET|ETIMEDOUT|rate.limit/i.test(text ?? '')
}
export function receiptFrom(text: string, token: string, stage: string): Record<string, any> | undefined {
  try {
    const value = JSON.parse(text)
    if (value?.token === token && value.stage === stage && ['completed', 'progress', 'blocked'].includes(value.status)) return value
  } catch {}
}

export function needsCompletionReview(next: string, stalled: number, rounds: number): boolean {
  return stalled >= 2 || rounds >= 6 || /manual|interactive.*(?:acceptance|terminal)|人工.*验收|PTY|最终.*验收/i.test(next)
}

// A completion review must account for missing functionality separately from optional checks.
export function validCompletionReview(result: Record<string, any>): boolean {
  return result.reviewed === true && Array.isArray(result.requirements) && result.requirements.length > 0 &&
    result.requirements.every((item: any) => typeof item?.requirement === 'string' && item.requirement.trim() &&
      item.status === 'passed' && typeof item.evidence === 'string' && item.evidence.trim()) &&
    Array.isArray(result.remainingRequired) && result.remainingRequired.length === 0 &&
    Array.isArray(result.deferredChecks) && result.deferredChecks.every((item: any) =>
      typeof item?.check === 'string' && typeof item.reason === 'string' && item.reason.trim() && item.required === false)
}
