import { useOperatorAuthStore } from '../stores/operatorAuth'
import { ApiError } from './types'

// Empty in dev: relative /api/v1/... paths hit Vite's dev-server proxy (vite.config.ts), which
// forwards to http://localhost:3000 — no CORS involved. Must be set for any production build,
// since that proxy doesn't exist there; it's the frontend-side counterpart of the backend's
// FRONTEND_ORIGIN env var (config/initializers/cors.rb) — the two must point at each other.
const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? ''

type HttpMethod = 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE'

interface RequestOptions {
  method?: HttpMethod
  body?: unknown
  params?: Record<string, unknown>
  /** Inject the operator's Authorization: Bearer header. */
  auth?: boolean
  signal?: AbortSignal
}

interface ErrorBody {
  error?: string
  errors?: Record<string, string[]>
}

export async function request<T>(path: string, opts: RequestOptions = {}): Promise<T> {
  const url = new URL(`${BASE_URL}/api/v1${path}`, window.location.origin)
  for (const [key, value] of Object.entries(opts.params ?? {})) {
    if (value !== undefined) url.searchParams.set(key, String(value))
  }

  const headers: Record<string, string> = { 'Content-Type': 'application/json' }
  if (opts.auth) {
    const token = useOperatorAuthStore().token
    if (token) headers.Authorization = `Bearer ${token}`
  }

  const res = await fetch(url, {
    method: opts.method ?? 'GET',
    headers,
    body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
    signal: opts.signal,
  })

  if (res.status === 204) return undefined as T

  const data: T | ErrorBody | null = await res.json().catch(() => null)

  if (!res.ok) {
    const errorBody = (data ?? {}) as ErrorBody
    if (opts.auth && res.status === 401) useOperatorAuthStore().clearSession()
    throw new ApiError(res.status, errorBody.error ?? 'Request failed', errorBody.errors)
  }

  return data as T
}
