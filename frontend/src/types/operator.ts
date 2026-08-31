// Matches app/presenters/operator_*_presenter.rb and app/models/operator_staff.rb.

import type { BusClass, TripStatus } from './trip'

export interface OperatorStaff {
  id: number
  name: string
  email: string
  operator_id: number
}

// The operator-admin Staff screen's list shape — distinct from OperatorStaff (the logged-in
// session's own staff record, which the login response doesn't include active/locked on).
export interface OperatorStaffMember {
  id: number
  operator_id: number
  name: string
  email: string
  active: boolean
  locked: boolean
}

export interface OperatorRoute {
  id: number
  operator_id: number
  origin_terminal_id: number
  destination_terminal_id: number
  origin_terminal: string
  destination_terminal: string
  distance_km: number
  estimated_duration_minutes: number
}

export interface OperatorBusUnit {
  id: number
  operator_id: number
  plate_number: string
  bus_class: BusClass
  total_seats: number
  seat_layout: Record<string, unknown>
  active: boolean
  reservable: boolean
}

export interface OperatorFareRule {
  id: number
  route_id: number
  bus_class: BusClass
  base_fare: number // minor units (centavos)
  effective_date: string // date, no tz conversion
}

export interface Payment {
  id: number
  status: string
  amount: number // minor units (centavos)
  collected_at: string | null
}

export interface ManifestRow {
  passenger_id: number
  full_name: string
  seat_number: string | null
  booking: {
    reference_code: string
    contact_number: string
    status: string
    checked_in: boolean
    checked_in_at: string | null
  }
  payment: Payment | null
}

export interface ManifestSummary {
  checked_in: number
  total_passengers: number
  paid: number
  seats_booked: number
  total_seats: number
  trip_status: TripStatus
}
