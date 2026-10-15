import { describe, expect, test } from 'bun:test'
import { fail, ProtocolError, ok, parse as unused } from '../src/protocol.js'

describe('protocol', () => {
  test('wraps successful and failed responses without leaking an exception shape', () => {
    expect(ok({ value: 1 })).toEqual({ protocolVersion: 1, ok: true, data: { value: 1 } })
    expect(fail(new ProtocolError('blocked', 'needs input'))).toEqual({ protocolVersion: 1, ok: false, error: { code: 'blocked', message: 'needs input', retryable: false, details: undefined } })
  })

  test('keeps structured details for recoverable errors', () => {
    expect(fail(new ProtocolError('recoverable', 'retry', { attempt: 1 }, true))).toEqual({ protocolVersion: 1, ok: false, error: { code: 'recoverable', message: 'retry', retryable: true, details: { attempt: 1 } } })
  })
})
