import { request } from './client'
import type { Booking } from '../types/booking'

export interface CreateBookingParams {
  trip_id: number
  contact_number: string
  idempotency_key: string
  trip_seat_ids: number[]
  passengers: { full_name: string }[]
}

// POST /api/v1/bookings
export function createBooking(params: CreateBookingParams) {
  return request<Booking>('/bookings', { method: 'POST', body: params })
}

// GET /api/v1/bookings/:reference_code
export function findBooking(referenceCode: string, contactNumber: string) {
  return request<Booking>(`/bookings/${referenceCode}`, {
    params: { contact_number: contactNumber },
  })
}

// PATCH /api/v1/bookings/:reference_code/cancel
export function cancelBooking(referenceCode: string, contactNumber: string) {
  return request<Booking>(`/bookings/${referenceCode}/cancel`, {
    method: 'PATCH',
    params: { contact_number: contactNumber },
  })
}
