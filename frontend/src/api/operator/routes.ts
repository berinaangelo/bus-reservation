import { request } from '../client'
import type { PaginatedResponse } from '../types'
import type { OperatorRoute } from '../../types/operator'

export interface OperatorRouteParams {
  origin_terminal_id: number
  destination_terminal_id: number
  distance_km: number
  estimated_duration_minutes: number
}

// GET /api/v1/operator/routes
export function listRoutes(page?: number) {
  return request<PaginatedResponse<'routes', OperatorRoute>>('/operator/routes', {
    params: { page },
    auth: true,
  })
}

// GET /api/v1/operator/routes/:id
export function getRoute(id: number) {
  return request<OperatorRoute>(`/operator/routes/${id}`, { auth: true })
}

// POST /api/v1/operator/routes
export function createRoute(params: OperatorRouteParams) {
  return request<OperatorRoute>('/operator/routes', { method: 'POST', body: params, auth: true })
}

// PATCH /api/v1/operator/routes/:id
export function updateRoute(id: number, params: Partial<OperatorRouteParams>) {
  return request<OperatorRoute>(`/operator/routes/${id}`, {
    method: 'PATCH',
    body: params,
    auth: true,
  })
}

// DELETE /api/v1/operator/routes/:id
export function deleteRoute(id: number) {
  return request<void>(`/operator/routes/${id}`, { method: 'DELETE', auth: true })
}
