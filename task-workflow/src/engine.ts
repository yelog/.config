import { randomUUID } from 'node:crypto'
import { mkdir, readFile, readdir } from 'node:fs/promises'
import path from 'node:path'
import { ProtocolError, boolean, object, string } from './protocol.js'
import { branchExists, currentBranch, gitCommonDir, gitRoot, head, isAncestor, git, removeWorktree, statusPorcelain } from './git.js'
import { ensureDir, exists, readJson, readState, saveState, writeJsonAtomic } from './storage.js'
import { taskLockFile, withLock } from './locks.js'
import { advanceStage, summary, taskDir, type ModelRef, type TaskState, type WorkStage } from './state.js'
import { loadConfig, modelFromConfig, worktreePath, type WorkflowConfig } from './config.js'
import { ensureWorktree, integrateState } from './integration.js'
import { parseScope } from './workspace.js'
import { readReceipt, receiptArtifact, validCompletionReview } from './receipts.js'
import { stagePrompt } from './prompts.js'

// Keep the canonical task configuration aligned with the OpenCode adapter.
// The Claude hook maps these magpie model IDs to the local Claude gateway aliases.
const defaultPlanner: ModelRef = { provider: 'magpie', model: 'codex/gpt-6.1-sol' }
const defaultExecutor: ModelRef = { provider: 'magpie', model: 'codex/gpt-6-luna' }

function stateFile(state: TaskState): string { return path.join(taskDir(state), 'state.json') }
function bindingsFile(commonDir: string): string { return path.join(commonDir, 'task-workflow', 'bindings.json') }

async function updateBinding(commonDir: string, sessionId: string, taskId: string | null): Promise<void> {
  const file = bindingsFile(commonDir)
  const bindings = await readJson<Record<string, string>>(file).catch(error => {
    if (error instanceof ProtocolError && error.code === 'not_found') return {}
    throw error
  })
  if (taskId) bindings[sessionId] = taskId
  else delete bindings[sessionId]
  await writeJsonAtomic(file, bindings)
}

async function findBoundTask(root: string, sessionId: string): Promise<TaskState | undefined> {
  const common = await gitCommonDir(root)
  const bindings = await readJson<Record<string, string>>(bindingsFile(common)).catch(() => ({}))
  const taskId = bindings[sessionId]
  if (!taskId) return undefined
  try { return await readState(path.join(common, 'task-workflow', 'tasks', taskId, 'state.json')) } catch { return undefined }
}

function slug(value: string): string {
  const result = value.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 48)
  return result || `task-${randomUUID().slice(0, 8)}`
}

function parseModels(value: unknown, config: WorkflowConfig): { planner: ModelRef; executor: ModelRef } {
  if (value === undefined) return { planner: modelFromConfig(config, 'planner', defaultPlanner), executor: modelFromConfig(config, 'executor', defaultExecutor) }
  const input = object(value, 'models')
  const planner = object(input.planner ?? {}, 'models.planner')
  const executor = object(input.executor ?? {}, 'models.executor')
  return {
    planner: { provider: string(planner.provider, 'models.planner.provider', false), model: string(planner.model, 'models.planner.model')! },
    executor: { provider: string(executor.provider, 'models.executor.provider', false), model: string(executor.model, 'models.executor.model')! },
  }
}

