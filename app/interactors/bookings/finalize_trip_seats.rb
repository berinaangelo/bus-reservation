# Attaches the now-existing booking to each claimed seat and flips it from held to booked. See
# Bookings::ClaimTripSeats for why this is a separate step.
module Bookings
  class FinalizeTripSeats
    include Interactor
    include Bookings::ReplayGuard

    def perform
      return unless context.trip.bus_unit.reservable?

      context.claimed_trip_seats.each do |trip_seat|
        trip_seat.update!(status: :booked, booking: context.booking, held_until: nil)
      end
    end
  end
end
