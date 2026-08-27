# Handles a Trip's bus_unit_id being changed on update (other attribute changes are already
# assigned onto context.trip by the controller before this runs, so one #save covers all of it).
# Blocks the change if any existing TripSeat already carries a real booking -- reassigning a
# rider's seat mid-sale isn't a case this MVP solves (would need a notification/reassignment
# flow); otherwise destroys the now-stale TripSeat rows and regenerates fresh ones for the new
# bus_unit, same insert_all discipline as Trips::Schedule. Since Seat management isn't built yet,
# this destroy+regenerate branch is a no-op in practice today, but it's forward-compatible with
# the eventual seat-management follow-up.
#
# MUST be invoked as: ActiveRecord::Base.transaction { Trips::ChangeBusUnit.call!(trip: trip) }
module Trips
  class ChangeBusUnit
    include Interactor

    def call
      trip = context.trip

      if trip.trip_seats.where.not(booking_id: nil).exists?
        context.fail!(message: "Cannot change bus unit: this trip already has booked seats")
      end

      trip.trip_seats.destroy_all
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