export async function initTask(input: Record<string, unknown>): Promise<{ state: TaskState; summary: ReturnType<typeof summary> }> {
  const root = await gitRoot(string(input.root, 'root')!)
  const sessionId = string(input.sessionId, 'sessionId')!
  const requirement = string(input.requirement, 'requirement')!
  const commonDir = await gitCommonDir(root)
  return withLock(path.join(commonDir, 'task-workflow', 'init.lock'), 'task-init', async () => {
    const config = await loadConfig(root)
    const existing = await findBoundTask(root, sessionId)
    if (existing && existing.status !== 'done') throw new ProtocolError('conflict', `session already has task ${existing.taskId}`)
    const targetBranch = await currentBranch(root)
    const initialBase = await head(root)
    const taskId = randomUUID()
    const name = slug(string(input.name, 'name', false) ?? requirement)
    let selectedName = name
    for (let suffix = 2; ; suffix++) {
      const candidate = suffix === 2 ? name : `${name}-${suffix}`
      const candidateWorktree = worktreePath(root, config, candidate)
      if (!await exists(candidateWorktree) && !await branchExists(root, `task/${candidate}`)) { selectedName = candidate; break }
    }
    const worktree = worktreePath(root, config, selectedName)
    const state: TaskState = {
      schemaVersion: 1, revision: 0, taskId, sessionId, requirement, root, commonDir, targetBranch, initialBase,
      base: initialBase, name: selectedName, planRelative: path.posix.join(config.planDirectory!, `${selectedName}.md`), taskBranch: `task/${selectedName}`, worktree, stage: 'analyze', status: 'pending',
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
      authorization: { commit: boolean(input.allowCommit, 'allowCommit', true), merge: boolean(input.allowMerge, 'allowMerge', true), cleanup: boolean(input.allowCleanup, 'allowCleanup', true) },
      models: parseModels(input.models, config), modelPolicy: input.modelPolicy === 'follow' ? 'follow' : 'pinned',
      budget: { runRounds: 0, totalRounds: 0, maxRunRounds: Number(config.maxRunRounds ?? 40), maxTotalRounds: Number(config.maxTotalRounds ?? 160), corrections: 0 },
      reviewPending: false,
      artifacts: { analysis: 'analysis.md', plan: 'plan.md', implementation: 'implementation.md', integration: 'integration.md', validation: 'validation.md', changeScope: 'change-scope.json' },
      validations: [],
    }
    const directory = taskDir(state)
    await ensureDir(directory)
    await writeJsonAtomic(stateFile(state), state)
    await updateBinding(commonDir, sessionId, taskId)
    return { state, summary: summary(state, false) }
  })
}

export async function statusTask(input: Record<string, unknown>): Promise<ReturnType<typeof summary> | null> {
  const root = await gitRoot(string(input.root, 'root')!)
  const sessionId = string(input.sessionId, 'sessionId')!
  const state = await findBoundTask(root, sessionId)
  return state ? summary(state, Boolean(state.attempt)) : null
}

export async function nextTask(input: Record<string, unknown>): Promise<Record<string, unknown>> {
  const root = await gitRoot(string(input.root, 'root')!)
  const sessionId = string(input.sessionId, 'sessionId')!
  const state = await findBoundTask(root, sessionId)
  if (!state) throw new ProtocolError('not_found', 'no task is bound to this session')
  const file = stateFile(state)
  return withLock(taskLockFile(state.commonDir, state.taskId), 'task', async () => {
    let current = await readState(file)
    if (current.status === 'done') return { kind: 'done', summary: summary(current, false) }
    if (current.attempt) throw new ProtocolError('conflict', 'task already has an active attempt')
    if (current.status === 'paused' || current.status === 'blocked') throw new ProtocolError('blocked', current.pauseReason ?? current.lastError ?? 'task is paused')
    if (current.stage === 'cleanup') return { kind: 'done', summary: summary(current, false) }
    if (current.stage === 'implement') {
      current = await ensureWorktree(current)
      current = await saveState(file, current)
    }
    if (current.budget.totalRounds >= current.budget.maxTotalRounds || current.budget.runRounds >= current.budget.maxRunRounds) {
      current.status = 'paused'; current.pauseReason = 'execution budget exhausted'; current.lastError = current.pauseReason; current = await saveState(file, current)
      throw new ProtocolError('blocked', current.pauseReason)
    }
    const attemptId = randomUUID()
    const token = randomUUID()
    const directory = taskDir(current)
    const receiptPath = path.join(directory, `${current.stage}-${attemptId}.json`)
    current.attempt = { attemptId, token, stage: current.stage as WorkStage, review: current.reviewPending, startedAt: new Date().toISOString(), receiptPath, expectedRevision: current.revision }
    current.status = 'running'
    current.budget.runRounds += 1
    current.budget.totalRounds += 1
    current = await saveState(file, current)
    if (current.stage === 'integrate') return { kind: 'integration', task: current.taskId, attemptId, token, model: current.models.executor, prompt: stagePrompt(current), summary: summary(current, true) }
    return { kind: 'prompt', task: current.taskId, stage: current.stage, review: current.reviewPending, model: current.stage === 'analyze' || current.stage === 'plan' ? current.models.planner : current.models.executor, prompt: stagePrompt(current), receiptPath, token, attemptId, summary: summary(current, true) }
  })
}

