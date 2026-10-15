import path from 'node:path'
import { ProtocolError } from './protocol.js'

export const stages = ['analyze', 'plan', 'implement', 'integrate', 'cleanup'] as const
export type Stage = typeof stages[number]
export type WorkStage = Exclude<Stage, 'cleanup'>
export const integrationSteps = ['verify', 'commit', 'merge', 'verify_target', 'cleanup'] as const
export type IntegrationStep = typeof integrationSteps[number]
export type TaskStatus = 'pending' | 'running' | 'waiting_input' | 'paused' | 'blocked' | 'recoverable' | 'done'
export type ReceiptStatus = 'completed' | 'progress' | 'blocked'

export type ModelRef = { provider?: string; model: string }
export type Authorization = { commit: boolean; merge: boolean; cleanup: boolean }
export type Attempt = {
  attemptId: string
  token: string
  stage: WorkStage
  review: boolean
  startedAt: string
  receiptPath: string
  turnId?: string
  expectedRevision: number
}

export type ValidationRecord = {
  id: string
  command: string[]
  cwd: string
  exitCode: number | null
  startedAt: string
  finishedAt: string
  codeFingerprint: string
  environment: Record<string, string>
  outputPath: string
  required: boolean
}

export type TaskState = {
  schemaVersion: 1
  revision: number
  taskId: string
  sessionId: string
  requirement: string
  root: string
  commonDir: string
  targetBranch: string
  initialBase: string
  base: string
  name: string
  planRelative: string
  taskBranch: string
  worktree: string
  stage: Stage
  integrationStep?: IntegrationStep
  status: TaskStatus
  createdAt: string
  updatedAt: string
  authorization: Authorization
  models: { planner: ModelRef; executor: ModelRef }
  modelPolicy: 'follow' | 'pinned'
  budget: { runRounds: number; totalRounds: number; maxRunRounds: number; maxTotalRounds: number; corrections: number }
  attempt?: Attempt
  reviewPending: boolean
  reviewedCommit?: string
  artifacts: { analysis: string; plan: string; implementation: string; integration: string; validation: string; changeScope: string }
  validations: ValidationRecord[]
  lastError?: string
  next?: string
  pauseReason?: string
  targetBefore?: string
  targetAfter?: string
  mergeCommit?: string
}

export type TaskSummary = Pick<TaskState, 'taskId' | 'sessionId' | 'name' | 'stage' | 'status' | 'revision' | 'root' | 'worktree' | 'taskBranch' | 'targetBranch' | 'reviewPending' | 'next' | 'lastError'> & {
  running: boolean
  model: string
  round: number
  totalRounds: number
}

export function taskDir(state: TaskState): string {
  return path.join(state.commonDir, 'task-workflow', 'tasks', state.taskId)
}

export function isStage(value: unknown): value is Stage {
  return typeof value === 'string' && (stages as readonly string[]).includes(value)
}

export function assertState(value: unknown): TaskState {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new ProtocolError('invalid_state', 'state.json must be an object')
  const state = value as Partial<TaskState>
  if (state.schemaVersion !== 1 || typeof state.taskId !== 'string' || typeof state.revision !== 'number' || !isStage(state.stage)) {
    throw new ProtocolError('invalid_state', 'unsupported or corrupt task state')
  }
  if (!state.status || !state.root || !state.commonDir || !state.sessionId || !state.planRelative) throw new ProtocolError('invalid_state', 'task state is missing required fields')
  return state as TaskState
}

export function advanceStage(state: TaskState): void {
  if (state.stage === 'analyze') state.stage = 'plan'
  else if (state.stage === 'plan') state.stage = 'implement'
  else if (state.stage === 'implement') state.stage = 'integrate'
  else if (state.stage === 'integrate') state.stage = 'cleanup'
  else state.status = 'done'
  state.reviewPending = false
  state.next = undefined
}

export function summary(state: TaskState, running: boolean): TaskSummary {
  const role = state.stage === 'analyze' || state.stage === 'plan' ? state.models.planner : state.models.executor
  return {
    taskId: state.taskId, sessionId: state.sessionId, name: state.name, stage: state.stage, status: state.status,
    revision: state.revision, root: state.root, worktree: state.worktree, taskBranch: state.taskBranch,
    targetBranch: state.targetBranch, reviewPending: state.reviewPending, next: state.next, lastError: state.lastError,
    running, model: role.model, round: state.budget.runRounds, totalRounds: state.budget.totalRounds,
  }
}
