import { test, expect } from 'bun:test'
import { mkdtemp, writeFile, rm } from 'node:fs/promises'
import path from 'node:path'
import { runRound, syncEvents, syncMessages, applyEvent, assertNotStopped, type ExecutionState, type SessionReader } from './execution'

const temporary = '/private/var/folders/d9/5sfcnz292bvbdh3nv19rvhc40000gn/T/opencode/'

async function fixture() {
  const folder = await mkdtemp(path.join(temporary, 'workflow-execution-'))
  const state: ExecutionState = {
    sessionID: 'ses_execution',
    executor: { version: 1, cursor: 0, authorizedThrough: 0, autoResume: true },
    activeReceipt: { path: path.join(folder, 'implement-token.json'), token: 'token', stage: 'implement', review: false,
      promptID: 'msg_current', text: 'Implement one unit', before: 'before', phase: 'prepared' },
  }
  const events: any[] = []
  let active = false, pending: any[] = [], calls = 0, pauses = 0, saves = 0
  const event = (type: string, data: any = {}) => {
    events.push({ type, created: events.length, durable: { seq: events.length + 1, aggregateID: state.sessionID }, data: { sessionID: state.sessionID, ...data } })
  }
  const reader: SessionReader = {
    log: async function* ({ after = 0 }: any) {
      for (const item of events.filter(event => event.durable.seq > after)) yield item
      yield { type: 'log.synced', aggregateID: state.sessionID, seq: events.length }
    },
    active: async () => active ? { [state.sessionID]: { type: 'running' } } : {},
    inbox: { list: async () => pending },
    message: { get: async () => {
      throw Object.assign(new Error('Message not found'), { _tag: 'MessageNotFoundError' })
    } } as any,
  }
  const receipt = async (status = 'progress') => writeFile(state.activeReceipt!.path, JSON.stringify({ token: 'token', stage: 'implement', status, next: 'Implement next unit', completedItems: ['one unit'] }))
  const deliver = () => {
    pending = []
    event('session.inbox.delivered', { inboxID: state.activeReceipt!.promptID })
    event('session.execution.started')
    active = true
  }
  const finish = (outcome = 'succeeded', data: any = {}) => {
    active = false
    event(`session.execution.${outcome}`, data)
  }
  let admit = async () => { deliver(); await receipt(); finish() }
  let pause = async () => {}
  const run = (explicitResume = false) => runRound({ state, reader, signal: new AbortController().signal, explicitResume,
    save: async () => { saves++ }, pause: async () => { pauses++; await pause() },
    prompt: async input => { calls++; expect(input.id).toBe(state.activeReceipt!.promptID); await admit() },
  })
  return { folder, state, reader, event, receipt, deliver, finish, run, calls: () => calls, saves: () => saves,
    setAdmit: (value: typeof admit) => { admit = value }, setPause: (value: typeof pause) => { pause = value },
    enqueue: () => { pending = [{ id: state.activeReceipt!.promptID }]; event('session.inbox.enqueued', { inboxID: state.activeReceipt!.promptID }) },
    pauses: () => pauses, dispose: () => rm(folder, { recursive: true, force: true }) }
}

test('a stale interrupted outcome cannot finish a prompt still waiting in the durable inbox', async () => {
  const f = await fixture()
  try {
    f.event('session.execution.interrupted', { reason: 'inactivity' })
    await syncEvents(f.state, f.reader, new AbortController().signal)
    f.state.executor.authorizedThrough = f.state.executor.cursor
    f.setAdmit(async () => { f.enqueue() })
    f.setPause(async () => {
      expect(f.calls()).toBe(1)
      if (f.pauses() === 3) { f.deliver(); await f.receipt(); f.finish() }
    })
    expect((await f.run()).result?.status).toBe('progress')
    expect(f.calls()).toBe(1)
    expect(f.pauses()).toBe(3)
  } finally { await f.dispose() }
})

