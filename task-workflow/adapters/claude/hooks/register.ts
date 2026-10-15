type ProcessResult = { exitCode: number; stdout: string; stderr: string }
type Model = { provider?: string; model: string }
type CoreResponse = { protocolVersion: number; ok: boolean; data?: any; error?: { code: string; message: string; retryable?: boolean } }
type ActiveAttempt = {
  taskId: string
  attemptId: string
  token: string
  stage: string
  model: Model
  turnId?: string
  root: string
  worktree?: string
  sessionId: string
}

const active = new Map<string, ActiveAttempt>()
const statusText = new Map<string, string>()
const timers = new Map<string, { cancel(): void }>()

async function corePath($: any): Promise<string> {
  const configured = await $.env.get('TASK_WORKFLOW_CORE')
  if (typeof configured === 'string' && configured.trim()) return configured
  return $.plugin.root.includes('/adapters/claude') ? `${$.plugin.root}/../../dist/cli.js` : `${$.plugin.root}/dist/cli.js`
}

async function runCore($: any, command: string, payload: Record<string, unknown>): Promise<any> {
  const result = await $.process.run(['node', await corePath($), command, '--payload', JSON.stringify(payload)], { timeoutMs: 600_000 }) as ProcessResult
  const raw = result.stdout.trim()
  if (!raw) throw new Error(result.stderr || `task-workflow core returned no response for ${command}`)
  let response: CoreResponse
  try { response = JSON.parse(raw) as CoreResponse } catch { throw new Error(`invalid task-workflow response: ${raw.slice(0, 500)}`) }
  if (!response.ok) throw new Error(response.error?.message ?? `task-workflow ${command} failed`)
  return response.data
}

async function sessionId($: any): Promise<string> { return String(await $.session.id()) }
async function sessionRoot($: any): Promise<string> { return String(await $.session.cwd()) }
async function sessionCwd($: any): Promise<string> { return String(await $.session.cwd()) }

function formatSummary(summary: any): string {
  if (!summary) return '当前会话没有任务。'
  const error = summary.lastError ? `\n错误：${summary.lastError}` : ''
  const next = summary.next ? `\n下一步：${summary.next}` : ''
  return `任务：${summary.name}\n状态：${summary.status}\n阶段：${summary.stage}${summary.reviewPending ? '（收尾审查）' : ''}\n轮次：${summary.round}/${summary.totalRounds}\n模型：${summary.model}\n分支：${summary.taskBranch || '(尚未创建)'} → ${summary.targetBranch}\nworktree：${summary.worktree || '(尚未创建)'}${next}${error}`
}

function setStatus($: any, summary: any): void {
  const id = String(summary?.sessionId ?? '')
  if (!id) return
  statusText.set(id, summary ? `${summary.name} · ${summary.stage} · ${summary.status}${summary.reviewPending ? ' · review' : ''}${summary.next ? ` · ${summary.next}` : ''}` : '')
  $.ui.invalidate('ui.render')
}

function inside(value: string, root: string): boolean {
  const normalizedValue = value.replace(/\\/g, '/').replace(/\/$/, '')
  const normalizedRoot = root.replace(/\\/g, '/').replace(/\/$/, '')
  return normalizedValue === normalizedRoot || normalizedValue.startsWith(`${normalizedRoot}/`)
}

function writeTool(tool: string): boolean {
  return ['Edit', 'Write', 'NotebookEdit', 'Bash', 'PowerShell', 'Monitor'].includes(tool)
}

function supportedModel(model: any): boolean {
  const value = String(model?.model ?? '')
  return value === 'codex/gpt-6.1-sol' || value === 'codex/gpt-6-luna' ||
    value === 'gpt-6.1-sol' || value === 'gpt-6-luna' ||
    value === 'group/auto-gpt-6-1-sol' || value === 'group/auto-gpt-6-luna' ||
    value === 'sonnet' || value === 'opus' || value === 'haiku' || value === 'inherit' || value.startsWith('claude-')
}

