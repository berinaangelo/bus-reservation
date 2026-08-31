import { request } from './client'
import type { TripSearchResponse } from '../types/trip'
import type { SeatMapResponse } from '../types/seatMap'

export interface SearchTripsParams {
  origin_terminal_id: string | number
  destination_terminal_id: string | number
  date: string
  cursor?: string
  [key: string]: unknown
}

// GET /api/v1/trips
export function searchTrips(params: SearchTripsParams) {
  return request<TripSearchResponse>('/trips', { params })
}

// GET /api/v1/trips/:id/seats — only meaningful for a reservable-class trip (aircon/deluxe/
// double_deck); Seat Selection doesn't call this for an ordinary-class trip.
export function getTripSeatMap(tripId: number | string) {
  return request<SeatMapResponse>(`/trips/${tripId}/seats`)
}
