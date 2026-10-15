import { readFile } from 'node:fs/promises'
import path from 'node:path'
import { ProtocolError } from './protocol.js'
import type { ModelRef, TaskState } from './state.js'

export type WorkflowConfig = {
  parent?: string
  planDirectory?: string
  models?: { planner?: ModelRef; executor?: ModelRef }
  modelPolicy?: 'follow' | 'pinned'
  maxRunRounds?: number
  maxTotalRounds?: number
  validations?: Array<{ id: string; command: string[]; cwd?: string; required?: boolean; timeoutMs?: number; files?: string[] }>
}

const defaults: Required<Pick<WorkflowConfig, 'planDirectory' | 'modelPolicy' | 'maxRunRounds' | 'maxTotalRounds'>> = {
  planDirectory: 'docs/plans', modelPolicy: 'pinned', maxRunRounds: 40, maxTotalRounds: 160,
}

export async function loadConfig(root: string): Promise<WorkflowConfig> {
  const file = path.join(root, '.task-workflow.json')
  let raw = '{}'
  try { raw = await readFile(file, 'utf8') } catch (error) { if ((error as NodeJS.ErrnoException).code !== 'ENOENT') throw error }
  let value: any
  try { value = JSON.parse(raw) } catch (error) { throw new ProtocolError('invalid_request', `${file} is not valid JSON`, String(error)) }
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new ProtocolError('invalid_request', `${file} must be an object`)
  const allowed = new Set(['parent', 'planDirectory', 'models', 'modelPolicy', 'maxRunRounds', 'maxTotalRounds', 'validations'])
  for (const key of Object.keys(value)) if (!allowed.has(key)) throw new ProtocolError('invalid_request', `unknown workflow config: ${key}`)
  const config = { ...defaults, ...value } as WorkflowConfig
  if (config.parent !== undefined && (typeof config.parent !== 'string' || !config.parent.trim())) throw new ProtocolError('invalid_request', 'parent must be a non-empty path')
  if (typeof config.planDirectory !== 'string' || !config.planDirectory.trim() || path.isAbsolute(config.planDirectory) || config.planDirectory.split(/[\\/]/).some(part => part === '..' || part === '.git')) {
    throw new ProtocolError('invalid_request', 'planDirectory must be a repository-relative path')
  }
  if (config.modelPolicy !== 'follow' && config.modelPolicy !== 'pinned') throw new ProtocolError('invalid_request', 'modelPolicy must be follow or pinned')
  if (!Number.isInteger(config.maxRunRounds) || config.maxRunRounds! < 1 || !Number.isInteger(config.maxTotalRounds) || config.maxTotalRounds! < config.maxRunRounds!) throw new ProtocolError('invalid_request', 'round budgets must be positive integers and total >= per-run')
  return config
}

export function modelFromConfig(config: WorkflowConfig, role: 'planner' | 'executor', fallback: ModelRef): ModelRef {
  const selected = config.models?.[role] ?? fallback
  if (!selected || typeof selected.model !== 'string' || !selected.model.trim()) throw new ProtocolError('invalid_request', `models.${role}.model is required`)
  return { provider: selected.provider, model: selected.model }
}

export function claudeModel(model: ModelRef): string {
  const value = model.model.trim()
  if (model.provider === 'magpie') {
    if (value === 'codex/gpt-6.1-sol') return 'group/auto-gpt-6-1-sol'
    if (value === 'codex/gpt-6-luna') return 'group/auto-gpt-6-luna'
  }
  if (model.provider === 'xrouter') {
    if (value === 'gpt-6.1-sol') return 'group/auto-gpt-6-1-sol'
    if (value === 'gpt-6-luna') return 'group/auto-gpt-6-luna'
  }
  if (value === 'group/auto-gpt-6-1-sol' || value === 'group/auto-gpt-6-luna' || value === 'sonnet' || value === 'opus' || value === 'haiku' || value === 'inherit' || value.startsWith('claude-')) return value
  throw new ProtocolError('invalid_request', `Claude Code cannot route model "${value}"; use magpie/codex IDs, a Claude alias, or a claude-* ID`)
}

export function worktreePath(root: string, config: WorkflowConfig, name: string): string {
  const parent = config.parent ? path.resolve(root, config.parent) : path.join(root, '.claude', 'worktrees')
  return path.join(parent, name)
}
