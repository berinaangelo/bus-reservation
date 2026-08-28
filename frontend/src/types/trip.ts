// Matches app/presenters/trip_presenter.rb (rider-facing) and
// app/presenters/operator_trip_presenter.rb (operator-facing, backs edit forms — includes raw
// editable ids the rider presenter omits).

export type BusClass = 'ordinary' | 'aircon' | 'deluxe' | 'double_deck'
export type TripStatus = 'scheduled' | 'in_progress' | 'completed' | 'cancelled'

export interface Trip {
  id: number
  departure_at: string // ISO8601, Asia/Manila
  arrival_at: string // ISO8601, Asia/Manila
  status: TripStatus
  bus_class: BusClass
  operator: string
  origin_terminal: string
  destination_terminal: string
  fare: number | null // minor units (centavos); null when no FareRule is configured yet
}

export interface OperatorTrip {
  id: number
  route_id: number
  bus_unit_id: number
  departure_at: string
  arrival_at: string
  status: TripStatus
  bus_class: BusClass
  plate_number: string
  route: string // "Origin -> Destination"
}
