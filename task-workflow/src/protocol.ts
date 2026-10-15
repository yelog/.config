export const PROTOCOL_VERSION = 1

export type ErrorCode =
  | 'invalid_request'
  | 'not_found'
  | 'conflict'
  | 'blocked'
  | 'recoverable'
  | 'git_error'
  | 'invalid_state'
  | 'internal'

export type ErrorValue = {
  code: ErrorCode
  message: string
  retryable?: boolean
  details?: unknown
}

export type Response<T> =
  | { protocolVersion: number; ok: true; data: T }
  | { protocolVersion: number; ok: false; error: ErrorValue }

export type CommandRequest = {
  command: string
  args?: Record<string, unknown>
}

export class ProtocolError extends Error {
  readonly code: ErrorCode
  readonly retryable: boolean
  readonly details: unknown

  constructor(code: ErrorCode, message: string, details?: unknown, retryable = false) {
    super(message)
    this.name = 'ProtocolError'
    this.code = code
    this.details = details
    this.retryable = retryable
  }
}

export function ok<T>(data: T): Response<T> {
  return { protocolVersion: PROTOCOL_VERSION, ok: true, data }
}

export function fail(error: unknown): Response<never> {
  if (error instanceof ProtocolError) {
    return {
      protocolVersion: PROTOCOL_VERSION,
      ok: false,
      error: { code: error.code, message: error.message, retryable: error.retryable, details: error.details },
    }
  }
  const message = error instanceof Error ? error.message : String(error)
  return { protocolVersion: PROTOCOL_VERSION, ok: false, error: { code: 'internal', message } }
}

export function object(value: unknown, label: string): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new ProtocolError('invalid_request', `${label} must be an object`)
  }
  return value as Record<string, unknown>
}

export function string(value: unknown, label: string, required = true): string | undefined {
  if (value === undefined && !required) return undefined
  if (typeof value !== 'string' || (required && !value.trim())) {
    throw new ProtocolError('invalid_request', `${label} must be a non-empty string`)
  }
  return value
}

export function boolean(value: unknown, label: string, fallback = false): boolean {
  if (value === undefined) return fallback
  if (typeof value !== 'boolean') throw new ProtocolError('invalid_request', `${label} must be boolean`)
  return value
}

export function arrayOfStrings(value: unknown, label: string): string[] {
  if (!Array.isArray(value) || value.some(item => typeof item !== 'string' || !item)) {
    throw new ProtocolError('invalid_request', `${label} must be an array of non-empty strings`)
  }
  return [...new Set(value)] as string[]
}
