# Shared no-op guard for every Bookings::Checkout step except FindExistingBooking. When an
# idempotency-key replay is detected (by FindExistingBooking, or by CreateBooking's own
# race-safety check), every later step must skip its real work entirely and leave `context.booking`
# pointing at the pre-existing record. Centralized here instead of repeating
# `return if context.idempotent_replay` at the top of every step, so the guard is one tested
# mechanism instead of a copy-pasted line that's easy to forget on a new step.
module Bookings
  module ReplayGuard
    def call
      return if context.idempotent_replay

      perform
    end
  end
end
