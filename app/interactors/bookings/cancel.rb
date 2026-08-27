# Cancels a confirmed Booking: void + release seat, no refund automation, per the "simple cancel"
# scope in kos/decisions/mvp-scope.md. Backs kos/decisions/ux/mockups/booking-detail-cancel.html.
#
# MUST be invoked as:
#
#   ActiveRecord::Base.transaction do
#     Bookings::Cancel.call!(booking: booking)
#   end
#
# `.call!` and the transaction are both required for atomicity -- see
# kos/decisions/rails-db-transactions-locking-idempotency.md, same reasoning as Bookings::Checkout.
#
# Locks the booking row first (must-not-double-process, same shape as seat claiming) so a
# double-tap on "Yes, Cancel" can't run the release twice. Cancelling an already-cancelled booking
# is a no-op success, not a failure -- kos/decisions/ux/mockups/booking-detail-cancel.html's
# "already cancelled" state expects revisiting this action to be harmless.
module Bookings
  class Cancel
    include Interactor

    def call
      booking = Booking.lock.find(context.booking.id)
      context.booking = booking

      return if booking.cancelled?
      context.fail!(message: "This booking can no longer be cancelled") unless booking.confirmed?

      booking.update!(status: :cancelled)
      release_seats(booking)
    end

    private

    def release_seats(booking)
      if booking.trip.bus_unit.reservable?
        release_trip_seats(booking)
      else
        release_ordinary_capacity(booking)
      end
    end

    # Unlink the cancelled booking's passengers from their trip_seats *before* freeing the seats
    # themselves -- Passenger#trip_seat_id is uniquely indexed, so a released TripSeat re-claimed
    # by a later booking's new passenger would collide with the old (still-cancelled) passenger
    # row otherwise. This does mean a cancelled booking stops reporting seat numbers once
    # released -- no seat-assignment audit trail is kept, matching mvp-scope's "no refund/audit
    # trail automation" cut. The frontend already has the seat labels from before the cancel call.
    def release_trip_seats(booking)
      booking.passengers.update_all(trip_seat_id: nil)
      booking.trip_seats.update_all(status: TripSeat.statuses[:available], booking_id: nil, held_until: nil)
    end

    # Ordinary-class trips have no TripSeat rows -- give the counted capacity back to the trip,
    # same atomic conditional-update shape as Bookings::ClaimOrdinaryCapacity's decrement.
    def release_ordinary_capacity(booking)
      Trip.where(id: booking.trip_id)
        .update_all([ "seats_available = seats_available + ?", booking.seat_count ])
    end
  end
end