async function artifactReady(state: TaskState): Promise<void> {
  const file = path.join(taskDir(state), receiptArtifact(state.stage as Exclude<WorkStage, 'cleanup'>))
  const text = await readFile(file, 'utf8').catch(() => '')
  if (!text.trim()) throw new ProtocolError('recoverable', `required artifact is missing or empty: ${file}`)
}

export async function completeTask(input: Record<string, unknown>): Promise<Record<string, unknown>> {
  const root = await gitRoot(string(input.root, 'root')!)
  const sessionId = string(input.sessionId, 'sessionId')!
  const task = await findBoundTask(root, sessionId)
  if (!task) throw new ProtocolError('not_found', 'no task is bound to this session')
  const file = stateFile(task)
  return withLock(taskLockFile(task.commonDir, task.taskId), 'task', async () => {
    let state = await readState(file)
    const reportedCwd = string(input.cwd, 'cwd', false)
    if (reportedCwd && path.resolve(reportedCwd) !== path.resolve(state.stage === 'implement' ? state.worktree : state.root)) {
      throw new ProtocolError('blocked', `stage completed from the wrong working directory; expected ${state.stage === 'implement' ? state.worktree : state.root}`, { reportedCwd })
    }
    const attempt = state.attempt
    if (!attempt) throw new ProtocolError('conflict', 'task has no active attempt')
    const attemptId = string(input.attemptId, 'attemptId')!
    if (attempt.attemptId !== attemptId || attempt.token !== string(input.token, 'token')) throw new ProtocolError('conflict', 'stale attempt completion')
    const receipt = await readReceipt(attempt.receiptPath, state)
    state.attempt = undefined
    if (receipt.status === 'blocked') {
      state.status = 'blocked'; state.pauseReason = receipt.question ?? receipt.reason ?? 'stage reported an external block'; state.lastError = state.pauseReason
      state = await saveState(file, state)
      return { kind: 'blocked', summary: summary(state, false), reason: state.pauseReason }
    }
    if (receipt.status === 'progress') {
      state.status = 'running'; state.next = receipt.next ?? receipt.reason ?? 'continue current stage'; state.lastError = undefined
      state = await saveState(file, state)
      return { kind: 'continue', summary: summary(state, false), next: state.next }
    }
    await artifactReady(state)
    if (state.stage === 'plan') {
      const scope = await readFile(path.join(taskDir(state), state.artifacts.changeScope), 'utf8').catch(() => '')
      if (!scope.trim()) throw new ProtocolError('recoverable', 'plan must write change-scope.json')
      parseScope(scope)
    }
    if (state.stage === 'implement' && !state.reviewPending) {
      state.reviewPending = true; state.next = 'mandatory completion review'; state.status = 'running'; state = await saveState(file, state)
      return { kind: 'continue', summary: summary(state, false), next: state.next, review: true }
    }
    if (state.stage === 'implement' && state.reviewPending && !validCompletionReview(receipt)) {
      state.reviewPending = true; state.next = 'completion review must provide requirement evidence and no remaining required items'; state.status = 'running'; state = await saveState(file, state)
      return { kind: 'continue', summary: summary(state, false), next: state.next, review: true }
    }
    if (state.stage === 'integrate') {
      state.status = 'pending'; state.integrationStep = 'verify'
      state = await saveState(file, state)
      return { kind: 'integration', summary: summary(state, false) }
    }
    advanceStage(state)
    state.status = 'pending'; state.integrationStep = undefined
    state = await saveState(file, state)
    return state.stage === 'integrate' ? { kind: 'integration', summary: summary(state, false) } : { kind: 'continue', summary: summary(state, false), next: `start ${state.stage}` }
  })
}

export async function resumeTask(input: Record<string, unknown>): Promise<ReturnType<typeof summary>> {
  const root = await gitRoot(string(input.root, 'root')!)
  const sessionId = string(input.sessionId, 'sessionId')!
  const task = await findBoundTask(root, sessionId)
  if (!task) throw new ProtocolError('not_found', 'no task is bound to this session')
  const file = stateFile(task)
  return withLock(taskLockFile(task.commonDir, task.taskId), 'task', async () => {
    let state = await readState(file)
    if (state.status === 'done') return summary(state, false)
    state.attempt = undefined; state.status = 'pending'; state.pauseReason = undefined; state.lastError = undefined; state.budget.runRounds = 0
    state = await saveState(file, state)
    return summary(state, false)
  })
}

