import { spawn } from 'node:child_process'
import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { ProtocolError } from './protocol.js'
import { fileFingerprint } from './artifacts.js'
import { resolveInside } from './workspace.js'
import type { TaskState, ValidationRecord } from './state.js'

export type CheckDefinition = { id: string; command: string[]; cwd?: string; required?: boolean; timeoutMs?: number; files?: string[] }

export async function runCheck(state: TaskState, definition: CheckDefinition, outputDirectory: string, workspaceRoot = state.worktree || state.root): Promise<ValidationRecord> {
  if (!/^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$/.test(definition.id) || !definition.command.length || definition.command.some(item => !item.trim())) throw new ProtocolError('invalid_request', 'validation command is invalid')
  const cwd = resolveInside(workspaceRoot, definition.cwd ?? '.')
  if (definition.timeoutMs !== undefined && (!Number.isInteger(definition.timeoutMs) || definition.timeoutMs < 1 || definition.timeoutMs > 600_000)) throw new ProtocolError('invalid_request', 'validation timeout must be between 1 and 600000 ms')
  const startedAt = new Date().toISOString()
  const fingerprint = await fileFingerprint(workspaceRoot, definition.files ?? ['.git/HEAD'])
  const outputPath = path.join(outputDirectory, `validation-${definition.id}-${Date.now()}.log`)
  await mkdir(outputDirectory, { recursive: true })
  const result = await new Promise<{ exitCode: number | null; stdout: string; stderr: string }>((resolve, reject) => {
    const child = spawn(definition.command[0], definition.command.slice(1), { cwd, env: process.env, stdio: ['ignore', 'pipe', 'pipe'] })
    let stdout = '', stderr = ''
    child.stdout.on('data', chunk => { stdout += String(chunk) })
    child.stderr.on('data', chunk => { stderr += String(chunk) })
    const timer = setTimeout(() => { child.kill('SIGTERM'); reject(new ProtocolError('recoverable', `validation timed out: ${definition.id}`, undefined, true)) }, definition.timeoutMs ?? 120_000)
    child.on('error', error => { clearTimeout(timer); reject(new ProtocolError('git_error', `validation failed to start: ${error.message}`)) })
    child.on('close', exitCode => { clearTimeout(timer); resolve({ exitCode, stdout, stderr }) })
  })
  await writeFile(outputPath, `${result.stdout}\n${result.stderr}`)
  const finishedAt = new Date().toISOString()
  return {
    id: definition.id, command: definition.command, cwd, exitCode: result.exitCode, startedAt, finishedAt,
    codeFingerprint: fingerprint, outputPath, required: definition.required !== false,
    environment: { node: process.version, platform: process.platform },
  }
}

export function requiredChecksPassed(records: readonly ValidationRecord[]): boolean {
  return records.filter(record => record.required).every(record => record.exitCode === 0)
}
