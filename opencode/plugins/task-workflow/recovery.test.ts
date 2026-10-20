import { test, expect } from 'bun:test'
import { execFileSync } from 'node:child_process'
import { mkdtemp, mkdir, readFile, writeFile, rm, realpath } from 'node:fs/promises'
import path from 'node:path'
import { createWorkflowPlugin } from './index'
import { ExecutionError, type SessionReader } from './execution'
import { fingerprint, initialReviewProgress, recordReviewProgress } from './progress'

const temporary = '/private/var/folders/d9/5sfcnz292bvbdh3nv19rvhc40000gn/T/opencode/'
const git = (root: string, ...args: string[]) => execFileSync('git', args, { cwd: root, encoding: 'utf8', stdio: 'pipe' }).trim()

async function fixture() {
  const root = await realpath(await mkdtemp(path.join(temporary, 'workflow-recovery-')))
  git(root, 'init', '-b', 'main'); git(root, 'config', 'user.name', 'Workflow Test'); git(root, 'config', 'user.email', 'test@example.invalid')
  await writeFile(path.join(root, 'feature.txt'), 'base')
  git(root, 'add', '.'); git(root, 'commit', '-m', 'initial')
  const tree = path.join(root, 'task-tree')
  git(root, 'worktree', 'add', '-b', 'task/demo', tree)
  const sessionID = `ses_recovery_${path.basename(root).replaceAll('-', '_')}`
  const folder = path.join(root, '.git/opencode-tasks', sessionID)
  await mkdir(folder, { recursive: true })
  await writeFile(path.join(folder, 'plan.md'), 'Implement MANUAL transaction support')
  await writeFile(path.join(folder, 'change-scope.json'), '{"files":["feature.txt"]}')
  const activeReceipt = { path: path.join(folder, 'implement-saved.json'), token: 'saved', stage: 'implement', review: true }
  const state: any = { sessionID, name: 'demo', requirement: 'implement feature', root, target: 'main', base: git(root, 'rev-parse', 'HEAD'),
    branch: 'task/demo', tree, folder, step: 2, status: 'running', worktreeCreated: true, activeReceipt,
    continuation: { step: 2, rounds: 4, reviews: 1, stalled: 0, corrections: 0, failures: 0, reviewPending: true, next: 'Implement MANUAL commit/rollback' },
    settings: { models: { astra: { providerID: 'test', id: 'analysis' }, luna: { providerID: 'test', id: 'implementation' } }, modelPolicy: 'pinned', prefix: 'demo', parent: root, planDirectory: 'docs/plans' },
  }
  const save = () => writeFile(path.join(folder, 'state.json'), JSON.stringify(state))
  const read = async () => JSON.parse(await readFile(path.join(folder, 'state.json'), 'utf8'))
  const events: any[] = []
  const messages: any[] = []
  const append = (type: string, data: any = {}) => events.push({ type, created: Date.now(), durable: { seq: events.length + 1, aggregateID: sessionID }, data: { sessionID, ...data } })
  const reader: SessionReader = {
    log: async function* ({ after = 0 }) {
      for (const item of events.filter(item => item.durable.seq > after)) yield item
      yield { type: 'log.synced', aggregateID: sessionID, seq: events.length }
    },
    active: async () => ({}), inbox: { list: async () => [] } as any,
    message: { get: async ({ messageID }: any) => {
      const message = messages.find(item => item.id === messageID)
      if (!message) throw Object.assign(new Error('Message not found'), { _tag: 'MessageNotFoundError' })
      return message
    } } as any,
    messages: { list: async () => ({ data: [...messages].reverse(), cursor: {} }) } as any,
  }
  const commands = new Map<string, any>(), hooks = new Map<string, any>()
  let calls = 0, notes: any[] = [], prompts: any[] = [], resolveFinished!: () => void, resolvePrompt!: () => void
  let finished = new Promise<void>(resolve => { resolveFinished = resolve })
  let prompted = new Promise<void>(resolve => { resolvePrompt = resolve })
  let execute = async (_input: any) => { append('session.execution.interrupted', { reason: 'user' }) }
  const ctx: any = {
    location: { directory: root },
    rpc: { register: async () => ({ events: { emit: async () => {} } }) },
    command: { transform: async (callback: any) => callback({ add: (command: any) => commands.set(command.name, command) }) },
    session: {
      get: async () => ({ location: { directory: tree }, outcome: 'interrupted' }),
      switchAgent: async () => {}, switchModel: async () => {}, wait: async () => {},
      hook: async (name: string, callback: any) => { hooks.set(name, callback) },
      synthetic: async (input: any) => { expect(input.resume).toBe(false); notes.push(input); if (input.text.includes('工作流暂停')) resolveFinished() },
      prompt: async (input: any) => {
        calls++
        prompts.push(input)
        messages.push({ id: input.id, type: 'user', time: { created: Date.now() }, text: input.text })
        append('session.inbox.enqueued', { inboxID: input.id, item: { type: 'user', payload: { text: input.text } } })
        append('session.inbox.delivered', { inboxID: input.id }); append('session.execution.started')
        resolvePrompt()
        await execute(input)
        return { id: input.id }
      },
    },
    tool: { hook: async (_name: string, callback: any) => { hooks.set('tool', callback) } },
  }
  await save()
  return { root, tree, folder, state, activeReceipt, sessionID, reader, ctx, hooks, append, save, read, commands,
    calls: () => calls, prompts: () => prompts, messages: () => messages, notes: () => notes, finished: () => finished, prompted: () => prompted,
    setExecute: (callback: typeof execute) => { execute = callback },
    reset: () => { notes = []; finished = new Promise<void>(resolve => { resolveFinished = resolve }); prompted = new Promise<void>(resolve => { resolvePrompt = resolve }) },
    complete: async (result: Record<string, any>) => {
      const { activeReceipt: round } = await read()
      await writeFile(round.path, JSON.stringify({ token: round.token, stage: round.stage, ...result }))
      append('session.execution.succeeded')
    },
    receipt: async () => writeFile(activeReceipt.path, JSON.stringify({ token: activeReceipt.token, stage: 'implement', status: 'progress', remainingRequired: ['MANUAL transaction missing'], next: 'Implement MANUAL commit/rollback in feature.txt and run the focused test', completedItems: ['reviewed actual code'], checks: ['diff inspected'] })),
    dispose: async () => { git(root, 'worktree', 'remove', '--force', tree); await rm(root, { recursive: true, force: true }) },
  }
}

