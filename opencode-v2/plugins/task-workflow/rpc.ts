import { Rpc } from '@opencode/plugin/rpc'

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
  if (!task.running) return task.status === 'blocked' ? '已暂停' : '已中断，可恢复'
  return task.review ? '收尾审查' : task.status === 'cleaning' ? '清理中' : '执行中'
}

export function progressLines(task: TaskView, waiting?: string): [string, string] {
  const clean = (s: string) => s.replace(/[\x00-\x1f\x7f-\x9f]/g, ' ')
  const line = progressSegments(task).map(segment => `${segment.state === 'done' ? '✓' : segment.state === 'paused' ? '!' : segment.state === 'active' ? '●' : '○'} ${segment.label}`).join(' → ')
  const state = progressState(task, waiting)
  return [line, clean(`${task.name} · ${task.model} · ${state} · 第 ${task.rounds} 轮${task.error ? ` · ${task.error}` : task.status !== 'done' && task.next ? ` · ${task.next}` : ''}`)]
}
