# Checks in a Booking (and, by extension, everyone travelling under it) at boarding. Booking-level,
# not per-seat/passenger -- mirrors Payment's own per-Booking scoping, since a party sharing one
# reference_code boards together. See kos/decisions/ux/mockups/trip-manifest.html.
#
# One-way for this MVP -- no undo endpoint. Checking in an already-checked-in booking is a no-op
# success, same idempotency shape as Bookings::Cancel (a double-tap during a boarding rush must
# not raise).
module Bookings
  class CheckIn
    include Interactor

    def call
      booking = Booking.lock.find(context.booking.id)
      context.booking = booking

      return if booking.checked_in?
      context.fail!(message: "This booking can no longer be checked in") unless booking.confirmed?

      booking.update!(checked_in_at: Time.current)
    end
  end
end