test('legacy resume consumes its saved review and executes the concrete repair with retained counters', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    await f.receipt()
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    expect(f.calls()).toBe(0)
    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.finished()
    expect(f.calls()).toBe(1)
    const s = await f.read()
    expect(s.continuation.rounds).toBe(5)
    expect(s.continuation.reviews).toBe(2)
    expect(s.activeReceipt.review).toBe(false)
    expect(s.activeReceipt.text).not.toContain('本轮是 Luna 收尾审查')
    expect(s.activeReceipt.text).toContain('Implement MANUAL commit/rollback in feature.txt')
    expect(s.checkpoint.receipt).toBe(f.activeReceipt.path)
    const before = f.calls()
    await f.commands.get('task-status').execute({ sessionID: f.sessionID })
    expect(f.calls()).toBe(before)
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('a legacy task with new implementation admits its fourth review without resetting history', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.status = 'blocked'
    f.state.error = 'Error: 三次收尾审查后仍无法完成，详见 checkpoint.json 中的必需缺口。'
    f.state.continuation = { ...f.state.continuation, rounds: 24, reviews: 3, reviewPending: true, sinceReview: 5 }
    f.state.checkpoint = { stage: 'implement', round: 24, review: false, codeChanged: true,
      checks: ['PASS focused monitoring test'], next: 'Review the completed monitoring implementation' }
    delete f.state.activeReceipt
    await writeFile(path.join(f.tree, 'feature.txt'), 'monitoring implemented')
    await f.save()
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.finished()

    const s = await f.read()
    expect(f.calls()).toBe(1)
    expect(s.activeReceipt.review).toBe(true)
    expect(s.activeReceipt.text).toContain('completion-review-4.md')
    expect(s.continuation.reviews).toBe(3)
    expect(s.continuation.rounds).toBe(24)
    expect(s.executor.manualResumeAttempts).toBe(1)
    expect(s.pause.kind).toBe('user')
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('identical reviews stop on three unchanged results and explicit reassessment permits only one more', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.status = 'blocked'
    f.state.continuation.reviews = 0
    delete f.state.activeReceipt
    await f.save()
    f.setExecute(async () => {
      const { activeReceipt: round } = await f.read()
      if (f.calls() > 10) throw new Error('Unbounded review loop')
      await writeFile(round.path, JSON.stringify({ token: round.token, stage: round.stage, status: 'completed' }))
      f.append('session.execution.succeeded')
    })
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.finished()
    await cleanup(); cleanup = undefined
    const stopped = await f.read()
    expect(f.calls()).toBe(4)
    expect(stopped.pause.kind).toBe('no-progress')
    expect(stopped.continuation.reviewProgress.unchanged).toBe(3)
    expect(stopped.continuation.reviews).toBe(4)
    expect(stopped.activeReceipt).toBeUndefined()

    f.reset()
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    expect(f.calls()).toBe(4)
    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.finished()
    await cleanup(); cleanup = undefined
    const reassessed = await f.read()
    expect(f.calls()).toBe(5)
    expect(f.prompts().at(-1).text).toContain('重新评估')
    expect(reassessed.pause.kind).toBe('no-progress')
    expect(reassessed.continuation.reviews).toBe(5)
    expect(reassessed.continuation.reviewProgress.unchanged).toBe(4)
    expect(reassessed.continuation.reassessment).toBeUndefined()
  } finally { await cleanup?.(); await f.dispose() }
}, 15000)

