#!/usr/bin/env node
import { readFile } from 'node:fs/promises'
import { fail, ok, ProtocolError } from './protocol.js'
import { cleanupTasks, completeTask, initTask, integrateTask, nextTask, pauseTask, resumeTask, statusTask } from './engine.js'

function argsFrom(argv: string[]): { command: string; args: Record<string, unknown> } {
  const [command, ...rest] = argv
  if (!command) throw new ProtocolError('invalid_request', 'command is required')
  const args: Record<string, unknown> = {}
  for (let i = 0; i < rest.length; i++) {
    const token = rest[i]
    if (!token.startsWith('--')) throw new ProtocolError('invalid_request', `unexpected argument: ${token}`)
    const equal = token.indexOf('=')
    const key = (equal >= 0 ? token.slice(2, equal) : token.slice(2))
    if (equal < 0 && key === 'apply') { args[key] = true; continue }
    const value = equal >= 0 ? token.slice(equal + 1) : rest[++i]
    if (value === undefined) throw new ProtocolError('invalid_request', `missing value for --${key}`)
    try { args[key] = JSON.parse(value) } catch { args[key] = value }
  }
  return { command, args }
}

async function payload(args: Record<string, unknown>): Promise<Record<string, unknown>> {
  if (args.payload && typeof args.payload === 'object' && !Array.isArray(args.payload)) return args.payload as Record<string, unknown>
  if (typeof args.payload === 'string') {
    try { return JSON.parse(args.payload) }
    catch (error) { throw new ProtocolError('invalid_request', `payload is invalid JSON: ${String(error)}`) }
  }
  return args
}

async function main(): Promise<void> {
  try {
    const parsed = argsFrom(process.argv.slice(2))
    const args = await payload(parsed.args)
    const result = parsed.command === 'init' ? await initTask(args)
      : parsed.command === 'status' ? await statusTask(args)
      : parsed.command === 'next' ? await nextTask(args)
      : parsed.command === 'complete' ? await completeTask(args)
      : parsed.command === 'resume' ? await resumeTask(args)
      : parsed.command === 'pause' ? await pauseTask(args)
      : parsed.command === 'integrate' ? await integrateTask(args)
      : parsed.command === 'cleanup' ? await cleanupTasks(args)
      : (() => { throw new ProtocolError('invalid_request', `unknown command: ${parsed.command}`) })()
    process.stdout.write(`${JSON.stringify(ok(result))}\n`)
  } catch (error) {
    process.stderr.write(`${error instanceof Error ? error.stack ?? error.message : String(error)}\n`)
    process.stdout.write(`${JSON.stringify(fail(error))}\n`)
    process.exitCode = 1
  }
}

void main()
