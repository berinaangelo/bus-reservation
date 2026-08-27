# Atomically decrements an ordinary-class trip's seat counter, for the same reason
# Bookings::ClaimTripSeats locks rows: a read-then-write here would race. The conditional
# UPDATE...WHERE is itself the atomic check-and-decrement -- no separate lock needed.
module Bookings
  class ClaimOrdinaryCapacity
    include Interactor
    include Bookings::ReplayGuard

    def perform
      return if context.trip.bus_unit.reservable?

      count = context.passengers.size
      updated = Trip
        .where(id: context.trip.id)
        .where("seats_available >= ?", count)
        .update_all([ "seats_available = seats_available - ?", count ])

      context.fail!(message: "Not enough seats available") if updated.zero?
    end
  end
end
