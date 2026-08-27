# Live rollup counts for the trip-manifest header (checked-in/total, paid/total, seats-booked/total).
# No aggregate table -- every count here is bounded to one trip's own bookings/seats, per
# kos/decisions/data-model-schema.md.
class ManifestSummary
  def initialize(trip:)
    @trip = trip
  end

  def call
    {
      checked_in: confirmed_passengers.merge(Booking.checked_in).count,
      total_passengers: confirmed_passengers.count,
      paid: confirmed_passengers.joins(booking: :payment).merge(Payment.collected).count,
      seats_booked: seats_booked,
      total_seats: @trip.bus_unit.total_seats
    }
  end

  private

  def confirmed_passengers
    Passenger.joins(:booking).merge(Booking.where(trip_id: @trip.id, status: :confirmed))
  end

  # Reservable-class trips count booked seats directly; ordinary-class trips have no TripSeat rows
  # at all, so seats "booked" is derived from the capacity counter instead -- same reservable?
  # branch Bookings::Cancel already uses.
  def seats_booked
    @trip.bus_unit.reservable? ? @trip.trip_seats.booked.count : @trip.bus_unit.total_seats - (@trip.seats_available || 0)
  end
end
