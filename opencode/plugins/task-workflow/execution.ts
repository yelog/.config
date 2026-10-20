import { OpenCode, type OpenCodeClient, type OpenCodeEvent, type SessionEventDurable, type SessionMessageInfo } from '@opencode/client'
import { Service } from '@opencode/client/service'
import { randomUUID } from 'node:crypto'
import { readFile } from 'node:fs/promises'
import { setTimeout as delay } from 'node:timers/promises'
import { failureKind, receiptFrom, transient, type FailureKind, type ReviewReason } from './progress.js'

export type ActiveReceipt = {
  path: string; token: string; stage: string; review: boolean
  reviewReason?: ReviewReason
  promptID?: string; text?: string; before?: string; preparedAt?: number
  phase?: 'prepared' | 'admitted' | 'delivered'
  delivered?: number; deliveredAt?: number; terminal?: { outcome: string; seq?: number; time?: number; reason?: string; error?: unknown }
  retries?: number; admissionRetries?: number; admittedAt?: number
}
export type ExecutionState = {
  sessionID: string
  executor: { version: 1; cursor: number; authorizedThrough: number; authorizedAt?: number; autoResume: boolean; userStop?: number; userStopAt?: number; recoveryFailures?: number; manualResumeAttempts?: number; acceptedIdle?: string }
  activeReceipt?: ActiveReceipt
}
export type SessionReader = Pick<OpenCodeClient['session'], 'log' | 'inbox' | 'active'> & {
  message?: OpenCodeClient['session']['message']
  messages?: OpenCodeClient['message']
}
export type ReaderFactory = () => Promise<SessionReader>
const MAX_LEGACY_PROMPT_PAGES = 50

// Discovery is read-only: never start, replace or restart the shared service here.
export const managedSessionReader: ReaderFactory = async () => {
  const endpoint = await Service.discover()
  if (!endpoint) throw new ExecutionError('transport', '无法发现当前后台服务；保留执行状态，等待服务恢复。')
  const client = OpenCode.make({ baseUrl: endpoint.url, headers: Service.headers(endpoint),
    fetch: (input, options) => fetch(input, { ...options,
      signal: options?.signal ? AbortSignal.any([options.signal, AbortSignal.timeout(30_000)]) : AbortSignal.timeout(30_000) }),
  })
  return { ...client.session, message: client.session.message, messages: client.message }
}

export class ExecutionError extends Error {
  constructor(readonly kind: FailureKind | 'interrupted' | 'protocol', message: string) { super(message) }
}

export function applyEvent(state: ExecutionState, event: OpenCodeEvent | SessionEventDurable): void {
  if (!('durable' in event) || event.durable.aggregateID !== state.sessionID) return
  const seq = event.durable.seq
  if (event.type === 'session.execution.interrupted' && event.data.reason === 'user') {
    state.executor.userStop = Math.max(state.executor.userStop ?? 0, seq)
    state.executor.userStopAt = Math.max(state.executor.userStopAt ?? 0, event.created)
  }
  const round = state.activeReceipt
  if (!round) return
  if (event.type === 'session.inbox.enqueued') {
    const item = event.data.item
    if (!round.promptID && item?.type === 'user' && item.payload.text.includes(round.token)) round.promptID = event.data.inboxID
    if (event.data.inboxID === round.promptID && !round.delivered) round.phase = 'admitted'
  }
  if (event.type === 'session.inbox.delivered' && event.data.inboxID === round.promptID) {
    round.delivered = seq; round.deliveredAt = event.created; round.phase = 'delivered'
    if ((round.terminal?.seq ?? 0) < seq) delete round.terminal
  }
  if (event.type === 'session.inbox.cancelled' && event.data.inboxID === round.promptID) {
    round.terminal = { outcome: 'interrupted', seq, time: event.created }
  }
  // The session event API does not carry an execution ID. Once this round has
  // ended, later model executions cannot change its terminal result unless a
  // new delivery for this exact prompt first clears the terminal above.
  if (round.terminal && event.type.startsWith('session.execution.') && seq > (round.terminal.seq ?? 0)) return
  if (!round.delivered || seq < round.delivered || seq < (round.terminal?.seq ?? 0)) return
  if (event.type === 'session.execution.started') delete round.terminal
  if (event.type === 'session.execution.succeeded') round.terminal = { outcome: 'succeeded', seq, time: event.created }
  if (event.type === 'session.execution.failed') round.terminal = { outcome: 'failed', seq, time: event.created, error: event.data.error }
  if (event.type === 'session.execution.interrupted') round.terminal = { outcome: 'interrupted', seq, time: event.created, reason: event.data.reason }
}

