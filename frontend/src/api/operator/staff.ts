import { request } from '../client'
import type { PaginatedResponse } from '../types'
import type { OperatorStaffMember } from '../../types/operator'

// GET /api/v1/operator/staff
export function listStaff(page?: number) {
  return request<PaginatedResponse<'staff', OperatorStaffMember>>('/operator/staff', {
    params: { page },
    auth: true,
  })
}

// POST /api/v1/operator/staff
export function inviteStaff(name: string, email: string) {
  return request<OperatorStaffMember>('/operator/staff', {
    method: 'POST',
    body: { name, email },
    auth: true,
  })
}

// PATCH /api/v1/operator/staff/:id
export function updateStaffActive(id: number, active: boolean) {
  return request<OperatorStaffMember>(`/operator/staff/${id}`, {
    method: 'PATCH',
    body: { active },
    auth: true,
  })
}
