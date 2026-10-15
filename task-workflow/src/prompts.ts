import path from 'node:path'
import type { TaskState, WorkStage } from './state.js'

export function stagePrompt(state: TaskState): string {
  const dir = path.join(state.commonDir, 'task-workflow', 'tasks', state.taskId)
  const artifacts = state.artifacts
  const base = `Task ${state.name} is in stage ${state.stage}.\nRequirement:\n${state.requirement}\n\nTask record: ${dir}\nTarget branch: ${state.targetBranch}\nTask worktree: ${state.worktree || '(not created yet)'}\n\nNever edit state.json. Only write the receipt path named below. Do not push.\n`
  if (state.stage === 'analyze') return `${base}\nFirst invoke the task-workflow:task-analyze skill. Read the repository and determine root cause, constraints, alternatives and a decision. Do not modify business code. Write a non-empty analysis report to ${path.join(dir, artifacts.analysis)}. Then write the exact receipt JSON to ${state.attempt?.receiptPath}.`
  if (state.stage === 'plan') return `${base}\nFirst invoke the task-workflow:task-plan skill. Read ${path.join(dir, artifacts.analysis)}. Create a complete implementation plan with files, steps, checks and acceptance criteria. Do not modify business code. Write the plan to ${path.join(dir, artifacts.plan)} and a JSON change scope to ${path.join(dir, artifacts.changeScope)}. Then write the exact receipt JSON to ${state.attempt?.receiptPath}.`
  if (state.stage === 'implement') {
    const review = state.reviewPending
    return `${base}\n${review ? `First invoke the task-workflow:task-review skill. This is the mandatory completion review. Read the actual diff, reports, checkpoint and validation records. Do not trust old summaries. Map every requirement to concrete evidence.` : `First invoke the task-workflow:task-implement skill. Before editing, call EnterWorktree with path ${state.worktree}. Confirm the active working directory is exactly ${state.worktree}. If entering the worktree is refused, write a blocked receipt and do not edit the original checkout. Then implement the plan in the task worktree. Work in end-to-end verifiable units and run targeted checks.`}\nRead ${path.join(dir, artifacts.plan)} and ${path.join(dir, artifacts.analysis)}. Write implementation details and actual checks to ${path.join(dir, artifacts.implementation)} and validation evidence to ${path.join(dir, artifacts.validation)}. ${review ? 'Return reviewed=true, requirements with evidence, remainingRequired=[], and deferredChecks (required=false only) when complete.' : ''} Write the exact receipt JSON to ${state.attempt?.receiptPath}.`
  }
  return `${base}\nBefore any integration, call ExitWorktree and verify that the active working directory is exactly ${state.root}. Do not edit files, commit, merge, or push in this handoff turn. Once outside the task worktree, report that the core may run the verified integration steps.`
}

export function receiptExample(state: TaskState, status: 'completed' | 'progress' | 'blocked'): string {
  const common = { token: state.attempt?.token, attemptId: state.attempt?.attemptId, stage: state.stage, status }
  if (status === 'completed') return JSON.stringify({ ...common, completedItems: ['...'], checks: ['...'] })
  if (status === 'blocked') return JSON.stringify({ ...common, reason: 'external input required', question: '...' })
  return JSON.stringify({ ...common, completedItems: ['...'], next: 'one concrete next action', checks: ['...'] })
}