test('an admitted prompt with a lost HTTP response is adopted without resubmission', async () => {
  const f = await fixture()
  try {
    f.setAdmit(async () => { f.enqueue(); throw new Error('Timed out waiting for response headers') })
    f.setPause(async () => { f.deliver(); await f.receipt(); f.finish() })
    expect((await f.run()).result?.status).toBe('progress')
    expect(f.calls()).toBe(1)
  } finally { await f.dispose() }
})

test('recovery consumes a valid existing receipt without sending another prompt', async () => {
  const f = await fixture()
  try {
    await f.receipt()
    expect((await f.run()).result?.status).toBe('progress')
    expect(f.calls()).toBe(0)
  } finally { await f.dispose() }
})

test('recovery joins an already delivered execution and waits for its completion', async () => {
  const f = await fixture()
  try {
    f.deliver()
    f.setPause(async () => { await f.receipt(); f.finish() })
    expect((await f.run()).result?.status).toBe('progress')
    expect(f.calls()).toBe(0)
  } finally { await f.dispose() }
})

test('an explicit user interruption prevents automatic continuation even with a written receipt', async () => {
  const f = await fixture()
  try {
    f.deliver(); await f.receipt(); f.finish('interrupted', { reason: 'user' })
    await expect(f.run()).rejects.toMatchObject({ kind: 'user' })
    expect(f.calls()).toBe(0)
  } finally { await f.dispose() }
})

test('a lifecycle interruption without a receipt retries the same unit with a new admitted identity', async () => {
  const f = await fixture()
  try {
    f.deliver(); f.finish('interrupted', { reason: 'shutdown' })
    expect((await f.run()).result?.status).toBe('progress')
    expect(f.state.activeReceipt!.promptID).not.toBe('msg_current')
    expect(f.state.activeReceipt!.token).toBe('token')
    expect(f.calls()).toBe(1)
  } finally { await f.dispose() }
})

test('quota exhaustion is not retried as a transient request failure', async () => {
  const f = await fixture()
  try {
    f.setAdmit(async () => { f.deliver(); f.finish('failed', { error: { type: 'provider.quota', status: 429, message: 'usage limit reached' } }) })
    await expect(f.run()).rejects.toMatchObject({ kind: 'quota' })
    expect(f.calls()).toBe(1)
    expect(f.pauses()).toBe(0)
  } finally { await f.dispose() }
})

test('explicit resume restores the original prompt and retries an acknowledged legacy quota failure', async () => {
  const f = await fixture()
  try {
    const originalID = f.state.activeReceipt!.promptID
    const originalText = 'Original task prompt with receipt token=token'
    delete f.state.activeReceipt!.text
    f.state.activeReceipt!.terminal = {
      outcome: 'failed', seq: 3, time: 30,
      error: { type: 'provider.quota', status: 429, message: 'usage limit reached' },
    }
    f.state.executor.authorizedThrough = 3
    f.reader.message = { get: async ({ messageID }: any) => ({
      id: messageID, type: 'user', time: { created: 10 }, text: originalText,
    }) } as any
    f.reader.messages = { list: async () => ({ data: [
      { id: 'idle_current', type: 'idle', time: { created: 30 }, outcome: 'failed', error: { type: 'provider.quota' } },
      { id: 'assistant_current', type: 'assistant', time: { created: 20 }, error: { type: 'provider.quota' } },
      { id: originalID, type: 'user', time: { created: 10 }, text: originalText },
    ], cursor: {} }) } as any

    const result = await f.run(true)

    expect(result.result?.status).toBe('progress')
    expect(f.calls()).toBe(1)
    expect(f.state.activeReceipt!.promptID).not.toBe(originalID)
    expect(f.state.activeReceipt!.text).toBe(originalText)
  } finally { await f.dispose() }
})

test('an explicit resume reports the durable admission identity exactly once', async () => {
  const f = await fixture()
  try {
    const admitted: any[] = []
    f.state.executor.authorizedAt = Date.now()
    f.setAdmit(async () => { f.deliver(); await f.receipt(); f.finish() })
    const result = await runRound({ state: f.state, reader: f.reader, signal: new AbortController().signal,
      explicitResume: true, save: async () => {}, prompt: async input => {
        expect(input.id).toBe(f.state.activeReceipt!.promptID)
        f.deliver(); await f.receipt(); f.finish()
      },
      onPromptAdmitted: async value => { admitted.push(value) },
      pause: async () => {} })
    expect(result.result?.status).toBe('progress')
    expect(admitted).toEqual([{ promptID: f.state.activeReceipt!.promptID, status: 'submitted' }])
  } finally { await f.dispose() }
})

