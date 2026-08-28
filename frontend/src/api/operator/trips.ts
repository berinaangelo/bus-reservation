import { request } from '../client'
import type { PaginatedResponse } from '../types'
import type { OperatorTrip } from '../../types/trip'

export interface OperatorTripParams {
  route_id: number
  bus_unit_id: number
  departure_at: string
  status?: string
}

// GET /api/v1/operator/trips
export function listTrips(page?: number) {
  return request<PaginatedResponse<'trips', OperatorTrip>>('/operator/trips', {
    params: { page },
    auth: true,
  })
}

// GET /api/v1/operator/trips/:id
export function getTrip(id: number) {
  return request<OperatorTrip>(`/operator/trips/${id}`, { auth: true })
}

// POST /api/v1/operator/trips
export function createTrip(params: OperatorTripParams) {
  return request<OperatorTrip>('/operator/trips', { method: 'POST', body: params, auth: true })
}

// PATCH /api/v1/operator/trips/:id
export function updateTrip(id: number, params: Partial<OperatorTripParams>) {
  return request<OperatorTrip>(`/operator/trips/${id}`, {
    method: 'PATCH',
    body: params,
    auth: true,
  })
}

// DELETE /api/v1/operator/trips/:id
export function deleteTrip(id: number) {
  return request<void>(`/operator/trips/${id}`, { method: 'DELETE', auth: true })
}
