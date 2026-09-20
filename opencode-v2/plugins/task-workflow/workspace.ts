import { execFileSync } from 'node:child_process'
import path from 'node:path'

const git = (root: string, ...args: string[]) => execFileSync('git', args, {
  cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'],
})

// Use an explicit manifest rather than guessing filenames out of Markdown prose.
// Directories may end in '/', but glob expressions are deliberately rejected.
export function parseScope(text: string): string[] {
  const value = JSON.parse(text.replace(/^```(?:json)?\s*|\s*```$/g, ''))
  if (!value || !Array.isArray(value.files)) throw new Error('change-scope.json 需要 files 数组')
  const files = value.files.map((file: unknown) => {
    if (typeof file !== 'string' || !file || path.posix.isAbsolute(file) ||
        /[\\\x00*?\[\]{}]/.test(file) || file.split('/').some(part => part === '..' || part === '.git')) {
      throw new Error(`无效计划路径：${JSON.stringify(file)}；请提供仓库内具体文件或目录，不使用通配符`)
    }
    const normalized = path.posix.normalize(file).replace(/\/$/, '')
    if (!normalized || normalized === '.') throw new Error('计划路径不能是整个仓库')
    return normalized
  })
  return [...new Set<string>(files)]
}

export function dirtyPaths(root: string): string[] {
  const parts = git(root, 'status', '--porcelain=v1', '-z', '--untracked-files=all').split('\0')
  const paths: string[] = []
  for (let i = 0; i < parts.length; i++) {
    const entry = parts[i]
    if (!entry) continue
    paths.push(entry.slice(3))
    // -z renames/copies are destination NUL source; protect both names.
    if (/[RC]/.test(entry.slice(0, 2)) && parts[i + 1]) paths.push(parts[++i])
  }
  return [...new Set(paths)]
}

export function changedPaths(root: string, base: string): string[] {
  return git(root, 'diff', '--name-only', '--no-renames', '-z', base, '--').split('\0').filter(Boolean)
}

export function untrackedPaths(root: string): string[] {
  return git(root, 'ls-files', '--others', '--exclude-standard', '-z').split('\0').filter(Boolean)
}

export function overlaps(planned: readonly string[], dirty: readonly string[], ignoreCase = false): string[] {
  const normalize = (file: string) => {
    const p = file.normalize('NFC').replace(/\/$/, '')
    return ignoreCase ? p.toLowerCase() : p
  }
  const scope = planned.map(normalize)
  return dirty.filter(file => {
    const p = normalize(file)
    return scope.some(s => s === p || p.startsWith(`${s}/`) || s.startsWith(`${p}/`))
  })
}

// `ignore` holds task-owned artifacts (for example the plan document the plan stage
// just created) so they are not mistaken for the user's uncommitted work.
export function workspaceCheck(root: string, planned: string[], ignore: readonly string[] = []) {
  let ignoreCase = false
  try { ignoreCase = git(root, 'config', '--get', 'core.ignorecase').trim() === 'true' } catch {}
  const skip = new Set(ignore)
  const dirty = dirtyPaths(root).filter(file => !skip.has(file))
  return { dirty, conflicts: overlaps(planned, dirty, ignoreCase) }
}