export async function pauseTask(input: Record<string, unknown>): Promise<ReturnType<typeof summary>> {
  const root = await gitRoot(string(input.root, 'root')!)
  const sessionId = string(input.sessionId, 'sessionId')!
  const task = await findBoundTask(root, sessionId)
  if (!task) throw new ProtocolError('not_found', 'no task is bound to this session')
  const file = stateFile(task)
  return withLock(taskLockFile(task.commonDir, task.taskId), 'task', async () => {
    let state = await readState(file)
    state.status = 'paused'; state.pauseReason = string(input.reason, 'reason', false) ?? 'paused by user'; state.attempt = undefined
    state = await saveState(file, state)
    return summary(state, false)
  })
}

export async function integrateTask(input: Record<string, unknown>): Promise<ReturnType<typeof summary>> {
  const root = await gitRoot(string(input.root, 'root')!)
  const sessionId = string(input.sessionId, 'sessionId')!
  const state = await findBoundTask(root, sessionId)
  if (!state) throw new ProtocolError('not_found', 'no task is bound to this session')
  const cwd = string(input.cwd, 'cwd', false)
  if (cwd && path.resolve(cwd) !== path.resolve(state.root)) throw new ProtocolError('blocked', `integration requires the original checkout: ${state.root}`)
  if (!state.attempt || state.attempt.stage !== 'integrate' || state.attempt.attemptId !== string(input.attemptId, 'attemptId') || state.attempt.token !== string(input.token, 'token')) throw new ProtocolError('conflict', 'stale integration handoff')
  const config = await loadConfig(root)
  const result = await integrateState(stateFile(state), config)
  return summary(result, false)
}

export async function cleanupTasks(input: Record<string, unknown>): Promise<{ entries: unknown[]; applied: boolean }> {
  const root = await gitRoot(string(input.root, 'root')!)
  const common = await gitCommonDir(root)
  const directory = path.join(common, 'task-workflow', 'tasks')
  const entries = []
  const { readdir } = await import('node:fs/promises')
  const apply = input.apply === true
  for (const id of await readdir(directory).catch(() => [] as string[])) {
    try {
      const state = await readState(path.join(directory, id, 'state.json'))
      if (state.status !== 'done') {
        entries.push({ taskId: id, name: state.name, status: state.status, reason: 'not done' })
        continue
      }
      const branch = await branchExists(state.root, state.taskBranch)
      const tree = await exists(state.worktree)
      if (!branch && !tree) continue
      if (!state.reviewedCommit || !await isAncestor(state.root, state.reviewedCommit, state.targetBranch)) {
        entries.push({ taskId: id, name: state.name, status: state.status, reason: 'reviewed commit is missing or not merged' })
        continue
      }
      if (branch && await git(state.root, 'rev-parse', state.taskBranch) !== state.reviewedCommit) {
        entries.push({ taskId: id, name: state.name, status: state.status, reason: 'task branch has new commits' })
        continue
      }
      if (tree) {
        let treeBranch: string
        try { treeBranch = await currentBranch(state.worktree) } catch {
          entries.push({ taskId: id, name: state.name, status: state.status, reason: 'worktree path is not a valid Git worktree' })
          continue
        }
        if (treeBranch !== state.taskBranch || await gitCommonDir(state.worktree) !== state.commonDir || await head(state.worktree) !== state.reviewedCommit || (await statusPorcelain(state.worktree)).trim()) {
          entries.push({ taskId: id, name: state.name, status: state.status, reason: 'worktree identity or cleanliness check failed' })
          continue
        }
      }
      if (!apply) {
        entries.push({ taskId: id, name: state.name, status: state.status, reason: 'safe to remove residual worktree/branch' })
        continue
      }
      const removed: string[] = []
      if (tree) { await removeWorktree(state.root, state.worktree); removed.push('worktree') }
      if (branch) { await git(state.root, 'branch', '-d', state.taskBranch); removed.push('branch') }
      entries.push({ taskId: id, name: state.name, status: state.status, reason: `removed ${removed.join(' and ')}` })
    } catch (error) { entries.push({ taskId: id, reason: String(error) }) }
  }
  return { entries, applied: apply }
}
