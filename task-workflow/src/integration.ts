import { mkdir, readFile } from 'node:fs/promises'
import path from 'node:path'
import { ProtocolError } from './protocol.js'
import { exists, readState, saveState, writeJsonAtomic } from './storage.js'
import { withLock, integrationLockFile, taskLockFile } from './locks.js'
import { ensurePlanInWorktree } from './artifacts.js'
import { assertNoPlannedOverlap, overlaps, parseScope } from './workspace.js'
import { branchExists, committedPaths, createWorktree, currentBranch, dirtyPaths, ensureIgnored, git, gitCommonDir, head, isAncestor, removeWorktree, statusPorcelain } from './git.js'
import { runCheck, requiredChecksPassed } from './validation.js'
import { taskDir, type TaskState } from './state.js'
import type { WorkflowConfig } from './config.js'

export async function ensureWorktree(state: TaskState): Promise<TaskState> {
  if (await exists(state.worktree)) {
    let branch: string
    try { branch = await currentBranch(state.worktree) } catch (error) {
      throw new ProtocolError('blocked', 'recorded worktree path exists but is not a valid Git worktree; refusing to take it over', String(error))
    }
    if (branch !== state.taskBranch) throw new ProtocolError('blocked', 'recorded worktree is on a different branch')
    if (await gitCommonDir(state.worktree) !== state.commonDir) throw new ProtocolError('blocked', 'recorded worktree belongs to a different repository')
    const planSource = path.join(taskDir(state), state.artifacts.plan)
    if (await exists(planSource)) await ensurePlanInWorktree(planSource, state.worktree, state.planRelative)
    return state
  }
  if (!state.taskBranch || !state.worktree) throw new ProtocolError('invalid_state', 'task worktree is not configured')
  const relativeWorktree = path.relative(state.root, state.worktree)
  if (!relativeWorktree.startsWith('..') && !path.isAbsolute(relativeWorktree)) await ensureIgnored(state.root, state.commonDir, relativeWorktree)
  await mkdir(path.dirname(state.worktree), { recursive: true })
  await createWorktree(state.root, state.taskBranch, state.worktree, state.base)
  const planSource = path.join(taskDir(state), state.artifacts.plan)
  if (await exists(planSource)) await ensurePlanInWorktree(planSource, state.worktree, state.planRelative)
  return state
}

async function writeIntegrationReport(state: TaskState, text: string): Promise<void> {
  await writeJsonAtomic(path.join(taskDir(state), 'integration-progress.json'), {
    taskId: state.taskId, step: state.integrationStep, text, targetBefore: state.targetBefore, targetAfter: state.targetAfter,
  })
}

async function commitTask(state: TaskState): Promise<TaskState> {
  if (!state.authorization.commit) throw new ProtocolError('blocked', 'task commit authorization is not recorded')
  const scopeText = await readFile(path.join(taskDir(state), state.artifacts.changeScope), 'utf8').catch(() => '')
  const planned = [...(scopeText ? parseScope(scopeText) : []), state.planRelative]
  const changedFiles = await dirtyPaths(state.worktree)
  const committed = (await head(state.worktree)) !== state.base ? await committedPaths(state.worktree, state.base) : []
  const committedUnexpected = committed.filter(file => !overlaps(planned, [file]).length)
  if (committedUnexpected.length) throw new ProtocolError('blocked', `task commits exceed declared scope: ${committedUnexpected.join(', ')}`, { planned, committed })
  if (!changedFiles.length) {
    if (committed.length) {
      state.reviewedCommit = state.reviewedCommit ?? await head(state.worktree)
      state.integrationStep = 'merge'
      return state
    }
    throw new ProtocolError('blocked', 'task worktree has no changes to commit')
  }
  if (overlaps(planned, changedFiles).length !== changedFiles.length) {
    const unexpected = changedFiles.filter(file => !overlaps(planned, [file]).length)
    throw new ProtocolError('blocked', `task worktree changes exceed declared scope: ${unexpected.join(', ')}`, { planned, changedFiles })
  }
  await git(state.worktree, 'add', '--all', '--', ...planned)
  const staged = await git(state.worktree, 'diff', '--cached', '--name-only')
  if (!staged.trim()) throw new ProtocolError('blocked', 'task worktree has no staged files')
  await git(state.worktree, 'commit', '-m', `feat(task): ${state.name}`)
  state.reviewedCommit = await head(state.worktree)
  state.integrationStep = 'merge'
  return state
}