test('required external evidence pauses with a specific reason instead of looping implementation', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.status = 'blocked'
    delete f.state.activeReceipt
    await f.save()
    f.setExecute(async () => {
      const { activeReceipt: round } = await f.read()
      await writeFile(round.path, JSON.stringify({ token: round.token, stage: round.stage, status: 'progress',
        blocker: { kind: 'external', required: true, condition: 'Provide a reachable ClickHouse fixture or passing forced-live CI result' },
        remainingRequired: ['Required live verification'], next: 'Run the required live target when the fixture is available' }))
      f.append('session.execution.succeeded')
    })
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.finished()
    const stopped = await f.read()
    expect(f.calls()).toBe(1)
    expect(stopped.pause.kind).toBe('external')
    expect(stopped.pause.message).toContain('ClickHouse fixture')
    expect(stopped.executor.autoResume).toBe(false)
    expect(stopped.activeReceipt).toBeUndefined()
    expect(f.notes().at(-1).text).toContain('补齐')
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('validation-only progress after three unchanged reviews permits another review and a concrete repair', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    const code = await fingerprint(f.tree)
    let review = recordReviewProgress(initialReviewProgress(), code, ['PASS cargo check'], true)
    for (let n = 0; n < 3; n++) review = recordReviewProgress(review, code, ['PASS cargo check'], true)
    review = recordReviewProgress(review, code, ['PASS required live monitoring target'], false)
    f.state.status = 'recovering'
    f.state.executor = { version: 1, cursor: 0, authorizedThrough: 0, autoResume: true }
    f.state.continuation = { ...f.state.continuation, rounds: 24, reviews: 4, reviewPending: true, reviewProgress: review }
    delete f.state.activeReceipt
    await f.save()
    f.setExecute(async () => {
      if (f.calls() === 1) await f.complete({ status: 'progress', remainingRequired: ['One independent repair'],
        next: 'Implement the repair in feature.txt', checks: ['PASS required live monitoring target'] })
      else f.append('session.execution.interrupted', { reason: 'user' })
    })
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.finished()
    const s = await f.read()
    expect(f.calls()).toBe(2)
    expect(s.continuation.reviewProgress.unchanged).toBe(0)
    expect(s.continuation.reviews).toBe(5)
    expect(s.continuation.rounds).toBe(25)
    expect(s.activeReceipt.review).toBe(false)
    expect(s.activeReceipt.text).toContain('Implement the repair in feature.txt')
    expect(s.pause.kind).toBe('user')
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('reload consumes a saved reassessment receipt without granting another unchanged review', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    const code = await fingerprint(f.tree)
    f.state.status = 'blocked'
    f.state.pause = { kind: 'no-progress', message: 'Repeated review without new evidence' }
    f.state.continuation = { ...f.state.continuation, reviews: 4, rounds: 24, reviewPending: true,
      reviewProgress: { ...initialReviewProgress({ review: true, fingerprint: code }), unchanged: 3 } }
    f.state.checkpoint = { stage: 'implement', round: 24, review: true, fingerprint: code, checks: [] }
    delete f.state.activeReceipt
    await f.save()
    f.setExecute(async () => {})
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.prompted()
    await cleanup(); cleanup = undefined
    const interrupted = await f.read()
    const round = interrupted.activeReceipt
    expect(interrupted.continuation.reassessment.token).toBe(round.token)
    expect(round.reviewReason).toBe('reassessment')
    expect(interrupted.continuation.reviewProgress.unchanged).toBe(3)

    await f.complete({ status: 'progress', remainingRequired: ['Same missing functionality'], next: 'Repair feature.txt' })
    f.reset()
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.finished()
    await cleanup(); cleanup = undefined
    const stopped = await f.read()
    expect(f.calls()).toBe(1)
    expect(stopped.pause.kind).toBe('no-progress')
    expect(stopped.continuation.reviews).toBe(5)
    expect(stopped.continuation.rounds).toBe(25)
    expect(stopped.continuation.reviewProgress.unchanged).toBe(4)
    expect(stopped.continuation.reassessment).toBeUndefined()
    expect(stopped.activeReceipt).toBeUndefined()
    expect(stopped.checkpoint.receipt).toBe(round.path)
    f.reset()
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    expect(f.calls()).toBe(1)
    expect((await f.read()).status).toBe('blocked')
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('external reassessment without fresh evidence pauses after one review even with a legacy baseline', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.status = 'blocked'
    f.state.pause = { kind: 'external', message: 'Required ClickHouse URL unavailable' }
    f.state.continuation.reviews = 3
    f.state.checkpoint = { stage: 'implement', round: 4, review: false,
      fingerprint: await fingerprint(f.tree), checks: ['PASS cargo check'] }
    delete f.state.activeReceipt
    await f.save()
    f.setExecute(async () => { await f.complete({ status: 'progress',
      remainingRequired: ['Required live target'], next: 'Wait for the configured endpoint', checks: ['PASS cargo check'] }) })
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.finished()
    const s = await f.read()
    expect(f.calls()).toBe(1)
    expect(s.pause.kind).toBe('external')
    expect(s.pause.message).toContain('Required ClickHouse URL unavailable')
    expect(s.continuation.rounds).toBe(5)
    expect(s.continuation.reviews).toBe(4)
    expect(s.continuation.reassessment).toBeUndefined()
    expect(s.executor.autoResume).toBe(false)
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('optional unavailable checks allow a valid completion review to reach integration', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.status = 'blocked'
    f.state.continuation.reviews = 3
    delete f.state.activeReceipt
    await writeFile(path.join(f.folder, 'implementation.md'), 'Feature implemented with automated evidence')
    await f.save()
    f.setExecute(async () => {
      if (f.calls() === 1) await f.complete({ status: 'completed', reviewed: true,
        requirements: [{ requirement: 'implement feature', status: 'passed', evidence: 'feature.txt and automated feature test' }],
        remainingRequired: [], deferredChecks: [{ check: 'Optional TUI smoke', required: false, reason: 'PTY unavailable; reducer and render tests passed' }] })
      else f.append('session.execution.interrupted', { reason: 'user' })
    })
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.finished()
    const s = await f.read()
    expect(f.calls()).toBe(2)
    expect(s.step).toBe(3)
    expect(s.activeReceipt.stage).toBe('integrate')
    const decision = JSON.parse(await readFile(path.join(f.folder, 'completion-decision.json'), 'utf8'))
    expect(decision.deferredChecks[0].required).toBe(false)
    expect(decision.requirements[0].status).toBe('passed')
    expect(s.pause.kind).toBe('user')
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('manual resume re-admits a legacy quota-failed round from its persisted session message', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.status = 'blocked'
    f.state.activeReceipt.review = false
    f.state.activeReceipt.promptID = 'msg_legacy_quota'
    f.state.activeReceipt.phase = 'delivered'
    f.state.activeReceipt.terminal = {
      outcome: 'failed', seq: 3, time: Date.now() - 1_000,
      error: { type: 'provider.quota', status: 429, message: 'usage limit reached' },
    }
    delete f.state.activeReceipt.text
    f.state.executor = { version: 1, cursor: 3, authorizedThrough: 0, autoResume: false }
    for (let i = 0; i < 3; i++) f.append('session.synthetic')
    f.messages().push({ id: 'msg_legacy_quota', type: 'user', time: { created: Date.now() - 2_000 }, text: 'Original full implementation prompt with legacy instructions' })
    await f.save()
    f.setExecute(async () => { f.append('session.execution.interrupted', { reason: 'user' }) })
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)

    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.finished()

    const s = await f.read()
    expect(f.calls()).toBe(1)
    expect(f.prompts()[0].text).toBe('Original full implementation prompt with legacy instructions')
    expect(f.prompts()[0].id).not.toBe('msg_legacy_quota')
    expect(s.activeReceipt.text).toBe(f.prompts()[0].text)
    expect(s.executor.manualResumeAttempts).toBe(1)
    expect(s.executor.recoveryFailures ?? 0).toBe(0)
    expect(s.status).toBe('blocked')
    expect(f.notes().some((note: any) => note.text.includes('恢复请求已提交给会话队列'))).toBe(true)
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('manual resume reports missing original prompt and does not resubmit a guessed request', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.status = 'blocked'
    f.state.activeReceipt.review = false
    f.state.activeReceipt.promptID = 'msg_missing_legacy'
    f.state.activeReceipt.terminal = {
      outcome: 'failed', seq: 3, time: Date.now() - 1_000,
      error: { type: 'provider.quota', status: 429, message: 'usage limit reached' },
    }
    delete f.state.activeReceipt.text
    f.state.executor = { version: 1, cursor: 3, authorizedThrough: 0, autoResume: false }
    await f.save()
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)

    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.finished()

    const s = await f.read()
    expect(f.calls()).toBe(0)
    expect(s.error).toContain('找不到原始任务请求')
    expect(s.error).not.toContain('模型额度耗尽')
    expect(s.executor.manualResumeAttempts).toBe(1)
    expect(s.executor.recoveryFailures ?? 0).toBe(0)
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('setup recovery repairs checkpoint from committed state without replaying a consumed receipt', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.executor = { version: 1, cursor: 0, authorizedThrough: 0, autoResume: true }
    delete f.state.activeReceipt
    f.state.continuation = { ...f.state.continuation, rounds: 5, reviews: 2, reviewPending: false, advice: 'Repair MANUAL transaction missing' }
    f.state.checkpoint = { stage: 'implement', round: 5, next: 'Repair MANUAL transaction missing', receipt: f.activeReceipt.path }
    await f.save()
    await writeFile(path.join(f.folder, 'checkpoint.json'), '{"round":1,"next":"stale"}')
    await f.receipt()
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.finished()
    const s = await f.read(), checkpoint = JSON.parse(await readFile(path.join(f.folder, 'checkpoint.json'), 'utf8'))
    expect(f.calls()).toBe(1)
    expect(s.continuation.rounds).toBe(5)
    expect(s.continuation.reviews).toBe(2)
    expect(checkpoint.round).toBe(5)
    expect(s.activeReceipt.review).toBe(false)
    expect(s.executor.autoResume).toBe(false)
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('unload cancels the controller and the next instance adopts the written receipt', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.executor = { version: 1, cursor: 0, authorizedThrough: 0, autoResume: true }
    delete f.state.activeReceipt
    f.state.continuation.reviewPending = false
    f.state.continuation.reviews = 0
    await f.save()
    f.setExecute(async () => {})
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.prompted()
    await cleanup()
    const interrupted = await f.read(), round = interrupted.activeReceipt
    expect(interrupted.status).toBe('running')
    expect(interrupted.executor.autoResume).toBe(true)
    await writeFile(round.path, JSON.stringify({ token: round.token, stage: round.stage, status: 'progress', completedItems: ['one implemented unit'], next: 'Implement next unit in feature.txt', checks: ['focused test passed'] }))
    f.append('session.execution.succeeded')
    f.reset(); f.setExecute(async () => { f.append('session.execution.interrupted', { reason: 'user' }) })
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.finished()
    const resumed = await f.read()
    expect(f.calls()).toBe(2)
    expect(resumed.continuation.rounds).toBe(5)
    expect(resumed.checkpoint.receipt).toBe(round.path)
    expect(f.notes()).toHaveLength(1)
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('a persisted user stop prevents startup recovery from issuing any prompt', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.executor = { version: 1, cursor: 0, authorizedThrough: 0, autoResume: true }
    await f.save(); await f.receipt()
    f.append('session.execution.interrupted', { reason: 'user' })
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.finished()
    expect(f.calls()).toBe(0)
    expect((await f.read()).executor.autoResume).toBe(false)
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('explicit resume acknowledges a persisted live stop but not a later stop', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.executor = { version: 1, cursor: 0, authorizedThrough: 0, userStop: 4, userStopAt: Date.now() - 100, autoResume: false }
    f.state.status = 'blocked'
    f.state.continuation.reviewPending = false
    f.state.continuation.reviews = 0
    delete f.state.activeReceipt
    await f.save()
    for (let i = 0; i < 4; i++) f.append('session.synthetic')
    f.setExecute(async () => { f.append('session.execution.interrupted', { reason: 'user' }) })
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.finished()
    const s = await f.read()
    expect(f.calls()).toBe(1)
    expect(s.executor.authorizedThrough).toBe(4)
    expect(s.executor.userStop).toBe(8)
    expect(s.executor.autoResume).toBe(false)
    expect(s.status).toBe('blocked')
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('explicit resume acknowledges a user stop discovered by replay before its command cutoff', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.executor = { version: 1, cursor: 0, authorizedThrough: 0, autoResume: false }
    f.state.status = 'blocked'
    f.state.continuation.reviewPending = false
    f.state.continuation.reviews = 0
    delete f.state.activeReceipt
    await f.save()
    f.append('session.execution.interrupted', { reason: 'user' })
    const priorStop = f.state.executor.userStop
    // The event exists in the durable history but has not yet been synced to state.
    expect(priorStop).toBeUndefined()
    f.setExecute(async () => { f.append('session.execution.interrupted', { reason: 'user' }) })
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.finished()
    const s = await f.read()
    expect(f.calls()).toBe(1)
    expect(s.executor.userStop).toBeGreaterThan(1)
    expect(s.executor.authorizedThrough).toBeLessThan(s.executor.userStop)
    expect(s.executor.autoResume).toBe(false)
    expect(s.status).toBe('blocked')
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('two location instances keep one controller and share the current context identity', async () => {
  const f = await fixture()
  let first: any, second: any
  try {
    f.state.executor = { version: 1, cursor: 0, authorizedThrough: 0, autoResume: true }
    delete f.state.activeReceipt
    f.state.continuation.reviewPending = false
    f.state.continuation.reviews = 0
    await f.save()
    f.setExecute(async () => {})
    first = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.prompted()
    let readerCalls = 0
    second = await createWorkflowPlugin(async () => { readerCalls++; return f.reader }).setup(f.ctx)
    await f.commands.get('task-status').execute({ sessionID: f.sessionID })
    expect(f.calls()).toBe(1)
    expect(readerCalls).toBe(0)
    await expect(f.commands.get('task-resume').execute({ sessionID: f.sessionID })).rejects.toThrow('任务仍在执行')
    const event = { sessionID: f.sessionID, system: [] as any[] }
    f.hooks.get('context')(event)
    const s = await f.read()
    expect(event.system[0].text).toContain(s.activeReceipt.token)
    await second(); second = undefined
    expect((await f.read()).executor.autoResume).toBe(true)
  } finally { await second?.(); await first?.(); await f.dispose() }
}, 10000)

test('an explicit resume preserves an exhausted phase budget', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.status = 'blocked'
    f.state.continuation.rounds = 40
    f.state.continuation.reviews = 3
    f.state.continuation.reviewPending = false
    delete f.state.activeReceipt
    await f.save()
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await f.finished()
    const s = await f.read()
    expect(f.calls()).toBe(0)
    expect(s.continuation.rounds).toBe(40)
    expect(s.continuation.reviews).toBe(3)
    expect(s.status).toBe('blocked')
    expect(s.pause.kind).toBe('budget')
    expect(f.notes().at(-1).text).toContain('/task-resume 不会增加预算')
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('a live-only user stop is persisted before unload and remains stopped after reload', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    f.state.executor = { version: 1, cursor: 0, authorizedThrough: 0, authorizedAt: Date.now() - 100, autoResume: true }
    delete f.state.activeReceipt
    f.state.continuation.reviewPending = false
    await f.save()
    f.setExecute(async () => {})
    let saved!: () => void
    const stopped = new Promise<void>(resolve => { saved = resolve })
    f.ctx.event = { subscribe: async function* ({ signal }: any) {
      await f.prompted()
      yield { type: 'session.execution.interrupted', created: Date.now(),
        durable: { aggregateID: f.sessionID, seq: 4, version: 1 }, data: { sessionID: f.sessionID, reason: 'user' } }
      saved()
      if (!signal.aborted) await new Promise<void>(resolve => signal.addEventListener('abort', () => resolve(), { once: true }))
    } }
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await stopped
    expect((await f.read()).executor.userStop).toBe(4)
    await cleanup(); cleanup = undefined
    delete f.ctx.event
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.finished()
    expect(f.calls()).toBe(1)
    expect((await f.read()).executor.autoResume).toBe(false)
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)

test('recovery enrollment survives a service failure on the first explicit resume', async () => {
  const f = await fixture()
  let cleanup: any
  try {
    await f.receipt()
    let saved!: () => void
    const recovering = new Promise<void>(resolve => { saved = resolve })
    f.ctx.rpc.register = async () => ({ events: { emit: async () => { if ((await f.read()).status === 'recovering') saved() } } })
    cleanup = await createWorkflowPlugin(async () => { throw new ExecutionError('transport', 'Service unavailable') }).setup(f.ctx)
    await f.commands.get('task-resume').execute({ sessionID: f.sessionID })
    await recovering
    await cleanup(); cleanup = undefined
    const s = await f.read()
    expect(s.status).toBe('recovering')
    expect(s.executor.autoResume).toBe(true)
    expect(s.executor.version).toBe(1)
    cleanup = await createWorkflowPlugin(async () => f.reader).setup(f.ctx)
    await f.finished()
    expect(f.calls()).toBe(1)
    expect((await f.read()).continuation.rounds).toBe(5)
  } finally { await cleanup?.(); await f.dispose() }
}, 10000)
