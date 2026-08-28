import { request } from '../client'
import type { PaginatedResponse } from '../types'
import type { OperatorBusUnit } from '../../types/operator'
import type { BusClass } from '../../types/trip'

export interface OperatorBusUnitParams {
  bus_class: BusClass
  plate_number: string
  total_seats: number
  active?: boolean
  seat_layout?: Record<string, unknown>
}

// GET /api/v1/operator/bus_units
export function listBusUnits(page?: number) {
  return request<PaginatedResponse<'bus_units', OperatorBusUnit>>('/operator/bus_units', {
    params: { page },
    auth: true,
  })
}

// GET /api/v1/operator/bus_units/:id
export function getBusUnit(id: number) {
  return request<OperatorBusUnit>(`/operator/bus_units/${id}`, { auth: true })
}

// POST /api/v1/operator/bus_units — picks STI class via BusUnit.class_for_bus_class(bus_class)
export function createBusUnit(params: OperatorBusUnitParams) {
  return request<OperatorBusUnit>('/operator/bus_units', {
    method: 'POST',
    body: params,
    auth: true,
  })
}

// PATCH /api/v1/operator/bus_units/:id — can class-switch via becomes! if bus_class changes
export function updateBusUnit(id: number, params: Partial<OperatorBusUnitParams>) {
  return request<OperatorBusUnit>(`/operator/bus_units/${id}`, {
    method: 'PATCH',
    body: params,
    auth: true,
  })
}

// DELETE /api/v1/operator/bus_units/:id
export function deleteBusUnit(id: number) {
  return request<void>(`/operator/bus_units/${id}`, { method: 'DELETE', auth: true })
}
