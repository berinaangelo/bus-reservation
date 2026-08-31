// Matches app/presenters/trip_seat_presenter.rb. Fetched by Seat Selection for reservable-class
// trips (aircon/deluxe/double_deck) — ordinary trips have no TripSeat rows, so there's nothing to
// fetch (seats_available from the Trip search result is enough).

export type SeatStatus = 'available' | 'held' | 'booked'
export type Deck = 'lower' | 'upper' | null

export interface TripSeat {
  id: number
  seat_number: string
  deck: Deck
  seat_type: 'window' | 'aisle'
  status: SeatStatus
}

export interface SeatLayout {
  rows: number
  columns: number
}

// GET /api/v1/trips/:id/seats. seat_layout is BusUnit#seat_layout passed through as-is: a flat
// {rows, columns} for single-deck buses, {lower, upper} for double-deck, or null for an
// ordinary-class trip (see backend note on TripsController#seats).
export interface SeatMapResponse {
  trip_seats: TripSeat[]
  seat_layout: SeatLayout | { lower: SeatLayout; upper: SeatLayout } | null
}