async function mergeTask(state: TaskState): Promise<TaskState> {
  if (!state.authorization.merge) throw new ProtocolError('blocked', 'task merge authorization is not recorded')
  if (await currentBranch(state.root) !== state.targetBranch) throw new ProtocolError('blocked', `target branch changed; expected ${state.targetBranch}`)
  state.targetBefore = await head(state.root)
  if (!state.reviewedCommit) state.reviewedCommit = await head(state.worktree)
  if (!await isAncestor(state.root, state.reviewedCommit, state.targetBranch)) {
    // The task tip is allowed to be merged; this check only rejects a target that
    // moved in a way that makes the original task base no longer meaningful.
    if (state.targetBefore !== state.base && !await isAncestor(state.root, state.base, state.targetBefore)) {
      throw new ProtocolError('blocked', 'target branch changed outside the task base; review before merging')
    }
  }
  await git(state.root, 'merge', '--no-edit', state.taskBranch)
  state.targetAfter = await head(state.root)
  state.mergeCommit = state.targetAfter
  state.integrationStep = 'verify_target'
  return state
}

async function verifyTarget(state: TaskState, config: WorkflowConfig): Promise<TaskState> {
  const records = []
  for (const definition of config.validations ?? []) {
    records.push(await runCheck(state, definition, taskDir(state), state.root))
  }
  state.validations = [...state.validations, ...records]
  if (records.length && !requiredChecksPassed(records)) {
    throw new ProtocolError('blocked', 'required target validation failed', records)
  }
  state.integrationStep = 'cleanup'
  return state
}

async function cleanupTask(state: TaskState): Promise<TaskState> {
  if (!state.authorization.cleanup) throw new ProtocolError('blocked', 'task cleanup authorization is not recorded')
  if (await exists(state.worktree)) {
    if (await currentBranch(state.worktree) !== state.taskBranch) throw new ProtocolError('blocked', 'worktree branch changed before cleanup')
    if ((await statusPorcelain(state.worktree)).trim()) throw new ProtocolError('blocked', 'worktree has uncommitted changes')
    await removeWorktree(state.root, state.worktree)
  }
  if (await branchExists(state.root, state.taskBranch)) {
    if (!state.reviewedCommit || !await isAncestor(state.root, state.reviewedCommit, state.targetBranch)) throw new ProtocolError('blocked', 'task commit is not merged; keeping branch')
    if (await head(state.root) !== state.targetAfter && state.targetAfter) throw new ProtocolError('blocked', 'target branch changed after integration; keeping branch')
    await git(state.root, 'branch', '-d', state.taskBranch)
  }
  state.status = 'done'
  state.stage = 'cleanup'
  state.integrationStep = undefined
  return state
}

export async function integrateState(stateFile: string, config: WorkflowConfig): Promise<TaskState> {
  const state = await readState(stateFile)
  return withLock(taskLockFile(state.commonDir, state.taskId), 'task', async () =>
    withLock(integrationLockFile(state.commonDir, state.root), 'integration', async () => {
      let current = await readState(stateFile)
      if (current.stage !== 'integrate') throw new ProtocolError('invalid_state', `task is not ready to integrate: ${current.stage}`)
      if (!current.integrationStep) current.integrationStep = 'verify'
      current.attempt = undefined
      current.status = 'running'
      current = await saveState(stateFile, current)
      try {
      while (current.integrationStep) {
        if (current.integrationStep === 'verify') {
          if (await currentBranch(current.root) !== current.targetBranch) throw new ProtocolError('blocked', 'target branch changed before integration')
          current = await ensureWorktree(current)
          const planned = await readFile(path.join(taskDir(current), current.artifacts.changeScope), 'utf8').then(text => parseScope(text)).catch(() => [])
          await assertNoPlannedOverlap(current.root, planned)
          current.integrationStep = 'commit'
        } else if (current.integrationStep === 'commit') current = await commitTask(current)
        else if (current.integrationStep === 'merge') current = await mergeTask(current)
        else if (current.integrationStep === 'verify_target') current = await verifyTarget(current, config)
        else if (current.integrationStep === 'cleanup') current = await cleanupTask(current)
        current = await saveState(stateFile, current)
        await writeIntegrationReport(current, `completed ${current.integrationStep ?? 'done'}`)
        if (current.status === 'done') break
      }
      return current
      } catch (error) {
        const latest = await readState(stateFile)
        latest.status = error instanceof ProtocolError && error.code === 'blocked' ? 'blocked' : 'recoverable'
        latest.lastError = error instanceof Error ? error.message : String(error)
        await saveState(stateFile, latest)
        throw error
      }
    }),
  )
}
