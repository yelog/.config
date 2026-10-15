import { execFile } from 'node:child_process'
import { appendFile, readFile } from 'node:fs/promises'
import { promisify } from 'node:util'
import path from 'node:path'
import { ProtocolError } from './protocol.js'

const execFileAsync = promisify(execFile)

export type GitResult = { stdout: string; stderr: string; exitCode: number }

export async function runGit(cwd: string, args: string[], timeout = 30_000): Promise<GitResult> {
  try {
    const result = await execFileAsync('git', args, { cwd, encoding: 'utf8', timeout, maxBuffer: 8 * 1024 * 1024 })
    return { stdout: result.stdout.trimEnd(), stderr: result.stderr.trimEnd(), exitCode: 0 }
  } catch (error: any) {
    if (error?.code === 'ETIMEDOUT') throw new ProtocolError('git_error', `git timed out: git ${args.join(' ')}`, undefined, true)
    if (typeof error?.stdout === 'string' || typeof error?.stderr === 'string') {
      return { stdout: String(error.stdout ?? '').trimEnd(), stderr: String(error.stderr ?? error.message ?? '').trimEnd(), exitCode: Number(error.code) || 1 }
    }
    throw new ProtocolError('git_error', `cannot run git: ${error instanceof Error ? error.message : String(error)}`)
  }
}

export async function git(cwd: string, ...args: string[]): Promise<string> {
  const result = await runGit(cwd, args)
  if (result.exitCode !== 0) throw new ProtocolError('git_error', result.stderr || `git ${args.join(' ')} failed`, result)
  return result.stdout
}

export async function gitRoot(cwd: string): Promise<string> {
  return path.resolve(await git(cwd, 'rev-parse', '--show-toplevel'))
}

export async function gitCommonDir(cwd: string): Promise<string> {
  return path.resolve(await git(cwd, 'rev-parse', '--path-format=absolute', '--git-common-dir'))
}

export async function currentBranch(cwd: string): Promise<string> {
  const branch = await git(cwd, 'branch', '--show-current')
  if (!branch) throw new ProtocolError('blocked', 'task must start from a named Git branch')
  return branch
}

export async function head(cwd: string): Promise<string> {
  return git(cwd, 'rev-parse', 'HEAD')
}

export async function statusPorcelain(cwd: string): Promise<string> {
  return git(cwd, 'status', '--porcelain=v1', '--untracked-files=all')
}

export async function isAncestor(cwd: string, ancestor: string, descendant: string): Promise<boolean> {
  return (await runGit(cwd, ['merge-base', '--is-ancestor', ancestor, descendant])).exitCode === 0
}

export async function branchExists(cwd: string, branch: string): Promise<boolean> {
  return Boolean((await git(cwd, 'branch', '--list', branch)).trim())
}

export async function worktreeInventory(cwd: string): Promise<string> {
  return git(cwd, 'worktree', 'list', '--porcelain')
}

export function parsePorcelainPaths(text: string): string[] {
  const result: string[] = []
  for (const line of text.split('\0')) {
    if (!line) continue
    result.push(line.length >= 3 ? line.slice(3) : line)
  }
  return [...new Set(result)]
}

export async function changedPaths(cwd: string, base: string): Promise<string[]> {
  const result = await git(cwd, 'diff', '--name-only', '--no-renames', '-z', base, '--')
  return result.split('\0').filter(Boolean)
}

export async function committedPaths(cwd: string, base: string): Promise<string[]> {
  const result = await git(cwd, 'diff', '--name-only', '--no-renames', '-z', `${base}..HEAD`, '--')
  return result.split('\0').filter(Boolean)
}

export async function dirtyPaths(cwd: string): Promise<string[]> {
  const raw = await git(cwd, 'status', '--porcelain=v1', '-z', '--untracked-files=all')
  const parts = raw.split('\0')
  const paths: string[] = []
  for (let i = 0; i < parts.length; i++) {
    const entry = parts[i]
    if (!entry) continue
    paths.push(entry.slice(3))
    if (/[RC]/.test(entry.slice(0, 2)) && parts[i + 1]) paths.push(parts[++i])
  }
  return [...new Set(paths)]
}

export async function createWorktree(root: string, branch: string, directory: string, base: string): Promise<void> {
  const result = await runGit(root, ['worktree', 'add', '-b', branch, directory, base], 60_000)
  if (result.exitCode !== 0) throw new ProtocolError('git_error', result.stderr || 'failed to create worktree', result)
}

export async function removeWorktree(root: string, directory: string): Promise<void> {
  const result = await runGit(root, ['worktree', 'remove', directory], 60_000)
  if (result.exitCode !== 0) throw new ProtocolError('blocked', result.stderr || 'failed to remove worktree', result)
}

export async function ensureIgnored(root: string, commonDir: string, relativePath: string): Promise<void> {
  const check = await runGit(root, ['check-ignore', '-q', '--', relativePath])
  if (check.exitCode === 0) return
  const exclude = path.join(commonDir, 'info', 'exclude')
  const current = await readFile(exclude, 'utf8').catch(() => '')
  const line = `${relativePath.replace(/\\/g, '/')}/`
  if (current.split('\n').some(item => item.trim() === line)) return
  await appendFile(exclude, `${current.endsWith('\n') || !current ? '' : '\n'}${line}\n`)
}
