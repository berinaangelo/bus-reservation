import type { TripSeat } from '../types/seatMap'

// Assumes seat_number is always "<row digits><column letter>" (e.g. "1A", "10B") — matching the
// mockup and existing factories. Seats has no row/column columns of its own; this is a naming
// convention, not a guaranteed invariant, so callers should tolerate a null return (an
// unparseable seat just won't be placed in the grid).
export function parseSeatPosition(seatNumber: string): { row: number; column: number } | null {
  const match = /^(\d+)([A-Za-z])$/.exec(seatNumber)
  if (!match) return null

  const row = Number(match[1])
  const column = match[2]!.toUpperCase().charCodeAt(0) - 'A'.charCodeAt(0)
  return { row, column }
}

export interface SeatRow {
  row: number
  seats: (TripSeat | null)[]
}

// Buckets seats into rows (keyed by the row number parsed out of seat_number), each padded to
// `columns` wide with null for any seat that's missing or unparseable. Rows are returned in
// ascending row-number order. The caller renders an aisle gap after the first half of the row
// (Math.ceil(columns / 2)).
export function groupSeatsIntoRows(seats: TripSeat[], columns: number): SeatRow[] {
  const rows = new Map<number, (TripSeat | null)[]>()

  for (const seat of seats) {
    const position = parseSeatPosition(seat.seat_number)
    if (!position || position.column >= columns) continue

    if (!rows.has(position.row)) {
      rows.set(position.row, new Array(columns).fill(null))
    }
    rows.get(position.row)![position.column] = seat
  }

  return [...rows.entries()].sort(([a], [b]) => a - b).map(([row, seats]) => ({ row, seats }))
}

// Whether the deck toggle should render at all — only double-deck trips have seats on both an
// upper and lower deck.
export function hasUpperDeck(seats: TripSeat[]): boolean {
  return seats.some((seat) => seat.deck === 'upper')
}
