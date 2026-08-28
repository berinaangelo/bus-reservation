import { request } from './client'
import type { Trip } from '../types/trip'

export interface SearchTripsParams {
  origin_terminal_id: string | number
  destination_terminal_id: string | number
  date: string
  [key: string]: unknown
}

// GET /api/v1/trips
export function searchTrips(params: SearchTripsParams) {
  return request<Trip[]>('/trips', { params })
}
