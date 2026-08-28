import { request } from '../client'
import type { OperatorStaff } from '../../types/operator'

interface LoginResponse {
  token: string
  expires_at: string
  operator_staff: OperatorStaff
}

// POST /api/v1/operator/session
export function login(email: string, password: string) {
  return request<LoginResponse>('/operator/session', { method: 'POST', body: { email, password } })
}

// DELETE /api/v1/operator/session
export function logout() {
  return request<void>('/operator/session', { method: 'DELETE', auth: true })
}
