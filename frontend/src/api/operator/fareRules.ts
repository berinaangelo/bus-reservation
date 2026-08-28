import { request } from '../client'
import type { PaginatedResponse } from '../types'
import type { OperatorFareRule } from '../../types/operator'
import type { BusClass } from '../../types/trip'

export interface OperatorFareRuleParams {
  route_id: number
  bus_class: BusClass
  base_fare: number // minor units (centavos)
  effective_date: string
}

// GET /api/v1/operator/fare_rules (scoped to the operator's own routes)
export function listFareRules(page?: number) {
  return request<PaginatedResponse<'fare_rules', OperatorFareRule>>('/operator/fare_rules', {
    params: { page },
    auth: true,
  })
}

// GET /api/v1/operator/fare_rules/:id
export function getFareRule(id: number) {
  return request<OperatorFareRule>(`/operator/fare_rules/${id}`, { auth: true })
}

// POST /api/v1/operator/fare_rules
export function createFareRule(params: OperatorFareRuleParams) {
  return request<OperatorFareRule>('/operator/fare_rules', {
    method: 'POST',
    body: params,
    auth: true,
  })
}

// PATCH /api/v1/operator/fare_rules/:id — route_id is immutable, excluded here
export function updateFareRule(
  id: number,
  params: Partial<Omit<OperatorFareRuleParams, 'route_id'>>,
) {
  return request<OperatorFareRule>(`/operator/fare_rules/${id}`, {
    method: 'PATCH',
    body: params,
    auth: true,
  })
}

// DELETE /api/v1/operator/fare_rules/:id
export function deleteFareRule(id: number) {
  return request<void>(`/operator/fare_rules/${id}`, { method: 'DELETE', auth: true })
}