export async function syncEvents(state: ExecutionState, reader: SessionReader, signal: AbortSignal): Promise<void> {
  for await (const event of reader.log({ sessionID: state.sessionID, after: state.executor.cursor, follow: false }, { signal })) {
    signal.throwIfAborted()
    if (event.type === 'log.synced') {
      state.executor.cursor = Math.max(state.executor.cursor, event.seq ?? 0)
      continue
    }
    applyEvent(state, event)
    // Live events do not advance this cursor: replay must still see any gaps.
    if (event.durable.aggregateID === state.sessionID) state.executor.cursor = Math.max(state.executor.cursor, event.durable.seq)
  }
}

export function assertNotStopped(state: ExecutionState): void {
  if ((state.executor.userStop ?? 0) > state.executor.authorizedThrough) {
    throw new ExecutionError('user', '用户已中断任务；保留停止状态，使用 /task-resume 后才继续。')
  }
}

// Some V2 builds retain projected messages while their experimental log only
// returns log.synced. Match the actual prompt in the full message timeline.
export async function syncMessages(state: ExecutionState, reader: SessionReader, signal: AbortSignal): Promise<void> {
  const round = state.activeReceipt
  if (round?.promptID && !round.text && reader.message) {
    const prompt = await reader.message.get({ sessionID: state.sessionID, messageID: round.promptID }, { signal }).catch(error => {
      if (error && typeof error === 'object' && '_tag' in error && error._tag === 'MessageNotFoundError') return undefined
      throw error
    })
    if (prompt && prompt.id !== round.promptID) throw new ExecutionError('protocol', 'session 返回的消息 ID 与待恢复请求不匹配。')
    if (prompt && prompt.type !== 'user') throw new ExecutionError('protocol', '原始任务消息不是 user 请求，无法安全恢复。')
    if (prompt?.type === 'user') round.text = prompt.text
  }
  if (!reader.messages) return
  let cursor: string | undefined
  let latestIdle: SessionMessageInfo | undefined
  let interruptedIdle: SessionMessageInfo | undefined
  const newer: SessionMessageInfo[] = []
  if (round && !round.promptID) {
    let legacyPrompt: Extract<SessionMessageInfo, { type: 'user' }> | undefined
    let tokenCursor: string | undefined
    let historyBoundReached = false
    for (let pageNumber = 0; pageNumber < MAX_LEGACY_PROMPT_PAGES; pageNumber++) {
      signal.throwIfAborted()
      const page = await reader.messages.list({ sessionID: state.sessionID, limit: 100, ...(tokenCursor ? { cursor: tokenCursor } : { order: 'desc' as const }) }, { signal })
      for (const message of page.data) {
        if (message.type !== 'user' || !message.text.includes(round.token)) continue
        // Messages are descending; a legacy retry can reuse the same receipt
        // token, so the newest matching user input is the resumable one.
        legacyPrompt = message
        break
      }
      if (legacyPrompt) break
      const next = page.cursor?.next
      if (!next || next === tokenCursor) { tokenCursor = undefined; break }
      tokenCursor = next
      if (pageNumber === MAX_LEGACY_PROMPT_PAGES - 1) historyBoundReached = true
    }
    if (!legacyPrompt && historyBoundReached) {
      throw new ExecutionError('protocol', '历史请求超过安全检索范围，无法确认恢复请求；未重新提交。')
    }
    if (legacyPrompt) round.promptID = legacyPrompt.id
  }
  const assertIdle = (knownInterruption = false) => {
    if (interruptedIdle?.type === 'idle' && interruptedIdle.id !== state.executor.acceptedIdle && !knownInterruption) {
      throw new ExecutionError('interrupted', '会话已中断且缺少可确认的生命周期原因；保持暂停，使用 /task-resume 后继续。')
    }
  }
  while (true) {
    const page = await reader.messages.list({ sessionID: state.sessionID, limit: 100, ...(cursor ? { cursor } : { order: 'desc' as const }) }, { signal })
    const timeline = [...newer, ...page.data]
    latestIdle ??= timeline.find(message => message.type === 'idle')
    interruptedIdle ??= timeline.find(message => message.type === 'idle' && message.outcome === 'interrupted' &&
      message.time.created >= (state.executor.authorizedAt ?? 0))
    const index = page.data.findIndex(message => message.type === 'user' && message.id === round?.promptID)
    if (round && index >= 0) {
      const prompt = page.data[index]
      if (prompt?.type !== 'user') throw new ExecutionError('protocol', '找到的恢复消息不是 user 请求，无法安全恢复。')
      round.promptID = prompt.id; round.phase = 'delivered'; round.deliveredAt = prompt.time.created
      // Older task states saved only the receipt identity. Recover the exact
      // admitted input from the session timeline before attempting a retry.
      round.text ??= prompt.text
      const following = [...newer, ...page.data.slice(0, index)]
      // The first idle chronologically after this prompt closes this execution.
      // Newer prompts and their errors belong to later work in the same session.
      let idleIndex = following.length - 1
      while (idleIndex >= 0 && following[idleIndex].type !== 'idle') idleIndex--
      const idle = following[idleIndex]
      const knownInterruption = idle?.type === 'idle' && idle.id === latestIdle?.id &&
        round.terminal?.outcome === idle.outcome && Boolean(round.terminal.reason) &&
        round.terminal.time !== undefined && round.terminal.time >= prompt.time.created &&
        Math.abs(round.terminal.time - idle.time.created) <= 30_000
      assertIdle(knownInterruption)
      if (idle?.type === 'idle') {
        const assistant = following.slice(idleIndex + 1).find(message => message.type === 'assistant' && message.error)
        const error = idle.error ?? (assistant?.type === 'assistant' ? assistant.error : undefined)
        const reason = knownInterruption ? round.terminal!.reason : undefined
        round.terminal = { outcome: idle.outcome, time: idle.time.created, error, reason, seq: round.terminal?.seq }
        state.executor.acceptedIdle = latestIdle!.id
      }
      return
    }
    newer.push(...page.data)
    if (!round && page.data.some(message => message.time.created < (state.executor.authorizedAt ?? 0))) { assertIdle(); return }
    if (round?.preparedAt !== undefined && page.data.some(message => message.time.created < round.preparedAt!)) { assertIdle(); return }
    const next = page.cursor?.next
    if (!next || next === cursor) { assertIdle(); return }
    cursor = next
  }
}

