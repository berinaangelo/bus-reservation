# The full passenger roster for one trip's manifest screen -- one row per Passenger (not per
# Booking), since a reservable-class booking's party lists one row per seat while an ordinary-class
# booking's passengers have no TripSeat at all. Cancelled bookings are excluded here, at the query
# level, never fetched-then-hidden -- a released booking has nothing to check in or collect.
class ManifestRoster
  def initialize(trip:)
    @trip = trip
  end

  def call
    Passenger
      .joins(:booking)
      .merge(Booking.where(trip_id: @trip.id, status: :confirmed))
      .preload(trip_seat: :seat, booking: :payment)
      .order("bookings.created_at DESC, passengers.id ASC")
  end
end
