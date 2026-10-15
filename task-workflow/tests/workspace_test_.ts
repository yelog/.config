import { describe, expect, test } from 'bun:test'
import { parseScope, overlaps, resolveInside } from '../src/workspace.js'

describe('workspace protection', () => {
  test('accepts concrete repository paths and rejects traversal or globs', () => {
    expect(parseScope('{"files":["src/a.ts","tests/"]}')).toEqual(['src/a.ts', 'tests'])
    expect(() => parseScope('{"files":["../outside"]}')).toThrow()
    expect(() => parseScope('{"files":["src/*.ts"]}')).toThrow()
  })

  test('detects file and directory overlap in both directions', () => {
    expect(overlaps(['src'], ['src/a.ts', 'README.md'])).toEqual(['src/a.ts'])
    expect(overlaps(['src/a.ts'], ['src'])).toEqual(['src'])
    expect(overlaps(['ReadMe.md'], ['README.md'], true)).toEqual(['README.md'])
  })

  test('does not resolve paths outside the repository', () => {
    expect(resolveInside('/repo', 'src/a.ts')).toBe('/repo/src/a.ts')
    expect(() => resolveInside('/repo', '../secret')).toThrow('escapes repository')
  })
})
