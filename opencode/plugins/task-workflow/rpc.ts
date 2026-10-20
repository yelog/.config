import { Rpc } from '@opencode/plugin/rpc'
import type { TaskPause } from './progress.js'

export const Workflow = Rpc.define({
  id: 'local.task-workflow',
  methods: {
    status: {
      input: { type: 'object', properties: { sessionID: { type: 'string' } }, required: ['sessionID'], additionalProperties: false },
      output: { type: 'object', properties: { task: { type: ['object', 'null'] } }, required: ['task'] },
    },
  },
  events: {
    updated: { schema: { type: 'object', properties: { sessionID: { type: 'string' } }, required: ['sessionID'] } },
  },
})

export type TaskView = {
  sessionID: string; name: string; step: number; status: string; running: boolean
  review: boolean; model: string; rounds: number; next: string; error?: string
  pause?: TaskPause; resumeHint?: string
}

export function isTerminalTaskStatus(status: string): boolean {
  return status === 'done' || status === 'blocked'
}

export function terminalNotification(task: TaskView): { title: string; message: string } {
  if (task.status === 'done') {
    return { title: `/task · ${task.name}`, message: '任务已完成，代码已合并，worktree 和分支已清理。' }
  }
  const reason = task.pause?.message ?? task.error
  return { title: `/task · ${task.name}`, message: reason ? `任务已暂停：${reason}${task.resumeHint ? `\n${task.resumeHint}` : ''}` : '任务已暂停或终止，请查看进度并使用 /task-resume。' }
}

export type StageKey = 'analyze' | 'plan' | 'implement' | 'integrate' | 'cleanup'
export type StageState = 'done' | 'active' | 'pending' | 'paused'
export type ProgressSegment = { key: StageKey; label: string; state: StageState }

const stageLabels: readonly [StageKey, string][] = [
  ['analyze', '分析'], ['plan', '计划'], ['implement', '实施'], ['integrate', '集成'], ['cleanup', '清理'],
]

export function progressSegments(task: TaskView): ProgressSegment[] {
  const done = task.status === 'done'
  const paused = !task.running && !done
  const stage = Math.min(Math.max(task.step, 0), stageLabels.length - 1)
  return stageLabels.map(([key, label], index) => ({
    key, label,
    state: done || index < stage ? 'done' : index === stage ? paused ? 'paused' : 'active' : 'pending',
  }))
}

export function progressState(task: TaskView, waiting?: string): string {
  if (task.status === 'done') return '已完成'
  if (waiting) return waiting
  if (task.status === 'recovering') return '等待自动恢复'
  if (!task.running) {
    if (task.status !== 'blocked') return '已中断，可恢复'
    switch (task.pause?.kind) {
      case 'external': return '等待外部条件'
      case 'no-progress': return '等待补充进展'
      case 'budget': return '执行预算耗尽'
      case 'quota': return '等待额度恢复'
      case 'user': return '已停止'
      case 'protocol': return '记录待修复'
      default: return '已暂停'
    }
  }
  return task.review ? '收尾审查' : task.status === 'cleaning' ? '清理中' : '执行中'
}

export function progressLines(task: TaskView, waiting?: string): [string, string] {
  const clean = (s: string) => s.replace(/[\x00-\x1f\x7f-\x9f]/g, ' ')
  const line = progressSegments(task).map(segment => `${segment.state === 'done' ? '✓' : segment.state === 'paused' ? '!' : segment.state === 'active' ? '●' : '○'} ${segment.label}`).join(' → ')
  const state = progressState(task, waiting)
  return [line, clean(`${task.name} · ${task.model} · ${state} · 第 ${task.rounds} 轮${task.error ? ` · ${task.error}` : task.status !== 'done' && task.next ? ` · ${task.next}` : ''}`)]
}
