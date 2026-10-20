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
export type FailureKind = 'quota' | 'rate-limit' | 'transport' | 'lifecycle' | 'user' | 'permanent'
export function failureKind(error: unknown): FailureKind {
  const value = error && typeof error === 'object' ? error as Record<string, any> : {}
  const text = `${error instanceof Error ? error.message : ''} ${typeof error === 'string' ? error : JSON.stringify(error) ?? ''}`
  if (value.reason === 'user') return 'user'
  if (['shutdown', 'inactivity', 'superseded'].includes(value.reason)) return 'lifecycle'
  if (value.type === 'provider.quota' || /insufficient.quota|usage limit.*reach|quota.*(?:exceed|exhaust)|credit balance/i.test(text)) return 'quota'
  if (value.type === 'provider.rate-limit' || value.status === 429 || /\b429\b|rate.limit/i.test(text)) return 'rate-limit'
  if (value.reason === 'Transport' || value._tag === 'ServiceUnavailableError') return 'transport'
  if (/\b(500|502|503|504)\b|temporarily unavailable|ECONNRESET|ECONNREFUSED|ETIMEDOUT|EPIPE|fetch failed|socket.*clos|timed?\s*out|timeout/i.test(text)) return 'transport'
  return 'permanent'
}
export function transient(error: unknown): boolean {
  return ['rate-limit', 'transport'].includes(failureKind(error))
}
export function receiptFrom(text: string, token: string, stage: string): Record<string, any> | undefined {
  try {
    const value = JSON.parse(text)
    if (value?.token === token && value.stage === stage && ['completed', 'progress', 'blocked'].includes(value.status)) return value
  } catch {}
}

export function needsCompletionReview(next: string, stalled: number, rounds: number): boolean {
  // Legacy hints must describe an acceptance check, not database MANUAL mode.
  return stalled >= 2 || rounds >= 6 || /\bmanual\s+(?:TUI\s+)?(?:acceptance|smoke|verification)\b|\binteractive\s+(?:TUI\s+)?(?:acceptance|verification)\b|人工.*验收|\bPTY\b|最终.*验收/i.test(next)
}

export type ReviewReason = 'periodic' | 'completion' | 'stalled' | 'blocked' | 'reassessment'
export type ReviewProgress = {
  fingerprint?: string
  evidence: string[]
  reviewedEvidence: string[]
  unchanged: number
}

// These hashes are a loop-detection heuristic, not proof that a check ran.
// Keep receipt identities, timestamps, ordering and repeated summaries from
// granting fresh progress; keep the command, outcome and result details.
export function checkEvidence(checks: unknown): string[] {
  if (!Array.isArray(checks)) return []
  return [...new Set(checks.filter((check): check is string => typeof check === 'string').map(check => check
    .replace(/\b\d{4}-\d{2}-\d{2}(?:[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?)?\b/g, '')
    .replace(/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/gi, '<id>')
    .replace(/\bmsg_[a-zA-Z0-9_-]+\b/g, '<message>')
    .replace(/\s+/g, ' ').trim()).filter(Boolean)
    .map(check => createHash('sha256').update(check).digest('hex')))].sort()
}

export function initialReviewProgress(checkpoint?: Record<string, any>): ReviewProgress {
  const evidence = checkEvidence(checkpoint?.checks)
  const reviewed = checkpoint?.review === true && typeof checkpoint.fingerprint === 'string'
  return { ...(reviewed ? { fingerprint: checkpoint.fingerprint } : {}), evidence,
    reviewedEvidence: reviewed ? evidence : [], unchanged: 0 }
}

export function hasReviewProgress(progress: ReviewProgress, fingerprint: string): boolean {
  return progress.fingerprint !== fingerprint || progress.evidence.some(check => !progress.reviewedEvidence.includes(check))
}

export function recordReviewProgress(progress: ReviewProgress, fingerprint: string, checks: unknown, review: boolean): ReviewProgress {
  const next = { ...progress, evidence: [...new Set([...progress.evidence, ...checkEvidence(checks)])].sort() }
  if (!review) return next
  return { ...next, fingerprint, reviewedEvidence: [...next.evidence],
    unchanged: hasReviewProgress(next, fingerprint) ? 0 : progress.unchanged + 1 }
}

export type TaskPause = {
  kind: FailureKind | 'external' | 'no-progress' | 'budget' | 'protocol' | 'interrupted'
  message: string
}
export class WorkflowPause extends Error {
  constructor(readonly kind: 'external' | 'no-progress' | 'budget', message: string) { super(message) }
}

export function pauseHint(pause?: TaskPause): string {
  switch (pause?.kind) {
    case 'external': return '补齐所列外部条件或验证结果后运行 /task-resume；将只重新评估一次，条件仍缺失则继续暂停。'
    case 'no-progress': return '检查剩余缺口并补充实现或验证证据后运行 /task-resume；允许一次重新评估，不清零累计预算。'
    case 'budget': return '本阶段 40 轮预算已耗尽；请检查报告并调整任务范围，/task-resume 不会增加预算。'
    case 'quota': return '额度恢复后运行 /task-resume，重试原未完成单元。'
    case 'protocol': return '请检查任务回执和 session 历史，修复记录后再运行 /task-resume。'
    case 'user': return '任务保持停止；需要继续时运行 /task-resume。'
    default: return '处理所列问题后运行 /task-resume。'
  }
}

export function requiredExternalCondition(result?: Record<string, any>): string | undefined {
  const blocker = result?.blocker
  return blocker?.kind === 'external' && blocker.required === true && typeof blocker.condition === 'string' && blocker.condition.trim()
    ? blocker.condition.trim() : undefined
}

export function verificationTimeout(command: string, timeout: number | undefined): number | undefined {
  const rust = /\bcargo(?:\s+\+[^\s]+)?\s+(?:test|check|clippy|build)\b/.test(command)
  const verification = rust || /\b(?:bun|npm|pnpm|yarn)\s+(?:(?:run|exec)\s+)?(?:test|check|lint|typecheck|build)\b|\b(?:pytest|go\s+test|mvn\s+test)\b/.test(command)
  if (!verification) return timeout
  const limit = rust ? 600_000 : 120_000
  return timeout && timeout > 0 ? Math.min(timeout, limit) : limit
}

// A completion review must account for missing functionality separately from optional checks.
export function validCompletionReview(result: Record<string, any>): boolean {
  return !requiredExternalCondition(result) && result.reviewed === true && Array.isArray(result.requirements) && result.requirements.length > 0 &&
    result.requirements.every((item: any) => typeof item?.requirement === 'string' && item.requirement.trim() &&
      item.status === 'passed' && typeof item.evidence === 'string' && item.evidence.trim()) &&
    Array.isArray(result.remainingRequired) && result.remainingRequired.length === 0 &&
    Array.isArray(result.deferredChecks) && result.deferredChecks.every((item: any) =>
      typeof item?.check === 'string' && typeof item.reason === 'string' && item.reason.trim() && item.required === false)
}
