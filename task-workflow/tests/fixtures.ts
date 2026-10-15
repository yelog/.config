import { execFileSync } from 'node:child_process'
import { mkdtemp, rm, writeFile } from 'node:fs/promises'
import path from 'node:path'
import type { TaskState } from '../src/state.js'

export const TEMP_ROOT = '/private/var/folders/d9/5sfcnz292bvbdh3nv19rvhc40000gn/T'

export async function tempDirectory(prefix = 'task-workflow-test-'): Promise<string> {
  return mkdtemp(path.join(TEMP_ROOT, prefix))
}

export function git(cwd: string, ...args: string[]): string {
  return execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim()
}

export function gitResult(cwd: string, ...args: string[]): { stdout: string; exitCode: number } {
  try { return { stdout: execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim(), exitCode: 0 } }
  catch (error: any) { return { stdout: String(error.stdout ?? '').trim(), exitCode: Number(error.status) || 1 } }
}

export async function gitRepository(): Promise<string> {
  const root = await tempDirectory()
  git(root, 'init', '-b', 'main')
  git(root, 'config', 'user.name', 'Task Workflow Test')
  git(root, 'config', 'user.email', 'task-workflow@example.invalid')
  await writeFile(path.join(root, 'README.md'), 'initial\n')
  git(root, 'add', '.')
  git(root, 'commit', '-m', 'initial')
  return root
}

export async function removeDirectory(directory: string): Promise<void> {
  await rm(directory, { recursive: true, force: true })
}

export function stateFixture(root: string, overrides: Partial<TaskState> = {}): TaskState {
  const commonDir = path.join(root, '.git')
  return {
    schemaVersion: 1, revision: 0, taskId: 'task-fixture', sessionId: 'session-fixture', requirement: 'test requirement',
    root, commonDir, targetBranch: 'main', initialBase: 'base', base: 'base', name: 'fixture', taskBranch: 'task/fixture',
    worktree: path.join(root, '.claude', 'worktrees', 'fixture'), planRelative: 'docs/plans/fixture.md', stage: 'analyze', status: 'pending', createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
    authorization: { commit: true, merge: true, cleanup: true }, models: { planner: { provider: 'magpie', model: 'codex/gpt-6.1-sol' }, executor: { provider: 'magpie', model: 'codex/gpt-6-luna' } }, modelPolicy: 'pinned',
    budget: { runRounds: 0, totalRounds: 0, maxRunRounds: 40, maxTotalRounds: 160, corrections: 0 }, reviewPending: false,
    artifacts: { analysis: 'analysis.md', plan: 'plan.md', implementation: 'implementation.md', integration: 'integration.md', validation: 'validation.md', changeScope: 'change-scope.json' }, validations: [],
    ...overrides,
  }
}