function runtimeModel(model: Model): string {
  if (model.provider === 'magpie' && model.model === 'codex/gpt-6.1-sol') return 'group/auto-gpt-6-1-sol'
  if (model.provider === 'magpie' && model.model === 'codex/gpt-6-luna') return 'group/auto-gpt-6-luna'
  // Keep old pinned task snapshots resumable while routing them through magpie.
  if (model.provider === 'xrouter' && model.model === 'gpt-6.1-sol') return 'group/auto-gpt-6-1-sol'
  if (model.provider === 'xrouter' && model.model === 'gpt-6-luna') return 'group/auto-gpt-6-luna'
  if (model.model === 'codex/gpt-6.1-sol') return 'group/auto-gpt-6-1-sol'
  if (model.model === 'codex/gpt-6-luna') return 'group/auto-gpt-6-luna'
  if (model.model === 'gpt-6.1-sol') return 'group/auto-gpt-6-1-sol'
  if (model.model === 'gpt-6-luna') return 'group/auto-gpt-6-luna'
  return model.model
}

async function refreshStatus($: any): Promise<any> {
  try {
    const id = await sessionId($)
    const summary = await runCore($, 'status', { root: await sessionRoot($), sessionId: id })
    setStatus($, { ...summary, sessionId: id })
    return summary
  } catch (error) {
    statusText.set(await sessionId($), `task-workflow 状态不可用：${error instanceof Error ? error.message : String(error)}`)
    $.ui.invalidate('ui.render')
    return undefined
  }
}

function scheduleNext($: any): void {
  void sessionId($).then(id => $.clock.after(0, () => { void startNext($, id) }))
}

async function startNext($: any, id: string): Promise<void> {
  if (id !== await sessionId($) || active.has(id)) return
  try {
    const next = await runCore($, 'next', { root: await sessionRoot($), sessionId: id })
    setStatus($, { ...next.summary, sessionId: id })
    if (next.kind === 'done') return
    if (next.kind === 'integration') {
      if (!supportedModel(next.model)) throw new Error(`Claude Code cannot use configured model ${next.model?.model ?? '(empty)'}; set executor to sonnet, opus, haiku, or a claude-* model id.`)
      const attempt: ActiveAttempt = { taskId: next.task, attemptId: next.attemptId, token: next.token, stage: 'integrate', model: next.model, root: await sessionRoot($), sessionId: id }
      active.set(id, attempt)
      await $.prompt.submit({ text: next.prompt })
      return
    }
    if (!supportedModel(next.model)) throw new Error(`Claude Code cannot use configured model ${next.model?.model ?? '(empty)'}; set planner/executor to sonnet, opus, haiku, or a claude-* model id.`)
    const attempt: ActiveAttempt = { taskId: next.task, attemptId: next.attemptId, token: next.token, stage: next.stage, model: next.model, root: await sessionRoot($), worktree: next.summary?.worktree, sessionId: id }
    active.set(id, attempt)
    await $.prompt.submit({ text: next.prompt })
  } catch (error) {
    active.delete(id)
    const message = error instanceof Error ? error.message : String(error)
    statusText.set(id, `task-workflow 暂停：${message}`)
    $.ui.toast(`任务暂停：${message}`)
    $.ui.invalidate('ui.render')
  }
}

async function pauseAfterAbort($: any, attempt: ActiveAttempt, reason: string): Promise<void> {
  try {
    const summary = await runCore($, 'pause', { root: attempt.root, sessionId: attempt.sessionId, reason })
    setStatus($, { ...summary, sessionId: attempt.sessionId })
  } catch (error) { $.ui.toast(`任务暂停状态保存失败：${error instanceof Error ? error.message : String(error)}`) }
}

