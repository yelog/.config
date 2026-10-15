import path from 'node:path'
import { git, dirtyPaths } from './git.js'
import { ProtocolError } from './protocol.js'

export function parseScope(text: string): string[] {
  let value: any
  try { value = JSON.parse(text.replace(/^```(?:json)?\s*|\s*```$/g, '')) } catch (error) {
    throw new ProtocolError('invalid_request', `change-scope.json is not valid JSON: ${String(error)}`)
  }
  if (!value || !Array.isArray(value.files)) throw new ProtocolError('invalid_request', 'change-scope.json requires a files array')
  const files: string[] = value.files.map((file: unknown): string => {
    if (typeof file !== 'string' || !file || path.posix.isAbsolute(file) || /[\\\x00*?[\]{}]/.test(file) || file.split('/').some(part => part === '..' || part === '.git')) {
      throw new ProtocolError('invalid_request', `invalid planned path: ${JSON.stringify(file)}`)
    }
    const normalized = path.posix.normalize(file).replace(/\/$/, '')
    if (!normalized || normalized === '.') throw new ProtocolError('invalid_request', 'planned path cannot be the repository root')
    return normalized
  })
  return [...new Set(files)]
}

export function overlaps(planned: readonly string[], dirty: readonly string[], ignoreCase = false): string[] {
  const normalize = (file: string) => {
    const normalized = file.normalize('NFC').replace(/\/$/, '')
    return ignoreCase ? normalized.toLowerCase() : normalized
  }
  const scope = planned.map(normalize)
  return dirty.filter(file => {
    const value = normalize(file)
    return scope.some(item => item === value || value.startsWith(`${item}/`) || item.startsWith(`${value}/`))
  })
}

export async function workspaceCheck(root: string, planned: string[], ignore: readonly string[] = []) {
  let ignoreCase = false
  try { ignoreCase = (await git(root, 'config', '--get', 'core.ignorecase')).trim() === 'true' } catch {}
  const ignored = new Set(ignore)
  const dirty = (await dirtyPaths(root)).filter(file => !ignored.has(file))
  return { dirty, conflicts: overlaps(planned, dirty, ignoreCase) }
}

export async function assertNoPlannedOverlap(root: string, planned: string[], ignore: readonly string[] = []): Promise<void> {
  const result = await workspaceCheck(root, planned, ignore)
  if (result.conflicts.length) {
    throw new ProtocolError('blocked', `planned files overlap uncommitted changes: ${result.conflicts.join(', ')}`, result)
  }
}

export function resolveInside(root: string, relative: string): string {
  if (path.isAbsolute(relative)) throw new ProtocolError('invalid_request', `path must be relative: ${relative}`)
  const resolvedRoot = path.resolve(root)
  const resolved = path.resolve(resolvedRoot, relative)
  if (resolved !== resolvedRoot && !resolved.startsWith(`${resolvedRoot}${path.sep}`)) {
    throw new ProtocolError('invalid_request', `path escapes repository: ${relative}`)
  }
  return resolved
}
