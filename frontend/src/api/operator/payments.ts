import { request } from '../client'
import type { Payment } from '../../types/operator'

// PATCH /api/v1/operator/payments/:id — flips the Paid toggle. Shared across a multi-seat
// booking's one Payment record, not per-seat.
export function updatePayment(id: number, collected: boolean) {
  return request<Payment>(`/operator/payments/${id}`, {
    method: 'PATCH',
    body: { collected },
    auth: true,
  })
}