export async function readReceipt(round: ActiveReceipt): Promise<Record<string, any> | undefined> {
  const text = await readFile(round.path, 'utf8').catch((error: NodeJS.ErrnoException) => {
    if (error.code === 'ENOENT') return ''
    throw error
  })
  return receiptFrom(text, round.token, round.stage)
}

export async function runRound(input: {
  state: ExecutionState; reader: SessionReader; signal: AbortSignal
  explicitResume?: boolean
  save: () => Promise<void>
  prompt: (input: { sessionID: string; id: string; text: string; delivery: 'queue'; metadata: Record<string, string> }) => Promise<unknown>
  onPromptAdmitted?: (input: { promptID: string; status: 'submitted' | 'pending' | 'active' }) => Promise<void>
  pause?: (milliseconds: number) => Promise<void>
}): Promise<{ result?: Record<string, any> }> {
  const { state, reader, signal, save } = input
  const round = state.activeReceipt!
  const pause = input.pause ?? (milliseconds => delay(milliseconds, undefined, { signal }))
  let readFailures = 0
  let resumeAdmissionReported = false
  const reportResumeAdmission = async (status: 'submitted' | 'pending' | 'active') => {
    if (!input.explicitResume || resumeAdmissionReported || !round.promptID || !input.onPromptAdmitted) return
    resumeAdmissionReported = true
    await input.onPromptAdmitted({ promptID: round.promptID, status }).catch(() => {})
  }
  while (true) {
    signal.throwIfAborted()
    const beforeSync = JSON.stringify({ executor: state.executor, round })
    let pending: boolean, active: boolean
    try {
      await syncEvents(state, reader, signal)
      assertNotStopped(state)
      const [inbox, sessions] = await Promise.all([
        reader.inbox.list({ sessionID: state.sessionID }, { signal }), reader.active({ signal }),
      ])
      if (!round.promptID) {
        const queued = inbox.find(item => item.type === 'user' && item.payload.text.includes(round.token))
        if (queued) { round.promptID = queued.id; round.phase = 'admitted' }
      }
      pending = inbox.some(item => item.id === round.promptID)
      active = Boolean(sessions[state.sessionID])
      if (pending) await reportResumeAdmission('pending')
      else if (active && round.phase !== 'prepared') await reportResumeAdmission('active')
      if (!active && !pending) await syncMessages(state, reader, signal)
      assertNotStopped(state)
      readFailures = 0
      if (JSON.stringify({ executor: state.executor, round }) !== beforeSync) await save()
    } catch (error) {
      signal.throwIfAborted()
      if (transient(error) && readFailures++ < 3) { await pause(1000 * 2 ** readFailures); continue }
      throw error
    }
    // A receipt is authoritative only once the admitted work is no longer running.
    if (active || pending) { await pause(750); continue }
    const result = await readReceipt(round)
    signal.throwIfAborted()
    assertNotStopped(state)
    if (result) return { result }
    if (round.terminal) {
      const terminal = round.terminal
      if (terminal.outcome === 'succeeded') return {}
      const kind = terminal.outcome === 'failed' ? failureKind(terminal.error) : failureKind({ reason: terminal.reason })
      const acknowledged = (terminal.seq !== undefined && terminal.seq <= state.executor.authorizedThrough) ||
        (terminal.time !== undefined && terminal.time <= (state.executor.authorizedAt ?? 0))
      if (!round.text && input.explicitResume && acknowledged) {
        throw new ExecutionError('protocol', '找不到原始任务请求，未重新提交。请检查 session 历史和任务报告后再处理。')
      }
      if (round.text && (acknowledged || ((kind === 'lifecycle' || kind === 'transport' || kind === 'rate-limit') && (round.retries ?? 0) < 3))) {
        if (!acknowledged) round.retries = (round.retries ?? 0) + 1
        // The prior input was delivered. A new identity resumes the same receipt/unit.
        round.promptID = `msg_${randomUUID().replaceAll('-', '')}`
        round.preparedAt = Date.now()
        round.phase = 'prepared'; delete round.delivered; delete round.deliveredAt; delete round.terminal; delete round.admittedAt
        round.admissionRetries = 0
        await save()
        if (!acknowledged) await pause(2000 * 2 ** ((round.retries ?? 1) - 1))
        continue
      }
      throw new ExecutionError(['lifecycle', 'transport', 'rate-limit'].includes(kind) ? 'permanent' : kind === 'permanent' && terminal.outcome === 'interrupted' ? 'interrupted' : kind,
        kind === 'quota' ? `模型额度耗尽，暂停自动重试：${JSON.stringify(terminal.error)}` :
          `阶段 ${round.stage} ${terminal.outcome}：${JSON.stringify(terminal.error ?? terminal.reason ?? '原因未知')}`)
    }
    // No legacy input or receipt remains: let the workflow repair the missing receipt.
    if (!round.text) {
      if (input.explicitResume) {
        throw new ExecutionError('protocol', '找不到原始任务请求，未重新提交。请检查 session 历史和任务报告后再处理。')
      }
      return {}
    }
    if (round.phase !== 'prepared' && round.phase !== undefined) {
      round.admittedAt ??= Date.now()
      if (Date.now() - round.admittedAt > 30_000) {
        throw new ExecutionError('protocol', '请求已入队但缺少投递/完成记录；保留原请求，未重复提交。')
      }
      await pause(750); continue
    }
    round.promptID ??= `msg_${randomUUID().replaceAll('-', '')}`
    await save()
    signal.throwIfAborted()
    assertNotStopped(state)
    try {
      await input.prompt({ sessionID: state.sessionID, id: round.promptID, text: round.text, delivery: 'queue',
        metadata: { taskWorkflowToken: round.token, taskWorkflowStage: round.stage } })
      if (round.phase !== 'delivered') round.phase = 'admitted'
      round.admittedAt = Date.now(); await save()
      await reportResumeAdmission('submitted')
    } catch (error) {
      signal.throwIfAborted()
      // The next loop reconciles durable admission before retrying this exact ID.
      if (!transient(error) || (round.admissionRetries ?? 0) >= 3) throw error
      round.admissionRetries = (round.admissionRetries ?? 0) + 1
      await save(); await pause(1000 * 2 ** (round.admissionRetries - 1))
    }
  }
}
