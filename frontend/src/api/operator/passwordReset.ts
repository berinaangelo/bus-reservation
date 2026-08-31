import { request } from '../client'

interface MessageResponse {
  message: string
}

// POST /api/v1/operator/password_resets
export function requestPasswordReset(email: string) {
  return request<MessageResponse>('/operator/password_resets', { method: 'POST', body: { email } })
}

// PATCH /api/v1/operator/password_resets/:token
export function confirmPasswordReset(token: string, password: string, passwordConfirmation: string) {
  return request<MessageResponse>(`/operator/password_resets/${encodeURIComponent(token)}`, {
    method: 'PATCH',
    body: { password, password_confirmation: passwordConfirmation },
  })
}
