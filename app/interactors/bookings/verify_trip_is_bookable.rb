# Re-checks the trip is still open for booking under the real transaction, since the
# CheckoutForm's validation happened before this transaction started and the trip's status could
# have changed in between (e.g. an operator cancelled it).
module Bookings
  class VerifyTripIsBookable
    include Interactor
    include Bookings::ReplayGuard

    def perform
      context.trip.reload
      context.fail!(message: "Trip is no longer open for booking") unless context.trip.scheduled?
    end
  end
end
