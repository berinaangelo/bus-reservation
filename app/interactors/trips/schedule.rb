# Persists a new Trip and, for a reservable bus_unit, bulk-generates its TripSeat rows via
# insert_all -- one per existing Seat -- per
# kos/decisions/rails-orm-performance-n-plus-one-and-indexes.md ("bulk ops for batch work ...
# instead of N individual saves triggering N sets of callbacks/queries"). Seat management isn't
# built yet, so bus_unit.seats is empty in practice today; this is built now so a Trip scheduled
# after Seat rows exist doesn't silently ship with zero bookable seats.
#
# arrival_at is computed by the caller (Api::V1::Operator::TripsController), not here or on the
# Trip model -- a model callback would clash with an existing regression test that deliberately
# builds a trip with an invalid arrival_at.
#
# MUST be invoked as: ActiveRecord::Base.transaction { Trips::Schedule.call!(trip: trip) }
module Trips
  class Schedule
    include Interactor

    def call
      trip = context.trip
      context.fail!(message: trip.errors.full_messages.to_sentence) unless trip.save

      return unless trip.bus_unit.reservable?

      now = Time.current
      rows = trip.bus_unit.seats.pluck(:id).map do |seat_id|
        { trip_id: trip.id, seat_id: seat_id, status: TripSeat.statuses[:available], created_at: now, updated_at: now }
      end
      TripSeat.insert_all(rows) if rows.any?
    end
  end
end
