// Matches app/presenters/booking_presenter.rb.

export interface Passenger {
  full_name: string
  seat_number: string | null // null for ordinary-class bookings (no seat map)
}

export interface Booking {
  reference_code: string // formatted per ReferenceCode.format, e.g. "4XK-7QM-9"
  status: string
  contact_number: string
  total_amount: number // minor units (centavos)
  seat_count: number
  trip: {
    departure_at: string
    arrival_at: string
    operator: string
    origin_terminal: string
    destination_terminal: string
  }
  passengers: Passenger[]
  payment_status: string | null
}