test('explicit resume reports a missing legacy prompt instead of repeating its stale provider error', async () => {
  const f = await fixture()
  try {
    delete f.state.activeReceipt!.text
    f.state.activeReceipt!.terminal = {
      outcome: 'failed', seq: 3, time: 30,
      error: { type: 'provider.quota', status: 429, message: 'usage limit reached' },
    }
    f.state.executor.authorizedThrough = 3
    f.reader.message = { get: async () => {
      throw Object.assign(new Error('Message not found'), { _tag: 'MessageNotFoundError' })
    } } as any
    f.reader.messages = { list: async () => ({ data: [], cursor: {} }) } as any

    await expect(f.run(true)).rejects.toMatchObject({
      kind: 'protocol',
      message: expect.stringContaining('找不到原始任务请求'),
    })
    expect(f.calls()).toBe(0)
  } finally { await f.dispose() }
})

test('an unadmitted transport retry reuses the prepared prompt ID', async () => {
  const f = await fixture()
  try {
    f.setAdmit(async () => {
      if (f.calls() === 1) throw new Error('ECONNRESET')
      expect(f.state.activeReceipt!.promptID).toBe('msg_current')
      f.deliver(); await f.receipt(); f.finish()
    })
    expect((await f.run()).result?.status).toBe('progress')
    expect(f.calls()).toBe(2)
    expect(f.state.activeReceipt!.admissionRetries).toBe(1)
  } finally { await f.dispose() }
})

test('a repeated lifecycle interruption exhausts its saved retry budget', async () => {
  const f = await fixture()
  try {
    f.state.activeReceipt!.retries = 3
    f.deliver(); f.finish('interrupted', { reason: 'inactivity' })
    await expect(f.run()).rejects.toMatchObject({ kind: 'permanent' })
    expect(f.calls()).toBe(0)
    expect(f.state.activeReceipt!.retries).toBe(3)
  } finally { await f.dispose() }
})

test('an explicit resume can retry a previously acknowledged user interruption', async () => {
  const f = await fixture()
  try {
    f.deliver(); f.finish('interrupted', { reason: 'user' })
    await syncEvents(f.state, f.reader, new AbortController().signal)
    f.state.executor.authorizedThrough = f.state.executor.cursor
    expect((await f.run()).result?.status).toBe('progress')
    expect(f.calls()).toBe(1)
    expect(f.state.activeReceipt!.promptID).not.toBe('msg_current')
  } finally { await f.dispose() }
})

test('projected messages recover delivery and completion when the log has no historical events', async () => {
  const f = await fixture()
  try {
    let pages = 0
    f.reader.messages = { list: async (input: any) => {
      pages++
      if (!input.cursor) return { data: [{ id: 'idle_current', type: 'idle', time: { created: 30 }, outcome: 'succeeded' }], cursor: { next: 'older' } }
      expect(input.cursor).toBe('older')
      return { data: [{ id: 'msg_current', type: 'user', time: { created: 10 }, text: 'Implement one unit' }], cursor: {} }
    } } as any
    await syncMessages(f.state, f.reader, new AbortController().signal)
    expect(f.state.activeReceipt!.phase).toBe('delivered')
    expect(f.state.activeReceipt!.terminal?.outcome).toBe('succeeded')
    expect(pages).toBe(2)
    expect(await f.run()).toEqual({})
    expect(f.calls()).toBe(0)
  } finally { await f.dispose() }
})

