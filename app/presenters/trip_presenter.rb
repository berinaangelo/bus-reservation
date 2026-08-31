# JSON shape for a trip search result. See
# kos/decisions/rails-presenters-decorators-for-json-formatting.md.
class TripPresenter < SimpleDelegator
  # seats_available is computed once per request across the whole result page by
  # TripSeatAvailability (avoids an N+1 that would come from computing it per-trip here) and
  # handed in rather than derived locally.
  def initialize(trip, seats_available:)
    super(trip)
    @seats_available = seats_available
  end

  def as_json(*)
    {
      id: id,
      departure_at: departure_at.in_time_zone("Asia/Manila").iso8601,
      arrival_at: arrival_at.in_time_zone("Asia/Manila").iso8601,
      status: status,
      bus_class: bus_unit.fare_class,
      operator: route.operator.name,
      origin_terminal: route.origin_terminal.name,
      destination_terminal: route.destination_terminal.name,
      fare: fare_amount,
      seats_available: @seats_available
    }
  end

  # SimpleDelegator forwards #to_json to the wrapped object via method_missing even when #as_json
  # is overridden here -- without this, `render json:` would silently render the raw Trip instead
  # of this presenter's shape.
  def to_json(*args)
    as_json.to_json(*args)
  end

  private

  # nil is a real, renderable state here (no FareRule configured yet for this route/class), not
  # an error -- fare configuration is a separate operator-admin concern.
  def fare_amount
    ApplicableFareRule.new(trip: __getobj__).call&.base_fare
  end
end
