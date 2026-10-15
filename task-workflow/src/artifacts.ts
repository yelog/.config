import { createHash } from 'node:crypto'
import { copyFile, mkdir, readFile, rename, rm, stat } from 'node:fs/promises'
import path from 'node:path'
import { ProtocolError } from './protocol.js'
import { exists } from './storage.js'
import { resolveInside } from './workspace.js'

export async function sha256(file: string): Promise<string> {
  return createHash('sha256').update(await readFile(file)).digest('hex')
}

export async function copyOwnedArtifact(source: string, destination: string, expectedHash?: string): Promise<string> {
  if (!await exists(source)) throw new ProtocolError('not_found', `artifact not found: ${source}`)
  const sourceHash = await sha256(source)
  if (expectedHash && sourceHash !== expectedHash) throw new ProtocolError('conflict', `artifact changed: ${source}`)
  if (await exists(destination)) {
    if (await sha256(destination) !== sourceHash) throw new ProtocolError('blocked', `artifact destination differs: ${destination}`)
    return sourceHash
  }
  await mkdir(path.dirname(destination), { recursive: true })
  const temporary = `${destination}.tmp-${process.pid}`
  await copyFile(source, temporary)
  await rename(temporary, destination)
  return sourceHash
}

export async function writeArtifact(file: string, content: string): Promise<void> {
  await mkdir(path.dirname(file), { recursive: true })
  const temporary = `${file}.tmp-${process.pid}`
  await import('node:fs/promises').then(fs => fs.writeFile(temporary, content, { mode: 0o600 }))
  await rename(temporary, file)
}

export function artifactPath(taskDirectory: string, name: string): string {
  return path.join(taskDirectory, name)
}

export function planDestination(root: string, planDirectory: string, name: string): string {
  return resolveInside(root, path.join(planDirectory, `${name}.md`))
}

export async function ensurePlanInWorktree(source: string, worktree: string, relative: string): Promise<string> {
  const destination = resolveInside(worktree, relative)
  return copyOwnedArtifact(source, destination)
}

export async function fileFingerprint(root: string, files: readonly string[]): Promise<string> {
  const hash = createHash('sha256')
  for (const file of [...files].sort()) {
    const target = resolveInside(root, file)
    try {
      const info = await stat(target)
      hash.update(file).update(String(info.size)).update(await readFile(target))
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') hash.update(file).update('<missing>')
      else throw error
    }
  }
  return hash.digest('hex')
}

export async function removeArtifact(file: string): Promise<void> {
  await rm(file, { force: true })
}
