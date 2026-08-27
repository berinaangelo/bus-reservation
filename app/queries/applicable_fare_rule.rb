# Resolves the FareRule in effect for a trip: the given route + bus_class's most recent rule
# whose effective_date is on or before the trip's travel date. See
# kos/decisions/data-model-schema.md -- fares are "versioned by effective date, looked up not
# computed."
class ApplicableFareRule
  def initialize(trip:)
    @trip = trip
  end

  def call
    FareRule
      .where(route_id: @trip.route_id, bus_class: @trip.bus_unit.fare_class)
      .where("effective_date <= ?", travel_date)
      .order(effective_date: :desc, id: :desc) # id tiebreaker: [route_id, bus_class, effective_date] isn't unique
      .first
  end

  private

  # The regulated fare in effect is a function of the calendar day of travel in the Philippines,
  # not the UTC day departure_at happens to fall on -- same reasoning as TripSearch's date
  # handling, see kos/decisions/utc-storage-ph-display.md.
  def travel_date
    @travel_date ||= @trip.departure_at.in_time_zone("Asia/Manila").to_date
  end
end