export function register(on: any): void {
  on('session.start', async ($: any, e: any, next: any) => {
    await $.command.register({ name: 'task', description: 'Start a resumable analyze -> plan -> implement -> integrate task', argumentHint: '<requirement>' })
    await $.command.register({ name: 'task-status', description: 'Show the current task status' })
    await $.command.register({ name: 'task-resume', description: 'Resume the current paused task', immediate: true })
    await $.command.register({ name: 'task-cleanup', description: 'List task workflow records; use apply only for explicit maintenance cleanup', argumentHint: '[apply]' })
    const id = await sessionId($)
    if (!timers.has(id)) timers.set(id, $.clock.every(3000, () => { void refreshStatus($) }))
    await refreshStatus($)
    return next(e)
  })

  on('session.end', async ($: any, e: any, next: any) => {
    const id = await sessionId($)
    timers.get(id)?.cancel()
    timers.delete(id)
    active.delete(id)
    statusText.delete(id)
    return next(e)
  })

  on('command.run', { command: 'task' }, async ($: any, e: any) => {
    if (!e.args?.trim()) return { text: '用法：/task <需求描述>' }
    const id = await sessionId($)
    const data = await runCore($, 'init', { root: await sessionRoot($), sessionId: id, requirement: e.args.trim(), allowCommit: true, allowMerge: true, allowCleanup: true })
    setStatus($, { ...data.summary, sessionId: id })
    scheduleNext($)
    return { text: `已创建任务 ${data.summary.name}，开始 ${data.summary.stage}。` }
  })

  on('command.run', { command: 'task-status' }, async ($: any) => {
    const summary = await refreshStatus($)
    return { text: formatSummary(summary) }
  })

  on('command.run', { command: 'task-resume' }, async ($: any) => {
    const id = await sessionId($)
    if (active.has(id)) return { text: '任务当前仍在执行中。' }
    const summary = await runCore($, 'resume', { root: await sessionRoot($), sessionId: id })
    setStatus($, { ...summary, sessionId: id })
    scheduleNext($)
    return { text: `任务已恢复：${summary.name}，继续 ${summary.stage}。` }
  })

  on('command.run', { command: 'task-cleanup' }, async ($: any, e: any) => {
    const apply = e.args?.trim() === 'apply'
    if (e.args?.trim() && !apply) return { text: '用法：/task-cleanup [apply]；默认只检查，不删除。' }
    const result = await runCore($, 'cleanup', { root: await sessionRoot($), apply })
    return { text: result.entries.length ? result.entries.map((entry: any) => `- ${entry.name ?? entry.taskId}: ${entry.reason}`).join('\n') : '没有任务记录。' }
  })

  on('turn.start', async ($: any, e: any, next: any) => {
    const attempt = active.get(await sessionId($))
    if (attempt && !attempt.turnId) attempt.turnId = e.turnId
    return next(e)
  })

  on('tool.call', async ($: any, e: any, next: any) => {
    const attempt = active.get(await sessionId($))
    if (!attempt) return next(e)
    const tool = String(e.tool)
    const cwd = await sessionCwd($)
    if (attempt.stage === 'implement') {
      if (tool === 'EnterWorktree') {
        if (String(e.path ?? '') !== attempt.worktree) return { deny: `EnterWorktree must use the task worktree ${attempt.worktree}.` }
        return next(e)
      }
      if (tool === 'ExitWorktree') return { deny: 'Stay in the task worktree until implementation and its receipt are complete.' }
      if (writeTool(tool) && (!attempt.worktree || !inside(cwd, attempt.worktree))) return { deny: `Task implementation is locked to ${attempt.worktree}; enter that worktree before writing or running commands.` }
    }
    if (attempt.stage === 'integrate' && writeTool(tool)) return { deny: 'Integration is controlled by the task workflow core after ExitWorktree; do not edit or run Git commands in this handoff.' }
    return next(e)
  }).catch(async ($: any, e: any, next: any) => {
    if (next.called) return next(e)
    return { deny: `task-workflow safety guard failed before ${String(e.tool)} could run: ${next.error?.message ?? 'unknown error'}` }
  })

  on('turn.step', async function* ($: any, e: any, next: any) {
    const attempt = active.get(await sessionId($))
    if (!attempt || e.agentId) return yield* next(e)
    return yield* next({ ...e, model: runtimeModel(attempt.model) })
  })

  on('turn.complete', async ($: any, e: any, next: any) => {
    const id = await sessionId($)
    const attempt = active.get(id)
    const result = await next(e)
    if (!attempt || (attempt.turnId && attempt.turnId !== e.turnId)) return result
    active.delete(id)
    if (e.isAborted) {
      await pauseAfterAbort($, attempt, '用户中断了当前阶段')
      return result
    }
    try {
      if (attempt.stage === 'integrate') {
        const summary = await runCore($, 'integrate', { root: await sessionRoot($), cwd: await sessionCwd($), sessionId: id, attemptId: attempt.attemptId, token: attempt.token })
        setStatus($, { ...summary, sessionId: id })
        $.ui.toast(`任务 ${summary.name} 已完成并合并。`)
        return result
      }
      const data = await runCore($, 'complete', { root: attempt.root, cwd: await sessionCwd($), sessionId: id, attemptId: attempt.attemptId, token: attempt.token, turnId: e.turnId })
      setStatus($, { ...data.summary, sessionId: id })
      scheduleNext($)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      await pauseAfterAbort($, attempt, message)
      $.ui.toast(`任务需要恢复：${message}`)
    }
    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($: any, e: any, next: any) => {
    const text = statusText.get(await sessionId($))
    if (!text) return next(e)
    const { Text } = $.ui.resolve(e)
    return Text({ children: [text], dimColor: true, wrap: 'truncate' })
  })
}