test('projected messages recover a legacy token and consume its existing receipt', async () => {
  const f = await fixture()
  try {
    delete f.state.activeReceipt!.promptID
    delete f.state.activeReceipt!.text
    f.reader.messages = { list: async () => ({ data: [
      { id: 'idle_legacy', type: 'idle', time: { created: 30 }, outcome: 'succeeded' },
      { id: 'msg_legacy', type: 'user', time: { created: 10 }, text: 'Write token=token receipt' },
    ], cursor: {} }) } as any
    await f.receipt()
    expect((await f.run()).result?.status).toBe('progress')
    expect(f.state.activeReceipt!.promptID).toBe('msg_legacy')
    expect(f.calls()).toBe(0)
  } finally { await f.dispose() }
})

test('an ambiguous interrupted idle stays paused when no lifecycle reason was persisted', async () => {
  const f = await fixture()
  try {
    f.reader.messages = { list: async () => ({ data: [
      { id: 'idle_current', type: 'idle', time: { created: 30 }, outcome: 'interrupted' },
      { id: 'msg_current', type: 'user', time: { created: 10 }, text: 'Implement one unit' },
    ], cursor: {} }) } as any
    await f.receipt()
    await expect(f.run()).rejects.toMatchObject({ kind: 'interrupted' })
    expect(f.calls()).toBe(0)
  } finally { await f.dispose() }
})

test('projected failure classification uses errors from the current prompt only', async () => {
  const f = await fixture()
  try {
    f.reader.messages = { list: async () => ({ data: [
      { id: 'idle_current', type: 'idle', time: { created: 30 }, outcome: 'failed' },
      { id: 'assistant_current', type: 'assistant', time: { created: 20 }, error: { type: 'provider.quota', status: 429, message: 'usage limit reached' } },
      { id: 'msg_current', type: 'user', time: { created: 10 }, text: 'Implement one unit' },
      { id: 'assistant_old', type: 'assistant', time: { created: 5 }, error: { status: 503 } },
    ], cursor: {} }) } as any
    await expect(f.run()).rejects.toMatchObject({ kind: 'quota' })
    expect(f.calls()).toBe(0)
  } finally { await f.dispose() }
})

test('a newer live event cannot skip a user stop waiting in historical replay', async () => {
  const f = await fixture()
  try {
    f.event('session.execution.interrupted', { reason: 'user' })
    applyEvent(f.state, { type: 'session.execution.started', created: 10,
      durable: { aggregateID: f.state.sessionID, seq: 10, version: 1 }, data: { sessionID: f.state.sessionID } } as any)
    expect(f.state.executor.cursor).toBe(0)
    await syncEvents(f.state, f.reader, new AbortController().signal)
    expect(() => assertNotStopped(f.state)).toThrow('用户已中断任务')
  } finally { await f.dispose() }
})

test('a user stop after explicit resume remains blocking even if its timestamp ties the cutoff', async () => {
  const f = await fixture()
  try {
    f.state.executor.authorizedAt = 100
    f.state.executor.userStop = 3
    f.state.executor.userStopAt = 100
    expect(() => assertNotStopped(f.state)).toThrow('用户已中断任务')
    f.state.executor.userStopAt = 101
    expect(() => assertNotStopped(f.state)).toThrow('用户已中断任务')
    f.state.executor.userStop = 2
    f.state.executor.authorizedThrough = 2
    expect(() => assertNotStopped(f.state)).not.toThrow()
  } finally { await f.dispose() }
})

test('an unrelated later failure cannot replace the completion of this prompt', async () => {
  const f = await fixture()
  try {
    f.reader.messages = { list: async () => ({ data: [
      { id: 'idle_later', type: 'idle', time: { created: 60 }, outcome: 'failed' },
      { id: 'assistant_later', type: 'assistant', time: { created: 50 }, error: { type: 'provider.quota' } },
      { id: 'msg_later', type: 'user', time: { created: 40 }, text: 'Other work' },
      { id: 'idle_current', type: 'idle', time: { created: 30 }, outcome: 'succeeded' },
      { id: 'msg_current', type: 'user', time: { created: 10 }, text: 'Implement one unit' },
    ], cursor: {} }) } as any
    expect(await f.run()).toEqual({})
    expect(f.state.activeReceipt!.terminal?.outcome).toBe('succeeded')
    expect(f.state.activeReceipt!.terminal?.error).toBeUndefined()
    expect(f.calls()).toBe(0)
  } finally { await f.dispose() }
})

