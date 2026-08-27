# Fast path for a resubmitted checkout: if a Booking already exists for this idempotency_key,
# every later step must skip real work and this request returns the original booking. Runs
# unconditionally (no Bookings::ReplayGuard -- it's the step that decides the flag).
#
# This isn't just a perf shortcut: without it, a resubmission arriving after the trip's status
# changed (e.g. staff cancelled it) since the original request committed would incorrectly fail
# Bookings::VerifyTripIsBookable instead of returning the original confirmed booking.
module Bookings
  class FindExistingBooking
    include Interactor

    def call
      existing = Booking.find_by(idempotency_key: context.idempotency_key)
      return if existing.nil?

      context.booking = existing
      context.idempotent_replay = true
    end
  end
end
