import { readFile } from 'node:fs/promises'
import { ProtocolError } from './protocol.js'
import type { ReceiptStatus, Stage, TaskState } from './state.js'

export type Receipt = {
  token: string
  attemptId: string
  stage: Exclude<Stage, 'cleanup'>
  status: ReceiptStatus
  completedItems?: string[]
  next?: string
  checks?: string[]
  reason?: string
  question?: string
  reviewed?: boolean
  requirements?: Array<{ id?: string; requirement: string; status: 'passed'; evidence: string }>
  remainingRequired?: string[]
  deferredChecks?: Array<{ check: string; required: false; reason: string }>
}

export async function readReceipt(file: string, state: TaskState): Promise<Receipt> {
  let value: any
  try { value = JSON.parse(await readFile(file, 'utf8')) } catch (error) {
    throw new ProtocolError('recoverable', `receipt is missing or invalid: ${file}`, String(error))
  }
  if (!value || value.token !== state.attempt?.token || value.attemptId !== state.attempt?.attemptId || value.stage !== state.stage) {
    throw new ProtocolError('conflict', 'receipt does not belong to the active attempt')
  }
  if (!['completed', 'progress', 'blocked'].includes(value.status)) throw new ProtocolError('invalid_request', 'receipt has invalid status')
  if (value.status !== 'completed' && (!Array.isArray(value.next) && typeof value.next !== 'string')) {
    throw new ProtocolError('invalid_request', 'progress or blocked receipt requires next/reason')
  }
  return value as Receipt
}

export function validCompletionReview(receipt: Receipt): boolean {
  return receipt.status === 'completed' && receipt.reviewed === true && Array.isArray(receipt.requirements) && receipt.requirements.length > 0 &&
    receipt.requirements.every(item => typeof item.requirement === 'string' && item.requirement.trim() && item.status === 'passed' && typeof item.evidence === 'string' && item.evidence.trim()) &&
    Array.isArray(receipt.remainingRequired) && receipt.remainingRequired.length === 0 &&
    Array.isArray(receipt.deferredChecks) && receipt.deferredChecks.every(item => item && item.required === false && typeof item.check === 'string' && typeof item.reason === 'string' && item.reason.trim())
}

export function receiptArtifact(stage: Exclude<Stage, 'cleanup'>): string {
  return { analyze: 'analysis.md', plan: 'plan.md', implement: 'implementation.md', integrate: 'integration.md' }[stage]
}
