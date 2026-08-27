# Finds scheduled trips for a rider's search: origin terminal -> destination terminal, on a
# given calendar date. The primary flow's first step — see kos/PLAN.md and
# kos/decisions/rails-query-objects-for-reused-queries.md.
#
# Seat-level availability (does this trip actually have a bookable seat left) is deliberately
# out of scope here — that's its own query object per the decision doc, layered on top of this
# one rather than folded in.
class TripSearch
  MANILA_ZONE = ActiveSupport::TimeZone["Asia/Manila"]

  def initialize(origin_terminal_id:, destination_terminal_id:, date:)
    @origin_terminal_id = origin_terminal_id
    @destination_terminal_id = destination_terminal_id
    @date = coerce_date(date)
  end

  def call
    Trip
      .joins(:route)
      .where(routes: { origin_terminal_id: @origin_terminal_id, destination_terminal_id: @destination_terminal_id })
      .where(status: :scheduled)
      .where(departure_at: manila_day_range)
      .preload(:bus_unit, route: [ :operator, :origin_terminal, :destination_terminal ])
      .order(:departure_at, :id)
  end

  private

  def coerce_date(date)
    return date if date.is_a?(Date)

    Date.parse(date.to_s)
  end

  # The rider picks a calendar date in Asia/Manila terms (see
  # kos/decisions/utc-storage-ph-display.md); departure_at is stored in UTC. The day boundary
  # has to be computed in Manila time and converted, not taken from the app's Time.zone (unset,
  # so it defaults to UTC) — otherwise a trip departing just after midnight Manila time but
  # still the previous UTC day would be missed, and vice versa.
  def manila_day_range
    manila_midnight = MANILA_ZONE.local(@date.year, @date.month, @date.day)
    manila_midnight.utc..manila_midnight.end_of_day.utc
  end
end
