import { describe, expect, test } from 'bun:test'
import { claudeModel, loadConfig } from '../src/config.js'
import { removeDirectory, gitRepository } from './fixtures.js'

describe('magpie model configuration', () => {
  test('maps canonical magpie IDs to Claude gateway aliases', () => {
    expect(claudeModel({ provider: 'magpie', model: 'codex/gpt-6.1-sol' })).toBe('group/auto-gpt-6-1-sol')
    expect(claudeModel({ provider: 'magpie', model: 'codex/gpt-6-luna' })).toBe('group/auto-gpt-6-luna')
    expect(claudeModel({ provider: 'xrouter', model: 'gpt-6-luna' })).toBe('group/auto-gpt-6-luna')
  })

  test('keeps the default workflow configuration provider-neutral only when explicitly overridden', async () => {
    const root = await gitRepository()
    try {
      const config = await loadConfig(root)
      expect(config.modelPolicy).toBe('pinned')
      expect(config.models).toBeUndefined()
    } finally { await removeDirectory(root) }
  })
})
