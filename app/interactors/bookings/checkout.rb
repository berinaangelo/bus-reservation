# Turns a rider's checkout submission into a confirmed Booking. See
# kos/decisions/rails-thin-controllers-organizer-interactor-pattern.md.
#
# MUST be invoked as:
#
#   ActiveRecord::Base.transaction do
#     Bookings::Checkout.call!(
#       trip: checkout_form.trip,
#       trip_seat_ids: checkout_form.trip_seat_ids,
#       passengers: checkout_form.passengers,
#       contact_number: checkout_form.contact_number,
#       idempotency_key: checkout_form.idempotency_key
#     )
#   end
#
# `.call!` (not `.call`) and the surrounding transaction are both required for atomicity -- see
# kos/decisions/rails-db-transactions-locking-idempotency.md. Plain `.call` doesn't raise on
# failure, so wrapping it in a transaction accomplishes nothing.
#
# Public contract: the only context key a caller may rely on is `result.booking` (set on both a
# fresh booking and an idempotent replay), plus the standard `result.success?` / `result.failure?`
# / `result.message`. `fare_rule`, `claimed_trip_seats`, and `idempotent_replay` are step-to-step
# scratch state, not part of the contract.
#
# CreateBooking runs before the seat/capacity claim steps deliberately: the DB's own unique index
# on idempotency_key is what actually serializes a true concurrent double-submit. Claiming
# inventory first would let two simultaneous requests both succeed at claiming before either
# commits, since a "does this key exist yet" pre-check has no way to see an uncommitted sibling.
module Bookings
  class Checkout
    include Interactor::Organizer

    organize Bookings::FindExistingBooking,
             Bookings::VerifyTripIsBookable,
             Bookings::ResolveFare,
             Bookings::CreateBooking,
             Bookings::ClaimTripSeats,
             Bookings::ClaimOrdinaryCapacity,
             Bookings::FinalizeTripSeats,
             Bookings::AttachPassengers,
             Bookings::CreatePayment
  end
end
