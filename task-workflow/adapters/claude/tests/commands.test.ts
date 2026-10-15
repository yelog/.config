import { expect, test } from 'claude-code/testing'

test('/task validates that a requirement is present before touching the core', async ($) => {
  const result = await $.command.run({ command: 'task', args: '' })
  expect(result.text).toBe('用法：/task <需求描述>')
})

test('/task-status handles a missing task without requiring a model turn', async ($, on) => {
  on('session.id', () => ({ value: 'test-session' }))
  on('session.root', () => ({ value: '/tmp' }))
  on('env.get', () => ({ value: undefined }))
  on('process.run', () => ({ value: { exitCode: 0, stdout: JSON.stringify({ protocolVersion: 1, ok: true, data: null }), stderr: '' } }))
  const result = await $.command.run({ command: 'task-status', args: '' })
  expect(result.text).toBe('当前会话没有任务。')
})
