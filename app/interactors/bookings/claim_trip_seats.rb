# Claims (holds) each requested TripSeat for a reservable-class trip, one row at a time under a
# real row lock -- see kos/decisions/rails-db-transactions-locking-idempotency.md, this is the
# "must-not-double-process" case pessimistic locking is mandated for.
#
# Deliberately does NOT set booking_id here (only status/held_until) -- see
# Bookings::FinalizeTripSeats, which attaches the booking once it exists. Keeping these as two
# steps means a future "hold this seat while the rider fills out passenger details" endpoint
# (fired at seat-selection time, before checkout) can reuse this step as-is.
module Bookings
  class ClaimTripSeats
    include Interactor
    include Bookings::ReplayGuard

    def perform
      return unless context.trip.bus_unit.reservable?

      held_until = SystemSetting.seat_hold_ttl_minutes.minutes.from_now

      # Ascending id order avoids lock-order deadlocks against a concurrent booking claiming an
      # overlapping set of seats in a different order.
      context.claimed_trip_seats = context.trip_seat_ids.sort.map { |id| claim_one(id, held_until) }
    end

    private

    def claim_one(id, held_until)
      trip_seat = TripSeat.lock.find_by(id: id, trip_id: context.trip.id)
      context.fail!(message: "Seat no longer available") if trip_seat.nil? || !trip_seat.bookable?

      trip_seat.update!(status: :held, held_until: held_until)
      trip_seat
    end
  end
end
