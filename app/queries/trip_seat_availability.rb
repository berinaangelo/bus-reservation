# Batched seats-left computation for a list of trips (trip search results), avoiding N+1 --
# mirrors the reservable? branch ManifestSummary#seats_booked already uses for one trip at a
# time, just inverted and computed for many trips in one shot via a single grouped query instead
# of a query per trip.
class TripSeatAvailability
  def initialize(trips)
    @trips = trips.to_a
  end

  def call
    counts = bookable_counts_by_trip_id

    @trips.each_with_object({}) do |trip, result|
      result[trip.id] = trip.bus_unit.reservable? ? counts.fetch(trip.id, 0) : (trip.seats_available || 0)
    end
  end

  private

  def bookable_counts_by_trip_id
    reservable_trip_ids = @trips.select { |trip| trip.bus_unit.reservable? }.map(&:id)
    return {} if reservable_trip_ids.empty?

    TripSeat.bookable.where(trip_id: reservable_trip_ids).group(:trip_id).count
  end
end
