# Creates one Passenger per submitted name, paired by array position with the claimed trip seats
# (nil for ordinary-class trips, which have no TripSeat rows). Looped create! rather than a bulk
# insert -- N is small (typically 1-4 people), unlike the "generate every TripSeat row for a
# scheduled trip" bulk-write scenario kos/decisions/rails-orm-performance-n-plus-one-and-indexes.md
# targets, and normal validations/timestamps are wanted here.
module Bookings
  class AttachPassengers
    include Interactor
    include Bookings::ReplayGuard

    def perform
      trip_seats = context.claimed_trip_seats || []

      context.passengers.each_with_index do |passenger_attrs, index|
        Passenger.create!(
          booking: context.booking,
          full_name: passenger_attrs[:full_name],
          trip_seat: trip_seats[index]
        )
      end
    end
  end
end