test('a completed prior shutdown cannot authorize an unrelated later interruption', async () => {
  const f = await fixture()
  try {
    f.state.activeReceipt!.terminal = { outcome: 'interrupted', time: 30, reason: 'shutdown' }
    f.reader.messages = { list: async () => ({ data: [
      { id: 'idle_later', type: 'idle', time: { created: 60 }, outcome: 'interrupted' },
      { id: 'msg_later', type: 'user', time: { created: 40 }, text: 'Other work' },
      { id: 'idle_current', type: 'idle', time: { created: 30 }, outcome: 'interrupted' },
      { id: 'msg_current', type: 'user', time: { created: 10 }, text: 'Implement one unit' },
    ], cursor: {} }) } as any
    await f.receipt()
    await expect(f.run()).rejects.toMatchObject({ kind: 'interrupted' })
    expect(f.calls()).toBe(0)
  } finally { await f.dispose() }
})

test('a stop hidden behind a page of passive notifications prevents admission', async () => {
  const f = await fixture()
  try {
    let pages = 0
    f.reader.messages = { list: async (input: any) => {
      pages++
      return input.cursor ? { data: [{ id: 'idle_old', type: 'idle', time: { created: 30 }, outcome: 'interrupted' }], cursor: {} } :
        { data: [{ id: 'note', type: 'synthetic', time: { created: 50 }, text: 'status' }], cursor: { next: 'older' } }
    } } as any
    delete f.state.activeReceipt
    await expect(syncMessages(f.state, f.reader, new AbortController().signal)).rejects.toMatchObject({ kind: 'interrupted' })
    expect(pages).toBe(2)
    expect(f.calls()).toBe(0)
  } finally { await f.dispose() }
})

test('later unrelated execution events cannot replace this round terminal result', async () => {
  const f = await fixture()
  try {
    f.deliver(); f.finish()
    await syncEvents(f.state, f.reader, new AbortController().signal)
    const terminalSeq = f.state.activeReceipt!.terminal?.seq
    f.event('session.execution.started')
    f.event('session.execution.failed', { error: { type: 'provider.quota' } })
    await syncEvents(f.state, f.reader, new AbortController().signal)
    expect(f.state.activeReceipt!.terminal?.outcome).toBe('succeeded')
    expect(f.state.activeReceipt!.terminal?.seq).toBe(terminalSeq)
  } finally { await f.dispose() }
})

test('a known lifecycle event remains attributable when its idle projection has a later timestamp', async () => {
  const f = await fixture()
  try {
    f.state.activeReceipt!.terminal = { outcome: 'interrupted', time: 29, reason: 'shutdown' }
    f.reader.messages = { list: async () => ({ data: [
      { id: 'idle_current', type: 'idle', time: { created: 30 }, outcome: 'interrupted' },
      { id: 'msg_current', type: 'user', time: { created: 10 }, text: 'Implement one unit' },
    ], cursor: {} }) } as any
    await f.receipt()
    expect((await f.run()).result?.status).toBe('progress')
    expect(f.state.activeReceipt!.terminal?.reason).toBe('shutdown')
    expect(f.calls()).toBe(0)
  } finally { await f.dispose() }
})

test('a legacy request still in the inbox is adopted by token before any new admission', async () => {
  const f = await fixture()
  try {
    delete f.state.activeReceipt!.promptID
    delete f.state.activeReceipt!.text
    delete f.state.activeReceipt!.phase
    let queued = true
    f.reader.inbox.list = async () => queued ? [{ id: 'msg_legacy', type: 'user', payload: { text: 'Write token=token receipt' } }] as any : []
    f.setPause(async () => {
      expect(f.state.activeReceipt!.promptID).toBe('msg_legacy')
      queued = false
      f.deliver(); await f.receipt(); f.finish()
    })
    expect((await f.run()).result?.status).toBe('progress')
    expect(f.calls()).toBe(0)
    expect(f.pauses()).toBe(1)
  } finally { await f.dispose() }
})
