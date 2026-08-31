import { request } from './client'
import type { Terminal } from '../types/terminal'

// GET /api/v1/terminals — backs the Trip Search From/To autocomplete. Bounded to 20 matches
// server-side, so this is meant to be called per-keystroke (debounced), not once up front.
export function searchTerminals(q: string) {
  return request<Terminal[]>('/terminals', { params: q ? { q } : {} })
}
